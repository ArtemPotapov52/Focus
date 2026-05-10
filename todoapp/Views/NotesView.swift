import SwiftUI
import SwiftData

struct NotesView: View {
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]
    @Environment(\.modelContext) private var context
    @State private var showNewNote = false
    @State private var selectedNote: Note?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(hex: "f9f9f9").ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        VStack(alignment: .leading, spacing: 2) {
                            Text("All Notes")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "1a1c1c"))
                            Text("\(notes.count) notes")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(Color(hex: "444748").opacity(0.6))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 16)
                        .padding(.bottom, 16)
                        .padding(.horizontal, 20)

                        aiSummaryCard

                        notesList
                    }
                    .padding(.bottom, 100)
                }
            }

            // FAB
            Button {
                selectedNote = nil
                showNewNote = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .offset(y: -1)
                    .background(Color(hex: "1a1c1c"))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 80)
        }
        .sheet(isPresented: $showNewNote) {
            NoteEditorView(title: "", content: "", category: nil) { title, content, category in
                let note = Note(title: title, content: content, category: category)
                context.insert(note)
                showNewNote = false
            }
        }
        .sheet(item: $selectedNote) { note in
            NoteEditorView(title: note.title, content: note.content, category: note.category) { title, content, category in
                note.title = title
                note.content = content
                note.category = category
                note.updatedAt = Date()
                selectedNote = nil
            }
        }
    }

    // MARK: - AI Summary Card

    private var aiSummaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "006685"))
                Text("AI INTELLIGENCE")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(0.05 * 11)
                    .foregroundColor(Color(hex: "006685"))
            }

            Text("Weekly Review")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "1a1c1c"))

            Text("You've captured 4 ideas regarding \"Minimalist UI\" and 2 meeting drafts. Your focus has been predominantly on structural alignment this week.")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(Color(hex: "444748"))
                .lineSpacing(2)

            Button {
            } label: {
                Text("Expand Summary")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "1a1c1c"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "f3f3f4"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "c4c7c7").opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Notes List

    private var notesList: some View {
        VStack(spacing: 8) {
            ForEach(notes) { note in
                Button {
                    selectedNote = note
                } label: {
                    noteCard(note)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }

    private func noteCard(_ note: Note) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.title.isEmpty ? "Untitled" : note.title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "1a1c1c"))
                        .lineLimit(1)

                    Text(note.content)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(Color(hex: "444748"))
                        .lineLimit(2)
                        .lineSpacing(2)
                }

                Spacer()

                Text(timestampString(note.updatedAt))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "444748").opacity(0.5))
            }

            if let cat = note.category {
                HStack(spacing: 4) {
                    Text(cat)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "006685"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(hex: "bfe9ff").opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color(hex: "ffffff"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "c4c7c7").opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private func timestampString(_ date: Date) -> String {
        let cal = Calendar.current
        let now = Date()

        let diff = now.timeIntervalSince(date)
        if diff < 60 { return "now" }
        if diff < 3600 { return "\(Int(diff / 60))m ago" }
        if cal.isDateInToday(date) { return "\(Int(diff / 3600))h ago" }
        if cal.isDateInYesterday(date) { return "Yesterday" }

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US")
        if cal.isDate(date, equalTo: now, toGranularity: .year) {
            df.dateFormat = "MMM d"
        } else {
            df.dateFormat = "MMM d, yyyy"
        }
        return df.string(from: date)
    }
}

// MARK: - Note Editor

struct NoteEditorView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title: String
    @State private var content: String
    @State private var category: String?
    @State private var showCategoryPicker = false
    let onSave: (String, String, String?) -> Void

    private let categories = ["Design", "Productivity", "Meeting", "Idea", "Personal"]

    init(title: String, content: String, category: String?, onSave: @escaping (String, String, String?) -> Void) {
        self._title = State(initialValue: title)
        self._content = State(initialValue: content)
        self._category = State(initialValue: category)
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { dismiss() }
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(Color(hex: "444748").opacity(0.6))

                Spacer()

                Text(title.isEmpty ? "New Note" : "Edit Note")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "1a1c1c"))

                Spacer()

                Button("Save") { onSave(title, content, category) }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "1a1c1c"))
                    .opacity(title.isEmpty && content.isEmpty ? 0.4 : 1)
                    .disabled(title.isEmpty && content.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            ScrollView {
                VStack(spacing: 16) {
                    // Category
                    Button {
                        showCategoryPicker.toggle()
                    } label: {
                        HStack(spacing: 0) {
                            Image(systemName: "tag")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "444748").opacity(0.6))
                                .frame(width: 16)
                                .padding(.leading, 0)
                            if let cat = category {
                                Text(cat)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(Color(hex: "006685"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color(hex: "bfe9ff").opacity(0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            } else {
                                Text("Add category")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundColor(Color(hex: "444748").opacity(0.4))
                            }
                            Spacer()
                            Image(systemName: showCategoryPicker ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "444748").opacity(0.3))
                                .padding(.trailing, 16)
                        }
                        .padding(.leading, 16)
                        .padding(.vertical, 10)
                        .background(Color(hex: "f3f3f4"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    if showCategoryPicker {
                        VStack(spacing: 4) {
                            ForEach(categories, id: \.self) { cat in
                                Button {
                                    category = category == cat ? nil : cat
                                } label: {
                                    HStack {
                                        Text(cat)
                                            .font(.system(size: 14, design: .rounded))
                                            .foregroundColor(Color(hex: "1a1c1c"))
                                        Spacer()
                                        if category == cat {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(Color(hex: "006685"))
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(category == cat ? Color(hex: "bfe9ff").opacity(0.15) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding(8)
                        .background(Color(hex: "f3f3f4"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Title
                    TextField("Title", text: $title)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "1a1c1c"))
                        .padding(.leading, 32)
                        .padding(.trailing, 16)
                        .padding(.vertical, 12)
                        .background(Color(hex: "f3f3f4"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    // Content
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("Start writing...")
                                .font(.system(size: 15, design: .rounded))
                                .foregroundColor(Color(hex: "444748").opacity(0.3))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                        }
                        TextEditor(text: $content)
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(Color(hex: "1a1c1c"))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 250)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                    }
                    .background(Color(hex: "f3f3f4"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
