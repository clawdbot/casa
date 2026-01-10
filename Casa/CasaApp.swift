import Combine
import SwiftUI
import UIKit

@main
struct CasaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = CasaAppModel.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
    }
}

@MainActor
final class CasaAppModel: ObservableObject {
    static let shared = CasaAppModel()

    let settings = CasaSettings.shared
    let logger = CasaLogger()
    let homeKit: HomeKitManager
    let server: HomeKitServer
#if canImport(Sparkle)
    let updater = SparkleUpdater()
#endif
    @Published var statusMessage: String = ""
    @Published var toastMessage: String? = nil
    @Published var cliStatus: CLIStatus = CLIInstaller.status()
    private var cancellables = Set<AnyCancellable>()
    private var serverChange: AnyCancellable?
    private var lastPort: UInt16
    private var lastToken: String
    private var lastHomeKitEnabled: Bool
    private var toastTask: Task<Void, Never>?

    private init() {
        self.homeKit = HomeKitManager(logger: logger)
        self.server = HomeKitServer(homeKit: homeKit, settings: settings, logger: logger)
        self.lastPort = settings.port
        self.lastToken = settings.authToken
        self.lastHomeKitEnabled = settings.homeKitEnabled
        serverChange = server.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        observeSettings()
        refreshCLIStatus()
    }

    private func observeSettings() {
        settings.$port
            .sink { [weak self] newPort in
                self?.handlePortChange(newPort)
            }
            .store(in: &cancellables)

        settings.$authToken
            .sink { [weak self] newToken in
                self?.handleAuthTokenChange(newToken)
            }
            .store(in: &cancellables)

        settings.$autoStart
            .sink { [weak self] enabled in
                self?.handleAutoStartChange(enabled)
            }
            .store(in: &cancellables)

        settings.$homeKitEnabled
            .sink { [weak self] enabled in
                self?.handleHomeKitToggle(enabled)
            }
            .store(in: &cancellables)

        settings.$onboardingComplete
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        server.$isRunning
            .sink { [weak self] isRunning in
                self?.statusMessage = isRunning ? "API started" : "API stopped"
            }
            .store(in: &cancellables)

        server.$lastError
            .sink { [weak self] error in
                guard let error else { return }
                self?.statusMessage = error
            }
            .store(in: &cancellables)
    }

    private func handlePortChange(_ newPort: UInt16) {
        guard newPort != lastPort else { return }
        lastPort = newPort
        logger.log(level: "info", message: "settings_port_changed", metadata: [
            "port": String(newPort)
        ])
        restartIfNeeded()
    }

    private func handleAuthTokenChange(_ newToken: String) {
        guard newToken != lastToken else { return }
        lastToken = newToken
        logger.log(level: "info", message: "settings_token_changed", metadata: [
            "present": newToken.isEmpty ? "false" : "true"
        ])
        restartIfNeeded()
    }

    private func handleAutoStartChange(_ enabled: Bool) {
        logger.log(level: "info", message: "settings_autostart_changed", metadata: [
            "enabled": enabled ? "true" : "false"
        ])
        if enabled, !server.isRunning {
            statusMessage = "Starting API..."
            server.start()
        } else if !enabled, server.isRunning {
            server.stop()
        }
    }

    private func handleHomeKitToggle(_ enabled: Bool) {
        guard enabled != lastHomeKitEnabled else { return }
        lastHomeKitEnabled = enabled
        logger.log(level: "info", message: "settings_homekit_toggle", metadata: [
            "enabled": enabled ? "true" : "false"
        ])
        if enabled {
            homeKit.start()
        } else {
            homeKit.stop()
        }
    }

    private func restartIfNeeded() {
        guard server.isRunning else { return }
        statusMessage = "Restarting API..."
        server.stop()
        server.start()
    }

    func toggleServer() {
        if server.isRunning {
            logger.log(level: "info", message: "server_toggle_stop")
            server.stop()
        } else {
            logger.log(level: "info", message: "server_toggle_start")
            statusMessage = "Starting API..."
            server.start()
        }
    }

    func installCLI() {
        logger.log(level: "info", message: "cli_install_requested")
        let result = CLIInstaller.installSymlink()
        switch result {
        case .success(let message):
            statusMessage = message
            logger.log(level: "info", message: "cli_install_success", metadata: [
                "message": message
            ])
        case .failure(let message):
            statusMessage = message
            logger.log(level: "error", message: "cli_install_failed", metadata: [
                "message": message
            ])
        }
        refreshCLIStatus()
    }

    func copyDiagnostics() {
        var lines: [String] = []
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        lines.append("Casa diagnostics")
        lines.append("Version: \(version) (\(build))")
        lines.append("Settings: \(settings.diagnostics())")
        lines.append("")
        lines.append("Recent log:")
        lines.append(logger.readLog())
        CasaPasteboard.copy(lines.joined(separator: "\n"))
        showToast("Diagnostics copied")
        logger.log(level: "info", message: "diagnostics_copied")
    }

    func copyLogs() {
        CasaPasteboard.copy(logger.readLog())
        showToast("Logs copied")
        logger.log(level: "info", message: "logs_copied")
    }

    func checkForUpdates() {
#if canImport(Sparkle)
        updater.checkForUpdates()
        statusMessage = "Checking for updates..."
        logger.log(level: "info", message: "updates_check_requested")
#else
        statusMessage = "Updates unavailable on this build"
        logger.log(level: "info", message: "updates_unavailable")
#endif
    }

    func initializeModules() {
        if settings.homeKitEnabled {
            homeKit.start()
        } else {
            homeKit.stop()
        }
    }

    func refreshCLIStatus() {
        cliStatus = CLIInstaller.status()
    }

    func showToast(_ message: String) {
        toastTask?.cancel()
        toastMessage = message
        toastTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            toastMessage = nil
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let model = CasaAppModel.shared
        model.initializeModules()
        if model.settings.autoStart {
            model.server.start()
        }

        return true
    }

#if targetEnvironment(macCatalyst)
    func applicationShouldTerminateAfterLastWindowClosed(_ application: UIApplication) -> Bool {
        false
    }
#endif
}
