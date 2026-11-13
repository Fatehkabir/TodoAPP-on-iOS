import SwiftUI

/// One row in the task list. Takes a @Binding to its Task so toggling the
/// checkbox updates the array back in TaskListView directly.
struct TaskRow: View {
    @Binding var task: Task
    var onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Image insertion — checkmark/circle SF Symbol as the completion toggle.
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(task.isCompleted ? .green : .gray)
                .onTapGesture {
                    withAnimation {
                        task.isCompleted.toggle()
                    }
                    onToggle()
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .gray : .primary)

                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .animation(.easeInOut, value: task.isCompleted)
    }
}
