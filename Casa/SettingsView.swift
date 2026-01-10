import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: CasaAppModel
    @ObservedObject private var settings = CasaSettings.shared

    var body: some View {
        Form {
            Section("API Server") {
                HStack {
                    Text(model.server.isRunning ? "Running" : "Stopped")
                    Spacer()
                    Button(model.server.isRunning ? "Stop" : "Start") {
                        model.toggleServer()
                    }
                }
                Text(verbatim: "Local API: http://127.0.0.1:\(String(model.server.port))")
                    .font(.footnote)
                if let error = model.server.lastError {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                }
                if !model.statusMessage.isEmpty {
                    Text(model.statusMessage)
                        .font(.footnote)
                }
            }

            Section("Settings") {
                ModuleToggleRow(
                    title: "Enable HomeKit module",
                    isOn: $settings.homeKitEnabled,
                    status: moduleStatusHomeKit(),
                    isSupported: true,
                    unavailableReason: nil
                )

                Toggle("Auto-start API", isOn: $settings.autoStart)

                HStack {
                    Text("Port")
                    Spacer()
                    TextField("14663", text: portBinding)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .keyboardType(.numberPad)
                }

                SecureField("Auth Token (optional)", text: $settings.authToken)

                HStack(spacing: 8) {
                    Text("CLI")
                    StatusBadge(status: model.cliStatus.isInstalled
                        ? ModuleStatus(text: "Installed", tone: .ok)
                        : ModuleStatus(text: "Not Installed", tone: .muted)
                    )
                }

                Button("Check for Updates") {
                    model.checkForUpdates()
                }

                Button("Install CLI Symlink") {
                    model.installCLI()
                }
            }
        }
    }

    private var portBinding: Binding<String> {
        Binding<String>(
            get: { String(settings.port) },
            set: { value in
                if let port = UInt16(value) {
                    settings.port = port
                }
            }
        )
    }

    private func moduleStatusHomeKit() -> ModuleStatus {
        if settings.homeKitEnabled {
            return ModuleStatus(text: "Enabled", tone: .ok)
        }
        return ModuleStatus(text: "Disabled", tone: .muted)
    }
}
