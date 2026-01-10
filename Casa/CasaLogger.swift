import Foundation

struct CasaLogEntry: Encodable {
    let timestamp: String
    let level: String
    let message: String
    let metadata: [String: String]
}

final class CasaLogger: ObservableObject {
    private let queue = DispatchQueue(label: "casa.logger.queue")
    private let logURL: URL
    private let maxFileSize: Int
    private let maxFiles: Int
    @Published private(set) var revision: Int = 0

    init(maxFileSize: Int = 1_000_000, maxFiles: Int = 5) {
        self.maxFileSize = maxFileSize
        self.maxFiles = maxFiles

        let baseURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
        let logsURL = baseURL?.appendingPathComponent("Logs/Casa", isDirectory: true)
        if let logsURL = logsURL {
            try? FileManager.default.createDirectory(at: logsURL, withIntermediateDirectories: true)
            self.logURL = logsURL.appendingPathComponent("casa.log")
        } else {
            self.logURL = URL(fileURLWithPath: "/tmp/casa.log")
        }
    }

    func log(level: String, message: String, metadata: [String: String] = [:]) {
        let entry = CasaLogEntry(
            timestamp: ISO8601DateFormatter().string(from: Date()),
            level: level,
            message: message,
            metadata: metadata
        )
        write(entry)
    }

    func logRequest(method: String, path: String, status: Int, requestId: String, latencyMs: Int) {
        log(level: "info", message: "request", metadata: [
            "method": method,
            "path": path,
            "status": String(status),
            "requestId": requestId,
            "latencyMs": String(latencyMs)
        ])
    }

    func readLog() -> String {
        (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
    }

    private func write(_ entry: CasaLogEntry) {
        queue.async {
            self.rotateIfNeeded()
            guard let data = try? JSONEncoder().encode(entry) else { return }
            var line = data
            line.append(0x0A)
            if let handle = try? FileHandle(forWritingTo: self.logURL) {
                defer { try? handle.close() }
                _ = try? handle.seekToEnd()
                try? handle.write(contentsOf: line)
            } else {
                try? line.write(to: self.logURL, options: .atomic)
            }
            DispatchQueue.main.async {
                self.revision &+= 1
            }
        }
    }

    private func rotateIfNeeded() {
        let size = (try? FileManager.default.attributesOfItem(atPath: logURL.path)[.size] as? NSNumber)?.intValue ?? 0
        guard size >= maxFileSize else { return }

        let fm = FileManager.default
        for index in stride(from: maxFiles - 1, through: 1, by: -1) {
            let src = logURL.deletingLastPathComponent().appendingPathComponent("casa.log.\(index)")
            let dst = logURL.deletingLastPathComponent().appendingPathComponent("casa.log.\(index + 1)")
            if fm.fileExists(atPath: src.path) {
                try? fm.removeItem(at: dst)
                try? fm.moveItem(at: src, to: dst)
            }
        }

        let first = logURL.deletingLastPathComponent().appendingPathComponent("casa.log.1")
        try? fm.removeItem(at: first)
        try? fm.moveItem(at: logURL, to: first)
    }
}
