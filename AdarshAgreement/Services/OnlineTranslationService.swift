import Foundation

enum OnlineTranslationError: LocalizedError {
    case disabled
    case notConfigured
    case unavailable

    var errorDescription: String? {
        switch self {
        case .disabled: "Enable Online Translation in Company Settings before generating a Hindi PDF."
        case .notConfigured: "Online translation is not configured for this build."
        case .unavailable: "Hindi translation is temporarily unavailable. Your English agreement has not changed."
        }
    }
}

/// Sends agreement text to the private translation service only after the user
/// has enabled the opt-in setting. The service deliberately receives no logs.
actor OnlineTranslationService {
    private struct RequestBody: Encodable { let target: String; let texts: [String] }
    private struct ResponseBody: Decodable { let texts: [String] }

    static func translateToHindi(_ source: [String]) async throws -> [String: String] {
        guard UserDefaults.standard.bool(forKey: "onlineTranslationEnabled") else {
            throw OnlineTranslationError.disabled
        }
        guard let endpointText = Bundle.main.object(forInfoDictionaryKey: "TranslationAPIURL") as? String,
              let endpoint = URL(string: endpointText),
              let token = Bundle.main.object(forInfoDictionaryKey: "TranslationAPIToken") as? String,
              !token.isEmpty, !token.contains("$(") else {
            throw OnlineTranslationError.notConfigured
        }

        let unique = source.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
        var translated = [String: String]()
        var batch = [String](); var count = 0
        func send(_ texts: [String]) async throws {
            guard !texts.isEmpty else { return }
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.timeoutInterval = 25
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONEncoder().encode(RequestBody(target: "hi", texts: texts))
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                  let body = try? JSONDecoder().decode(ResponseBody.self, from: data), body.texts.count == texts.count else {
                throw OnlineTranslationError.unavailable
            }
            for (english, hindi) in zip(texts, body.texts) { translated[english] = hindi }
        }
        for text in unique {
            let length = text.count
            if batch.count == 50 || count + length > 5_000 {
                try await send(batch); batch = []; count = 0
            }
            batch.append(text); count += length
        }
        try await send(batch)
        return translated
    }
}
