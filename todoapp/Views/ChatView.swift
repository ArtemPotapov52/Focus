import SwiftUI
import SwiftData
import EventKit

struct ChatView: View {
    @State private var chat = ChatManager()
    @State private var input = ""
    @AppStorage("chat_api_key") private var apiKey = Secrets.openCodeKey
    @Query private var notes: [Note]
    @Environment(EventKitManager.self) var ek
    @FocusState private var inputFocused
    @State private var kbHeight: CGFloat = 0

    private let suggestions = ["Plan my day", "Summarize latest notes", "Refine goals", "What's on my schedule?"]

    var body: some View {
        VStack(spacing: 0) {
            if apiKey.isEmpty {
                emptyKeyView
            } else if chat.messages.isEmpty {
                emptyChatView
            } else {
                messagesView
            }

            // Input area
            inputArea
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { n in
            if let r = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                kbHeight = r.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            kbHeight = 0
        }
    }

    // MARK: - Empty Key

    private var emptyKeyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "key.fill")
                .font(.system(size: 34))
                .foregroundColor(.appTextSec.opacity(0.3))
            Text("Enter your API key")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.appTextSec.opacity(0.6))
            SecureField("API key", text: $apiKey)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Empty Chat

    private var emptyChatView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundColor(.appTextSec.opacity(0.2))

            Text("How can I help you?")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.appText)

            Text("Ask about your notes, tasks, or schedule")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.appTextSec.opacity(0.5))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Messages

    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(chat.messages) { msg in
                        messageBubble(msg)
                            .id(msg.id)
                            .transition(.opacity)
                    }
                    if let error = chat.error {
                        Text(error)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.red.opacity(0.8))
                            .padding(.horizontal)
                            .padding(.top, 4)
                    }
                }
                .padding(.vertical, 8)
            }
            .onChange(of: chat.messages.count) { _, _ in
                if let last = chat.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .onChange(of: chat.isLoading) { _, loading in
                if loading, let last = chat.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    // MARK: - Message Bubble

    @ViewBuilder
    private func messageBubble(_ msg: ChatMessage) -> some View {
        let isUser = msg.role == "user"

        HStack(alignment: .bottom, spacing: 10) {
            if isUser {
                Spacer(minLength: 40)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 3) {
                if isUser {
                    userBubble(msg)
                } else {
                    aiBubble(msg)
                }

                Text(msg.timestamp, style: .time)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.appTextSec.opacity(0.35))
                    .padding(.horizontal, 4)
            }

            if !isUser {
                Spacer(minLength: 40)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 2)
    }

    private func userBubble(_ msg: ChatMessage) -> some View {
        Text(msg.content)
            .font(.system(size: 14, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.appText)
            .clipShape(RoundedCorner(radius: 18, corners: [.topLeft, .topRight, .bottomLeft]))
    }

    @ViewBuilder
    private func aiBubble(_ msg: ChatMessage) -> some View {
        if (msg.isStreaming || chat.isLoading) && msg.content.isEmpty {
            thinkingBubble
        } else {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    MarkdownText(msg.content)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.appText)
                    if msg.isStreaming {
                        Text("▎")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(.appText)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.appBubble)
            .clipShape(RoundedCorner(radius: 18, corners: [.topLeft, .topRight, .bottomRight]))
            .overlay(
                RoundedCorner(radius: 18, corners: [.topLeft, .topRight, .bottomRight])
                    .stroke(.appBorder.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private var thinkingBubble: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 14))
                .foregroundColor(.appTextSec.opacity(0.5))
                .shimmer()
            Text(chat.thinkingPhrase)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.appTextSec.opacity(0.6))
                .italic()
                .shimmer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.appBubble)
        .clipShape(RoundedCorner(radius: 18, corners: [.topLeft, .topRight, .bottomRight]))
        .overlay(
            RoundedCorner(radius: 18, corners: [.topLeft, .topRight, .bottomRight])
                .stroke(.appBorder.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Input Area

    private var inputArea: some View {
        VStack(spacing: 8) {
            if chat.messages.isEmpty {
                suggestedPrompts
            }

            HStack(spacing: 0) {
                Button {
                    inputFocused = false
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.appTextSec.opacity(0.5))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)

                TextField("Message FocusAI...", text: $input, axis: .vertical)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.appText)
                    .lineLimit(1...6)
                    .autocorrectionDisabled()
                    .focused($inputFocused)
                    .disabled(chat.isLoading)
                    .onSubmit { send() }
                    .padding(.leading, 20)
                    .padding(.trailing, 12)
                    .padding(.vertical, 10)

                if chat.isLoading {
                    Button { chat.stop() } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color(hex: "c42b2b"))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 6)
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Button { send() } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(input.trimmingCharacters(in: .whitespaces).isEmpty ? .appText.opacity(0.3) : .appText)
                            .clipShape(Circle())
                    }
                    .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.trailing, 6)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .background(.appWhite)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.appBorder.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            .padding(.horizontal, 16)
        }
        .padding(.bottom, kbHeight > 0 ? 8 : 100)
        .padding(.top, 8)
        .background(
            LinearGradient(colors: [Color.appBg.opacity(0), Color.appBg], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }

    // MARK: - Suggested Prompts

    private var suggestedPrompts: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { prompt in
                    Button {
                        input = prompt
                        send()
                    } label: {
                        Text(prompt)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.appText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(.appGrayBg.opacity(0.5))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(.appBorder.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Send

    private func send() {
        let text = input.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !chat.isLoading else { return }
        input = ""
        chat.send(text, apiKey: apiKey)
    }
}

// MARK: - RoundedCorner Shape

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - MarkdownText

struct MarkdownText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        parsedText
    }

    private var parsedText: Text {
        let segments = tokenize(text)
        var result = Text("")
        for segment in segments {
            switch segment.kind {
            case .bold:
                result = result + Text(segment.content).bold()
            case .italic:
                result = result + Text(segment.content).italic()
            case .code:
                result = result + Text(segment.content)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.appAccent)
            case .plain:
                result = result + Text(segment.content)
            }
        }
        return result
    }

    private struct Segment {
        let kind: Kind
        let content: String

        enum Kind { case plain, bold, italic, code }
    }

    private func tokenize(_ input: String) -> [Segment] {
        var segments: [Segment] = []
        var i = input.startIndex

        while i < input.endIndex {
            let remaining = input[i...]

            // **bold**
            if remaining.hasPrefix("**"), let end = remaining.range(of: "**", range: remaining.index(remaining.startIndex, offsetBy: 2)..<remaining.endIndex) {
                let content = String(remaining[remaining.index(remaining.startIndex, offsetBy: 2)..<end.lowerBound])
                if !content.isEmpty {
                    segments.append(Segment(kind: .bold, content: content))
                }
                i = end.upperBound
                continue
            }

            // *italic*
            if remaining.hasPrefix("*"), !remaining.hasPrefix("**"), let end = remaining.range(of: "*", range: remaining.index(remaining.startIndex, offsetBy: 1)..<remaining.endIndex) {
                let content = String(remaining[remaining.index(remaining.startIndex, offsetBy: 1)..<end.lowerBound])
                if !content.isEmpty {
                    segments.append(Segment(kind: .italic, content: content))
                }
                i = end.upperBound
                continue
            }

            // `code`
            if remaining.hasPrefix("`"), let end = remaining.range(of: "`", range: remaining.index(remaining.startIndex, offsetBy: 1)..<remaining.endIndex) {
                let content = String(remaining[remaining.index(remaining.startIndex, offsetBy: 1)..<end.lowerBound])
                if !content.isEmpty {
                    segments.append(Segment(kind: .code, content: content))
                }
                i = end.upperBound
                continue
            }

            // plain — collect until next marker or end
            var plain = ""
            while i < input.endIndex {
                if input[i...].hasPrefix("**") || input[i...].hasPrefix("*") || input[i...].hasPrefix("`") {
                    break
                }
                plain.append(input[i])
                i = input.index(after: i)
            }
            if !plain.isEmpty {
                segments.append(Segment(kind: .plain, content: plain))
            }
        }

        return segments
    }
}

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.5),
                        .clear,
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 60)
                .offset(x: phase)
                .blur(radius: 4)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
