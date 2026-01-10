import SwiftUI

struct LogsView: View {
    @EnvironmentObject private var model: CasaAppModel
    @ObservedObject private var settings = CasaSettings.shared
    @State private var diagnosticsText = ""
    @State private var logsText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                section(title: "Diagnostics", text: diagnosticsText, onCopy: copyDiagnostics)
                section(title: "Logs", text: logsText, onCopy: copyLogs)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .padding(.top, 10)
        }
        .onAppear(perform: refresh)
        .onReceive(model.logger.$revision) { _ in
            logsText = model.logger.readLog()
        }
        .onReceive(settings.objectWillChange) { _ in
            diagnosticsText = diagnostics()
        }
    }

    private var header: some View {
        HStack {
            Text("Diagnostics & Logs")
                .font(.title2)
        }
    }

    private func section(title: String, text: String, onCopy: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button("Copy") {
                    onCopy()
                }
                .buttonStyle(.borderless)
            }
            Text(text.isEmpty ? "No data yet." : text)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(10)
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func refresh() {
        diagnosticsText = diagnostics()
        logsText = model.logger.readLog()
    }

    private func diagnostics() -> String {
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        var lines: [String] = []
        lines.append("Casa diagnostics")
        lines.append("Version: \(version) (\(build))")
        lines.append("Settings: \(settings.diagnostics())")
        return lines.joined(separator: "\n")
    }

    private func copyDiagnostics() {
        CasaPasteboard.copy(diagnosticsText)
        model.showToast("Diagnostics copied")
        model.logger.log(level: "info", message: "diagnostics_copied")
    }

    private func copyLogs() {
        CasaPasteboard.copy(logsText)
        model.showToast("Logs copied")
        model.logger.log(level: "info", message: "logs_copied")
    }
}
