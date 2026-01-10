import SwiftUI

enum ModuleTone {
    case ok
    case muted
    case warning
    case error
}

struct ModuleStatus {
    let text: String
    let tone: ModuleTone
}

struct StatusBadge: View {
    let status: ModuleStatus

    var body: some View {
        Text(status.text.uppercased())
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundColor(foregroundColor)
            .background(backgroundColor)
            .cornerRadius(10)
    }

    private var backgroundColor: Color {
        switch status.tone {
        case .ok:
            return Color.green.opacity(0.15)
        case .muted:
            return Color.gray.opacity(0.2)
        case .warning:
            return Color.orange.opacity(0.2)
        case .error:
            return Color.red.opacity(0.2)
        }
    }

    private var foregroundColor: Color {
        switch status.tone {
        case .ok:
            return .green
        case .muted:
            return .secondary
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }
}

struct ModuleToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    let status: ModuleStatus
    let isSupported: Bool
    let unavailableReason: String?
    @State private var showInfo = false

    var body: some View {
        HStack(spacing: 12) {
            Toggle(title, isOn: $isOn)
                .disabled(!isSupported)
            StatusBadge(status: status)

            if let unavailableReason, !isSupported {
                Button {
                    showInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
                .alert("Unavailable", isPresented: $showInfo) {
                    Button("OK") {}
                } message: {
                    Text(unavailableReason)
                }
            }
        }
    }
}
