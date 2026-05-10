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
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "1a1c1c"))
                Spacer()
                if !chat.messages.isEmpty {
                    Button { chat.clear() } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "444748").opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 16)

            if apiKey.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 34))
                        .foregroundColor(Color(hex: "444748").opacity(0.3))
                    Text("Введи API ключ от OpenCode Zen")
                        .foregroundColor(Color(hex: "444748").opacity(0.6))
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
                        .font(.system(size: 34))
                        .foregroundColor(Color(hex: "444748").opacity(0.3))
                    Text("Спроси что-нибудь")
                        .foregroundColor(Color(hex: "444748").opacity(0.5))
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
                        .foregroundColor(input.trimmingCharacters(in: .whitespaces).isEmpty || chat.isLoading ? Color(hex: "444748").opacity(0.3) : Color(hex: "1a1c1c"))
                }
                .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || chat.isLoading)
            }
            .padding(.horizontal, 20)
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
                    .foregroundColor(Color(hex: "444748").opacity(0.4))
                Text(msg.content + (msg.isStreaming ? "▌" : ""))
                    .font(.body)
                    .foregroundColor(Color(hex: "1a1c1c"))
                    .textSelection(.enabled)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(msg.role == "user" ? Color.blue.opacity(0.1) : Color(hex: "eeeeee"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 20)

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
