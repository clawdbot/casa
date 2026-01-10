import Foundation

final class CasaSettings: ObservableObject {
    static let shared = CasaSettings()

    @Published var port: UInt16 {
        didSet { persist() }
    }
    @Published var authToken: String {
        didSet { persist() }
    }
    @Published var autoStart: Bool {
        didSet { persist() }
    }
    @Published var homeKitEnabled: Bool {
        didSet { persist() }
    }
    @Published var onboardingComplete: Bool {
        didSet { persist() }
    }

    private let defaults: UserDefaults
    private var isLoading = true

    private init() {
        self.defaults = UserDefaults.standard
        let storedPort = defaults.integer(forKey: Keys.port)
        self.port = storedPort == 0 ? 14663 : UInt16(storedPort)
        self.authToken = defaults.string(forKey: Keys.authToken) ?? ""
        if defaults.object(forKey: Keys.autoStart) == nil {
            self.autoStart = false
        } else {
            self.autoStart = defaults.bool(forKey: Keys.autoStart)
        }
        if defaults.object(forKey: Keys.homeKitEnabled) == nil {
            self.homeKitEnabled = false
        } else {
            self.homeKitEnabled = defaults.bool(forKey: Keys.homeKitEnabled)
        }
        if defaults.object(forKey: Keys.onboardingComplete) == nil {
            self.onboardingComplete = false
        } else {
            self.onboardingComplete = defaults.bool(forKey: Keys.onboardingComplete)
        }
        isLoading = false
    }

    private init(defaults: UserDefaults) {
        self.defaults = defaults
        let storedPort = defaults.integer(forKey: Keys.port)
        self.port = storedPort == 0 ? 14663 : UInt16(storedPort)
        self.authToken = defaults.string(forKey: Keys.authToken) ?? ""
        if defaults.object(forKey: Keys.autoStart) == nil {
            self.autoStart = false
        } else {
            self.autoStart = defaults.bool(forKey: Keys.autoStart)
        }
        if defaults.object(forKey: Keys.homeKitEnabled) == nil {
            self.homeKitEnabled = false
        } else {
            self.homeKitEnabled = defaults.bool(forKey: Keys.homeKitEnabled)
        }
        if defaults.object(forKey: Keys.onboardingComplete) == nil {
            self.onboardingComplete = false
        } else {
            self.onboardingComplete = defaults.bool(forKey: Keys.onboardingComplete)
        }
        isLoading = false
    }

    #if DEBUG
    static func makeForTests(defaults: UserDefaults) -> CasaSettings {
        CasaSettings(defaults: defaults)
    }
    #endif

    private func persist() {
        guard !isLoading else { return }
        defaults.set(Int(port), forKey: Keys.port)
        defaults.set(authToken, forKey: Keys.authToken)
        defaults.set(autoStart, forKey: Keys.autoStart)
        defaults.set(homeKitEnabled, forKey: Keys.homeKitEnabled)
        defaults.set(onboardingComplete, forKey: Keys.onboardingComplete)
    }

    func diagnostics() -> [String: Any] {
        [
            "port": Int(port),
            "authTokenSet": !authToken.isEmpty,
            "autoStart": autoStart,
            "homeKitEnabled": homeKitEnabled,
            "onboardingComplete": onboardingComplete
        ]
    }

    private enum Keys {
        static let port = "casa.settings.port"
        static let authToken = "casa.settings.authToken"
        static let autoStart = "casa.settings.autoStart"
        static let homeKitEnabled = "casa.settings.homeKitEnabled"
        static let onboardingComplete = "casa.settings.onboardingComplete"
    }
}
