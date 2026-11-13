import SwiftUI

/// One screen that handles both adding a new task and editing an existing one.
/// If `existingTask` is nil, Save creates a task; otherwise it updates one.
struct AddEditTaskView: View {
    let existingTask: Task?
    var onSave: () -> Void

    @State private var title: String
    @State private var description: String
    @State private var isSaving = false
    @State private var showDeleteConfirmation = false
    @State private var errorMessage = ""

    @Environment(\.dismiss) private var dismiss

    init(existingTask: Task?, onSave: @escaping () -> Void) {
        self.existingTask = existingTask
        self.onSave = onSave
        _title = State(initialValue: existingTask?.title ?? "")
        _description = State(initialValue: existingTask?.description ?? "")
    }

    private var isEditing: Bool { existingTask != nil }

    var body: some View {
        Form {
            Section("Title") {
                TextField("e.g. Finish lab report", text: $title)
            }

            Section("Description") {
                TextEditor(text: $description)
                    .frame(height: 120)
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            }

            Section {
                Button {
                    _Concurrency.Task { await save() }
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark")
                            Text(isEditing ? "Save Changes" : "Add Task")
                        }
                        Spacer()
                    }
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
            }
            if isEditing {
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "trash")
                            Text("Delete Task")
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle(isEditing ? "Edit Task" : "New Task")
        .confirmationDialog(
            "Delete Task",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Task", role: .destructive) {
                _Concurrency.Task { await deleteTask() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this task? This cannot be undone.")
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private func save() async {
        errorMessage = ""
        isSaving = true
        defer { isSaving = false }

        do {
            if var task = existingTask {
                task.title = title
                task.description = description
                try await FirebaseManager.shared.updateTask(task)
            } else {
                try await FirebaseManager.shared.addTask(title: title, description: description)
            }
            onSave()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteTask() async {
        guard let task = existingTask else { return }
        errorMessage = ""
        isSaving = true
        defer { isSaving = false }

        do {
            try await FirebaseManager.shared.deleteTask(id: task.id)
            onSave()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        AddEditTaskView(existingTask: nil) {}
    }
}
