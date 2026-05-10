import SwiftUI
import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String
    var content: String
    var isStreaming: Bool

    static func user(_ text: String) -> ChatMessage {
        ChatMessage(role: "user", content: text, isStreaming: false)
    }

    static func assistant(_ text: String, streaming: Bool = false) -> ChatMessage {
        ChatMessage(role: "assistant", content: text, isStreaming: streaming)
    }
}

@Observable
final class ChatManager {
    var messages: [ChatMessage] = []
    var isLoading = false
    var error: String?

    private let baseURL = "https://opencode.ai/zen/v1/chat/completions"
    private let model = "big-pickle"

    func send(_ text: String, apiKey: String) {
        guard !apiKey.isEmpty else {
            error = "Введите API ключ"
            return
        }

        let userMsg = ChatMessage.user(text)
        messages.append(userMsg)
        isLoading = true
        error = nil

        var assistantMsg = ChatMessage.assistant("", streaming: true)
        messages.append(assistantMsg)

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let apiMessages = messages
            .filter { !$0.isStreaming || $0.id == assistantMsg.id }
            .map { ["role": $0.role, "content": $0.content] }

        let body: [String: Any] = [
            "model": model,
            "messages": apiMessages,
            "stream": true
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let idx = messages.count - 1

        Task {
            do {
                let (bytes, response) = try await URLSession.shared.bytes(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                guard http.statusCode == 200 else {
                    let text = try await bytes.lines.reduce("", +)
                    throw NSError(domain: "API", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: text])
                }

                for try await line in bytes.lines {
                    guard line.hasPrefix("data: ") else { continue }
                    let data = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                    guard data != "[DONE]" else { continue }
                    guard let json = try JSONSerialization.jsonObject(with: Data(data.utf8)) as? [String: Any],
                          let choice = (json["choices"] as? [[String: Any]])?.first,
                          let delta = choice["delta"] as? [String: Any],
                          let content = delta["content"] as? String else { continue }
                    await MainActor.run {
                        messages[idx].content += content
                    }
                }
                await MainActor.run {
                    messages[idx].isStreaming = false
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    messages[idx].isStreaming = false
                    isLoading = false
                }
            }
        }
    }

    func clear() {
        messages = []
        error = nil
    }
}
