import SwiftUI
import SwiftData

struct NotesView: View {
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]
    @Environment(\.modelContext) private var context
    @State private var showNewNote = false
    @State private var selectedNote: Note?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Заметки")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Spacer()
                Button {
                    showNewNote = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            if notes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "note.text")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.4))
                    Text("Нет заметок")
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(notes) { note in
                            Button {
                                selectedNote = note
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    if !note.title.isEmpty {
                                        Text(note.title)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                    Text(note.content)
                                        .font(.body)
                                        .foregroundColor(.white.opacity(0.8))
                                        .lineLimit(3)
                                    Text(note.updatedAt, style: .date)
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(.ultraThinMaterial.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal)
                            }
                        }
                        .onDelete { indexSet in
                            for i in indexSet {
                                context.delete(notes[i])
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .sheet(isPresented: $showNewNote) {
            NoteEditorView(title: "", content: "") { title, content in
                let note = Note(title: title, content: content)
                context.insert(note)
                showNewNote = false
            }
        }
        .sheet(item: $selectedNote) { note in
            NoteEditorView(title: note.title, content: note.content) { title, content in
                note.title = title
                note.content = content
                note.updatedAt = Date()
                selectedNote = nil
            }
        }
    }
}

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var content: String
    let onSave: (String, String) -> Void

    init(title: String, content: String, onSave: @escaping (String, String) -> Void) {
        self._title = State(initialValue: title)
        self._content = State(initialValue: content)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Заголовок", text: $title)
                ZStack(alignment: .topLeading) {
                    if content.isEmpty {
                        Text("Текст заметки...")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle(title.isEmpty ? "Новая заметка" : "Заметка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { onSave(title, content) }
                        .disabled(title.isEmpty && content.isEmpty)
                }
            }
        }
    }
}
