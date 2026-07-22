//
//  NetworkLogger.swift
//  QuickChat
//
//  Created by NamNT97 on 22/7/26.
//

import Foundation
import OSLog

extension URLSession {
    /// Thay cho `data(for:)` — tự log đầy đủ header/body của request và status/header/body của response.
    func dataWithLogging(
        for request: URLRequest,
        logger: Logger = AppLogger.network
    ) async throws -> (Data, URLResponse) {
        logRequest(request, using: logger)
        let start = Date()
        do {
            let (data, response) = try await data(for: request)
            let elapsed = String(format: "%.2f", Date().timeIntervalSince(start))
            logResponse(response, data: data, elapsed: elapsed, using: logger)
            return (data, response)
        } catch {
            logger.error("└─ ✗ request thất bại — \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    private func logRequest(_ request: URLRequest, using logger: Logger) {
        logger.info("┌─ → \(request.httpMethod ?? "GET", privacy: .public) \(request.url?.absoluteString ?? "", privacy: .public)")
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            logger.info("│  header: \(Self.prettyJSON(headers), privacy: .public)")
        }
        if let bodyData = request.httpBody {
            let bodyString = String(data: bodyData, encoding: .utf8) ?? "<binary, \(bodyData.count) bytes>"
            logger.info("│  body: \(bodyString, privacy: .public)")
        }
    }

    private func logResponse(_ response: URLResponse, data: Data, elapsed: String, using logger: Logger) {
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode ?? -1
        let responseBody = String(data: data, encoding: .utf8) ?? "<binary, \(data.count) bytes>"
        logger.info("│  response status: \(statusCode, privacy: .public)")
        if let headers = httpResponse?.allHeaderFields as? [String: String], !headers.isEmpty {
            logger.info("│  response header: \(Self.prettyJSON(headers), privacy: .public)")
        }
        logger.info("│  response body: \(responseBody, privacy: .public)")
        logger.info("└─ ✓ hoàn tất sau \(elapsed, privacy: .public)s")
    }

    private static func prettyJSON(_ dict: [String: String]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: data, encoding: .utf8) else {
            return "\(dict)"
        }
        return string
    }
}
