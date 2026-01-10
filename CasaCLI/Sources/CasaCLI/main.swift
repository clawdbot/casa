import ArgumentParser
import Foundation

@main
struct CasaCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "casa",
        abstract: "Casa CLI for HomeKit automation",
        subcommands: [
            Health.self,
            Homes.self,
            Devices.self,
            Accessory.self,
            Rooms.self,
            Services.self,
            Schema.self,
            Characteristics.self,
            Cameras.self,
            Watch.self
        ]
    )

    struct Options: ParsableArguments {
        @Option(name: .shortAndLong, help: "Base URL for the Casa API.")
        var url: String = ProcessInfo.processInfo.environment["CASA_URL"] ?? "http://127.0.0.1:14663"

        @Option(name: .shortAndLong, help: "Auth token (or set CASA_TOKEN).")
        var token: String = ProcessInfo.processInfo.environment["CASA_TOKEN"] ?? ""

        @Flag(name: .shortAndLong, help: "Print the full response envelope.")
        var raw: Bool = false
    }

    struct Devices: AsyncParsableCommand {
        static let configuration = CommandConfiguration(abstract: "List accessories")
        @OptionGroup var options: Options

        func run() async throws {
            let client = APIClient(baseURL: options.url, token: options.token)
            let data = try await client.get(path: "/homekit/accessories")
            try output(data: data, raw: options.raw)
        }
    }

    struct Accessory: AsyncParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Fetch one accessory")
        @OptionGroup var options: Options

        @Argument(help: "Accessory ID")
        var id: String

        func run() async throws {
            let client = APIClient(baseURL: options.url, token: options.token)
            let data = try await client.get(path: "/homekit/accessories/\(id)")
            try output(data: data, raw: options.raw)
        }
    }

    struct Rooms: AsyncParsableCommand {
        static let configuration = CommandConfiguration(abstract: "List rooms")
        @OptionGroup var options: Options

        func run() async throws {
            let client = APIClient(baseURL: options.url, token: options.token)
            let data = try await client.get(path: "/homekit/rooms")
            try output(data: data, raw: options.raw)
        }
    }

    struct Services: AsyncParsableCommand {
        static let configuration = CommandConfiguration(abstract: "List services")
        @OptionGroup var options: Options

        func run() async throws {
            let client = APIClient(baseURL: options.url, token: options.token)
            let data = try await client.get(path: "/homekit/services")
            try output(data: data, raw: options.raw)
        }
    }

    struct Homes: AsyncParsableCommand {
        static let configuration = CommandConfiguration(abstract: "List homes")
        @OptionGroup var options: Options

        func run() async throws {
            let client = APIClient(baseURL: options.url, token: options.token)
            let data = try await client.get(path: "/homekit/homes")
            try output(data: data, raw: options.raw)
        }
    }

    struct Health: AsyncParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Check server health")
        @OptionGroup var options: Options

        func run() async throws {
            let client = APIClient(baseURL: options.url, token: options.token)
            let data = try await client.get(path: "/health")
            try output(data: data, raw: options.raw)
        }
    }

    struct Schema: AsyncParsableCommand {
        static let configuration = CommandConfiguration(abstract: "List writable characteristics schema")
        @OptionGroup var options: Options

        func run() async throws {
            let client = APIClient(baseURL: options.url, token: options.token)
            let data = try await client.get(path: "/homekit/schema")
            try output(data: data, raw: options.raw)
        }
    }

    struct Characteristics: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Read or write a characteristic",
            subcommands: [Get.self, Set.self, Write.self]
        )

        struct Get: AsyncParsableCommand {
            static let configuration = CommandConfiguration(abstract: "Read a characteristic")
            @OptionGroup var options: Options

            @Argument(help: "Characteristic ID")
            var id: String

            func run() async throws {
                let client = APIClient(baseURL: options.url, token: options.token)
                let data = try await client.get(path: "/homekit/characteristics/\(id)")
                try output(data: data, raw: options.raw)
            }
        }

        struct Set: AsyncParsableCommand {
            static let configuration = CommandConfiguration(abstract: "Write a characteristic (PUT)")
            @OptionGroup var options: Options

            @Argument(help: "Characteristic ID")
            var id: String

            @Argument(help: "Value (JSON literal or plain string)")
            var value: String

            func run() async throws {
                let client = APIClient(baseURL: options.url, token: options.token)
                let payload: [String: Any] = ["value": try parseJSONValue(value)]
                let data = try await client.request(method: "PUT", path: "/homekit/characteristics/\(id)", jsonBody: payload)
                try output(data: data, raw: options.raw)
            }
        }

        struct Write: AsyncParsableCommand {
            static let configuration = CommandConfiguration(abstract: "Write a characteristic (legacy POST)")
            @OptionGroup var options: Options

            @Argument(help: "Characteristic ID")
            var id: String

            @Argument(help: "Value (JSON literal or plain string)")
            var value: String

            func run() async throws {
                let client = APIClient(baseURL: options.url, token: options.token)
                let payload: [String: Any] = ["id": id, "value": try parseJSONValue(value)]
                let data = try await client.request(method: "POST", path: "/homekit/characteristic", jsonBody: payload)
                try output(data: data, raw: options.raw)
            }
        }
    }

    struct Cameras: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Camera endpoints",
            subcommands: [List.self, Get.self]
        )

        struct List: AsyncParsableCommand {
            static let configuration = CommandConfiguration(abstract: "List cameras")
            @OptionGroup var options: Options

            func run() async throws {
                let client = APIClient(baseURL: options.url, token: options.token)
                let data = try await client.get(path: "/homekit/cameras")
                try output(data: data, raw: options.raw)
            }
        }

        struct Get: AsyncParsableCommand {
            static let configuration = CommandConfiguration(abstract: "Fetch one camera")
            @OptionGroup var options: Options

            @Argument(help: "Camera ID")
            var id: String

            func run() async throws {
                let client = APIClient(baseURL: options.url, token: options.token)
                let data = try await client.get(path: "/homekit/cameras/\(id)")
                try output(data: data, raw: options.raw)
            }
        }

    }

    struct Watch: AsyncParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Stream accessory changes")
        @OptionGroup var options: Options

        @Option(name: .shortAndLong, help: "Polling interval in seconds.")
        var interval: Double = 2.0

        func run() async throws {
                let client = APIClient(baseURL: options.url, token: options.token)
                var lastPayload: Data?
                while true {
                    let data = try await client.get(path: "/homekit/accessories")
                    if data != lastPayload {
                        try output(data: data, raw: options.raw)
                        lastPayload = data
                }
                try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }

}

private struct APIClient {
    let baseURL: URL
    let token: String

    init(baseURL: String, token: String) {
        if let url = URL(string: baseURL) {
            self.baseURL = url
        } else {
            self.baseURL = URL(string: "http://127.0.0.1:14663")!
        }
        self.token = token
    }

    func get(path: String) async throws -> Data {
        try await request(method: "GET", path: path)
    }

    func getRaw(path: String) async throws -> Data {
        try await request(method: "GET", path: path, expectJSON: false)
    }

    func request(method: String, path: String, jsonBody: [String: Any]? = nil, expectJSON: Bool = true) async throws -> Data {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw RuntimeError("Invalid URL: \(path)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if !token.isEmpty {
            request.setValue(token, forHTTPHeaderField: "X-Casa-Token")
        }
        if let jsonBody {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody, options: [])
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw RuntimeError("No HTTP response")
        }
        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw RuntimeError(message)
        }
        if expectJSON {
            _ = try JSONSerialization.jsonObject(with: data, options: [])
        }
        return data
    }
}

private func output(data: Data, raw: Bool) throws {
    let object = try JSONSerialization.jsonObject(with: data, options: [])
    if raw {
        let pretty = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        FileHandle.standardOutput.write(pretty)
        FileHandle.standardOutput.write(Data("\n".utf8))
        return
    }

    if let dict = object as? [String: Any], let dataField = dict["data"] {
        let pretty = try JSONSerialization.data(withJSONObject: dataField, options: [.prettyPrinted, .sortedKeys])
        FileHandle.standardOutput.write(pretty)
        FileHandle.standardOutput.write(Data("\n".utf8))
        return
    }

    let pretty = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    FileHandle.standardOutput.write(pretty)
    FileHandle.standardOutput.write(Data("\n".utf8))
}

struct RuntimeError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}

private func parseJSONValue(_ value: String) throws -> Any {
    let data = Data(value.utf8)
    if let parsed = try? JSONSerialization.jsonObject(with: data, options: []) {
        return parsed
    }
    if let number = Double(value) {
        return number
    }
    if value.lowercased() == "true" { return true }
    if value.lowercased() == "false" { return false }
    if value.lowercased() == "null" { return NSNull() }
    return value
}

private func writeFile(path: String, data: Data) throws {
    let url = URL(fileURLWithPath: path)
    try data.write(to: url)
}
