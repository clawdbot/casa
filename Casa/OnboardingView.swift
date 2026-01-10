import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var model: CasaAppModel
    @ObservedObject private var settings = CasaSettings.shared
    @State private var stepIndex = 0
    @State private var cliInstallAttempted = false

    var body: some View {
        HStack {
            Spacer(minLength: 0)
            VStack(spacing: 16) {
                Text("Welcome to Casa")
                    .font(.title)
                Text("Enable the Apple modules you want to expose and grant permissions when prompted.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Group {
                    if stepIndex == 0 {
                        modulesStep
                    } else {
                        cliStep
                    }
                }

                HStack(spacing: 8) {
                    Circle()
                        .fill(stepIndex == 0 ? Color.primary : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(stepIndex == 1 ? Color.primary : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }

                HStack {
                    Button("Back") {
                        stepIndex = max(0, stepIndex - 1)
                    }
                    .disabled(stepIndex == 0)

                    Spacer()

                    Button(stepIndex == 1 ? "Finish" : "Next") {
                        if stepIndex == 1 {
                            settings.onboardingComplete = true
                        } else {
                            stepIndex = min(1, stepIndex + 1)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .frame(maxWidth: 420)
            .padding(.horizontal, 48)
            .padding(.vertical, 24)
            Spacer(minLength: 0)
        }
    }

    private var modulesStep: some View {
        VStack(spacing: 16) {
            Text("Modules & Permissions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
            Toggle("Enable HomeKit module", isOn: $settings.homeKitEnabled)
            Toggle("Auto-start API server", isOn: $settings.autoStart)
            Text("All modules are off by default. You can change these later in Settings.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)

            Button("Request HomeKit Access") {
                model.homeKit.start()
                model.showToast("HomeKit permission prompt requested")
            }
            .disabled(!settings.homeKitEnabled)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 24)
    }

    private var cliStep: some View {
        VStack(spacing: 16) {
            Text("Install CLI")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
            Text("Install the bundled CLI so you can call the API from the terminal.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)

            Button("Install CLI") {
                model.installCLI()
                cliInstallAttempted = true
            }
            .disabled(!model.cliStatus.canInstall || model.cliStatus.isInstalled)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            if !model.cliStatus.canInstall, let reason = model.cliStatus.reason {
                Text(reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if model.cliStatus.isInstalled {
                Text("CLI already installed at /usr/local/bin/casa.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if cliInstallAttempted && !model.cliStatus.isInstalled {
                Text("CLI install failed. Check permissions for /usr/local/bin.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.horizontal, 24)
    }
}
