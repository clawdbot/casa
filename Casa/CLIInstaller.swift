import Foundation

enum CLIInstallerResult {
    case success(String)
    case failure(String)

    var message: String {
        switch self {
        case .success(let message), .failure(let message):
            return message
        }
    }
}

enum CLIInstaller {
    static func status() -> CLIStatus {
        #if targetEnvironment(macCatalyst)
        let targetPath = "/usr/local/bin/casa"
        let fm = FileManager.default
        let exists = fm.fileExists(atPath: targetPath)
        let hasCLI = Bundle.main.url(forResource: "casa", withExtension: nil) != nil
        if exists {
            return CLIStatus(isInstalled: true, canInstall: hasCLI, reason: nil)
        }
        if !hasCLI {
            return CLIStatus(isInstalled: false, canInstall: false, reason: "Embedded CLI not found in the app bundle.")
        }
        return CLIStatus(isInstalled: false, canInstall: true, reason: nil)
        #else
        return CLIStatus(isInstalled: false, canInstall: false, reason: "CLI installer is only available on Mac Catalyst.")
        #endif
    }

    static func installSymlink() -> CLIInstallerResult {
        #if targetEnvironment(macCatalyst)
        guard let scriptURL = Bundle.main.url(forResource: "casa", withExtension: nil) else {
            return .failure("Embedded CLI not found")
        }

        let targetPath = "/usr/local/bin/casa"
        let targetURL = URL(fileURLWithPath: targetPath)
        let fm = FileManager.default

        do {
            if fm.fileExists(atPath: targetPath) {
                try fm.removeItem(at: targetURL)
            }
            try fm.createSymbolicLink(at: targetURL, withDestinationURL: scriptURL)
            return .success("Symlink installed at /usr/local/bin/casa")
        } catch {
            return .failure("Failed to install symlink: \(error.localizedDescription)")
        }
        #else
        return .failure("CLI installer is only available on Mac Catalyst")
        #endif
    }
}

struct CLIStatus {
    let isInstalled: Bool
    let canInstall: Bool
    let reason: String?
}
