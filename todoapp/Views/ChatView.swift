import SwiftUI

struct ChatView: View {
    @State private var chat = ChatManager()
    @State private var input = ""
    @AppStorage("chat_api_key") private var apiKey = Secrets.openCodeKey
    @FocusState private var inputFocused

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("AI Чат")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Spacer()
                if !chat.messages.isEmpty {
                    Button { chat.clear() } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            if apiKey.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white.opacity(0.4))
                    Text("Введи API ключ от OpenCode Zen")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.subheadline)
                    SecureField("API ключ", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 40)
                    Link("Получить ключ на opencode.ai", destination: URL(string: "https://opencode.ai/auth")!)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .frame(maxHeight: .infinity)
            } else if chat.messages.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 36))
                        .foregroundColor(.white.opacity(0.4))
                    Text("Спроси что-нибудь")
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(chat.messages) { msg in
                                messageBubble(msg)
                                    .id(msg.id)
                            }
                            if let error = chat.error {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red.opacity(0.8))
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onChange(of: chat.messages.count) { _ in
                        if let last = chat.messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                    .onChange(of: chat.messages.last?.content.count) { _ in
                        if let last = chat.messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("Сообщение...", text: $input)
                    .textFieldStyle(.roundedBorder)
                    .focused($inputFocused)
                    .disabled(chat.isLoading)
                    .onSubmit { send() }

                Button { send() } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(input.trimmingCharacters(in: .whitespaces).isEmpty || chat.isLoading ? .white.opacity(0.3) : .white)
                }
                .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || chat.isLoading)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private func messageBubble(_ msg: ChatMessage) -> some View {
        HStack(alignment: .bottom) {
            if msg.role == "user" {
                Spacer(minLength: 40)
            }
            VStack(alignment: msg.role == "user" ? .trailing : .leading, spacing: 2) {
                Text(msg.role == "user" ? "Ты" : "Big Pickle")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
                Text(msg.content + (msg.isStreaming ? "▌" : ""))
                    .font(.body)
                    .foregroundColor(.white)
                    .textSelection(.enabled)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(msg.role == "user" ? Color.blue.opacity(0.3) : Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)

            if msg.role == "assistant" {
                Spacer(minLength: 40)
            }
        }
    }

    private func send() {
        let text = input.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !chat.isLoading else { return }
        input = ""
        chat.send(text, apiKey: apiKey)
    }
}
