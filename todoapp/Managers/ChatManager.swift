import Foundation
import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String
    var content: String
    var isStreaming: Bool
    var timestamp: Date

    static func user(_ text: String) -> ChatMessage {
        ChatMessage(role: "user", content: text, isStreaming: false, timestamp: Date())
    }

    static func assistant(_ text: String, streaming: Bool = false) -> ChatMessage {
        ChatMessage(role: "assistant", content: text, isStreaming: streaming, timestamp: Date())
    }
}

@Observable
final class ChatManager {
    var messages: [ChatMessage] = []
    var isLoading = false
    var error: String?
    var thinkingPhrase = "Thinking..."
    var useContext = true

    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"
    private let model = "openrouter/free"
    private var systemPrompt = ""
    private var currentTask: Task<Void, Never>?

    private let phrases = [
        "Synthesizing your notes...",
        "Analyzing your schedule...",
        "Reviewing your tasks...",
        "Connecting the dots...",
        "Processing your request...",
        "Searching knowledge base...",
        "Compiling insights...",
        "Cross-referencing data...",
        "Formulating response...",
        "Scanning your workspace...",
        "Generating analysis...",
        "Structuring output...",
    ]

    func setContext(notes: String, tasks: String, events: String, completedToday: String = "", completedWeek: String = "") {
        let df = DateFormatter()
        df.dateFormat = "EEEE, MMMM d, yyyy 'at' HH:mm"
        let now = df.string(from: Date())

        systemPrompt = """
You are FocusAI, an AI assistant integrated into a productivity app. Current date and time: \(now).

Your role: provide concise, business-like answers. Be brief — no preamble, no summaries of what you can do. Answer directly.

When asked for a review or summary — analyze what's actually in the context (notes content, completed tasks, upcoming events) and give a structured answer with real data.

When asked about completed tasks:
- "Today" count means entries in "Recently completed today" section only (all have today's date).
- "This week" means entries in "Recently completed this week" section.
- If a section says "None", answer 0 / none for that period.

Response format:
- Always start with a **bold header** that summarizes the topic.
- Then the content in plain text.
- Keep it short and actionable.

Rules:
- Never mention that you have access to notes, tasks, calendar, or any user data. Just answer based on what you know.
- When asked who made you: "Developed by FocusAI."

Context (internal — do not reference explicitly):
Notes:
\(notes.isEmpty ? "None" : notes)

Today's tasks:
\(tasks.isEmpty ? "None" : tasks)

Today's events:
\(events.isEmpty ? "None" : events)

Recently completed today:
\(completedToday.isEmpty ? "None" : completedToday)

Recently completed this week:
\(completedWeek.isEmpty ? "None" : completedWeek)
"""
    }

    func send(_ text: String, apiKey: String) {
        guard !apiKey.isEmpty else {
            error = "Enter API key"
            return
        }

        startThinkingTimer()

        let userMsg = ChatMessage.user(text)
        messages.append(userMsg)
        isLoading = true
        error = nil

        var assistantMsg = ChatMessage.assistant("", streaming: false)
        messages.append(assistantMsg)

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://focusai.app", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("FocusAI", forHTTPHeaderField: "X-Title")
        request.timeoutInterval = 30

        var apiMessages: [[String: String]] = []
        let prompt: String
        if useContext, !systemPrompt.isEmpty {
            prompt = systemPrompt
        } else {
            prompt = "You are FocusAI, an AI assistant developed by FocusAI. When asked who you are or who made you, always answer: \"Developed by FocusAI.\""
        }
        apiMessages.append(["role": "system", "content": prompt])
        for m in messages {
            if m.role == "system" { continue }
            if m.isStreaming, m.id != assistantMsg.id { continue }
            apiMessages.append(["role": m.role, "content": m.content])
        }

        let body: [String: Any] = [
            "model": model,
            "messages": apiMessages,
            "stream": false
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let idx = messages.count - 1

        currentTask?.cancel()
        currentTask = Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                try Task.checkCancellation()
                guard let http = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                guard http.statusCode == 200 else {
                    let text = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw NSError(domain: "API", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: text])
                }
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let choices = json["choices"] as? [[String: Any]],
                      let first = choices.first,
                      let message = first["message"] as? [String: Any],
                      let content = message["content"] as? String else {
                    throw URLError(.cannotParseResponse)
                }
                await MainActor.run {
                    messages[idx].content = content
                    messages[idx].isStreaming = false
                    isLoading = false
                    stopThinkingTimer()
                }
            } catch is CancellationError {
                await MainActor.run {
                    messages[idx].isStreaming = false
                    isLoading = false
                    stopThinkingTimer()
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    messages[idx].isStreaming = false
                    isLoading = false
                    stopThinkingTimer()
                }
            }
        }
    }

    func clear() {
        messages = []
        error = nil
        stopThinkingTimer()
        currentTask?.cancel()
        currentTask = nil
    }

    func stop() {
        currentTask?.cancel()
        currentTask = nil
        isLoading = false
        if let last = messages.last, last.isStreaming {
            messages[messages.count - 1].isStreaming = false
        }
        stopThinkingTimer()
    }

    // MARK: - Thinking Timer

    private var timer: Timer?

    private func startThinkingTimer() {
        stopThinkingTimer()
        thinkingPhrase = phrases.randomElement() ?? "Thinking..."
        timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.thinkingPhrase = self.phrases.randomElement() ?? "Thinking..."
        }
    }

    private func stopThinkingTimer() {
        timer?.invalidate()
        timer = nil
    }
}
