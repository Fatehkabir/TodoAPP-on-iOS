import SwiftUI


struct TaskListView: View {
    @Binding var isLoggedIn: Bool

    @State private var tasks: [Task] = []
    @State private var isShowingAddTask = false
    @State private var taskToEdit: Task? = nil
    @State private var taskToDelete: Task? = nil
    @State private var showDeleteConfirmation = false
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if tasks.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach($tasks) { $task in
                            HStack {
                                TaskRow(task: $task) {
                                    _Concurrency.Task { await toggleTask(task) }
                                }

                                Spacer()

                                // Explicit Edit & Delete action buttons on each row
                                HStack(spacing: 12) {
                                    Button {
                                        taskToEdit = task
                                    } label: {
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(.borderless)

                                    Button {
                                        taskToDelete = task
                                        showDeleteConfirmation = true
                                    } label: {
                                        Image(systemName: "trash.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                taskToEdit = task
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    taskToDelete = task
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    taskToEdit = task
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                        .onDelete(perform: deleteTasks)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingAddTask = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        logout()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddTask) {
                NavigationStack {
                    AddEditTaskView(existingTask: nil) {
                        _Concurrency.Task { await loadTasks() }
                    }
                }
            }
            .sheet(item: $taskToEdit) { task in
                NavigationStack {
                    AddEditTaskView(existingTask: task) {
                        _Concurrency.Task { await loadTasks() }
                    }
                }
            }
            .confirmationDialog(
                "Delete Task",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible,
                presenting: taskToDelete
            ) { task in
                Button("Delete \"\(task.title)\"", role: .destructive) {
                    deleteTaskDirectly(task)
                }
                Button("Cancel", role: .cancel) {}
            } message: { task in
                Text("Are you sure you want to delete this task? This action cannot be undone.")
            }
            .overlay(alignment: .bottom) {
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                        .padding()
                }
            }
        }
        .task {
            await loadTasks()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("No tasks yet")
                .font(.headline)
            Text("Tap + to add your first task.")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }

    // MARK: - Firebase calls

    private func loadTasks() async {
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }
        do {
            let fetched = try await FirebaseManager.shared.fetchTasks()
            withAnimation {
                tasks = fetched
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func toggleTask(_ task: Task) async {
        do {
            try await FirebaseManager.shared.updateTask(task)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteTaskDirectly(_ task: Task) {
        withAnimation {
            tasks.removeAll { $0.id == task.id }
        }

        _Concurrency.Task {
            do {
                try await FirebaseManager.shared.deleteTask(id: task.id)
            } catch {
                errorMessage = error.localizedDescription
                await loadTasks()
            }
        }
    }

    private func deleteTasks(at offsets: IndexSet) {
        // Grab the tasks being removed before the array changes.
        let tasksToDelete = offsets.map { tasks[$0] }

        withAnimation {
            tasks.remove(atOffsets: offsets)
        }

        _Concurrency.Task {
            for task in tasksToDelete {
                do {
                    try await FirebaseManager.shared.deleteTask(id: task.id)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func logout() {
        do {
            try FirebaseManager.shared.logout()
            isLoggedIn = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    TaskListView(isLoggedIn: .constant(true))
}
