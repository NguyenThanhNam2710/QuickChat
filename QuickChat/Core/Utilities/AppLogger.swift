//
//  AppLogger.swift
//  QuickChat
//
//  Created by NamNT97 on 22/7/26.
//

import Foundation
import OSLog

enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.N.QuickChat"
    
    static let auth = Logger(subsystem: subsystem, category: "Auth")
    static let network = Logger(subsystem: subsystem, category: "Network")
    static let ui = Logger(subsystem: subsystem, category: "UI")
}

extension Logger {
    func logCall<T>(
        _ name: String,
        header: [String: Any] = [:],
        body: [String: Any] = [:],
        response: @escaping (T) -> [String: Any] = { _ in [:] },
        action: () async throws -> T
    ) async throws -> T {
        let start = Date()
        self.info("┌─ → \(name, privacy: .public)")
        if !header.isEmpty {
            self.info("│  header: \(Self.prettyJSON(header), privacy: .public)")
        }
        if !body.isEmpty {
            self.info("│  body: \(Self.prettyJSON(body), privacy: .public)")
        }
        do {
            let result = try await action()
            let elapsed = String(format: "%.2f", Date().timeIntervalSince(start))
            let responseDict = response(result)
            if !responseDict.isEmpty {
                self.info("│  response: \(Self.prettyJSON(responseDict), privacy: .public)")
            }
            self.info("└─ ✓ \(name, privacy: .public) thành công (\(elapsed, privacy: .public)s)")
            return result
        } catch {
            let elapsed = String(format: "%.2f", Date().timeIntervalSince(start))
            self.error("└─ ✗ \(name, privacy: .public) thất bại (\(elapsed, privacy: .public)s) — \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    fileprivate static func prettyJSON(_ dict: [String: Any]) -> String {
        guard JSONSerialization.isValidJSONObject(dict),
              let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: data, encoding: .utf8)
        else {
            return "\(dict)"
        }
        return string
    }
}
