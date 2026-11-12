import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Every single Firebase call the app makes lives here — both Authentication
/// and Firestore (the "database"). Keeping it all in one simple class makes it
/// easy to see the whole backend in one file.
class FirebaseManager {
    static let shared = FirebaseManager()
    private init() {}

    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    // MARK: - Authentication

    var currentUserId: String? {
        auth.currentUser?.uid
    }

    func signUp(email: String, password: String) async throws {
        try await auth.createUser(withEmail: email, password: password)
    }

    func login(email: String, password: String) async throws {
        try await auth.signIn(withEmail: email, password: password)
    }

    func logout() throws {
        try auth.signOut()
    }

    // MARK: - Firestore CRUD (Create, Read, Update, Delete)

    /// CREATE — adds a brand-new task document, tagged with the signed-in user's id
    /// so later we only ever read back *this* user's own tasks.
    func addTask(title: String, description: String) async throws {
        guard let uid = currentUserId else { return }

        let data: [String: Any] = [
            "title": title,
            "description": description,
            "isCompleted": false,
            "userId": uid
        ]
        try await db.collection("tasks").addDocument(data: data)
    }

    /// READ — fetches every task that belongs to the signed-in user.
    func fetchTasks() async throws -> [Task] {
        guard let uid = currentUserId else { return [] }

        let snapshot = try await db.collection("tasks")
            .whereField("userId", isEqualTo: uid)
            .getDocuments()

        // A plain for loop over the documents, building up an array —
        // exactly the pattern from the "for loop" and "array" lessons.
        var tasks: [Task] = []
        for document in snapshot.documents {
            let data = document.data()
            let task = Task(
                id: document.documentID,
                title: data["title"] as? String ?? "",
                description: data["description"] as? String ?? "",
                isCompleted: data["isCompleted"] as? Bool ?? false,
                userId: data["userId"] as? String ?? ""
            )
            tasks.append(task)
        }
        return tasks
    }

    /// UPDATE — used both when editing a task's title/description, and when
    /// toggling its "completed" checkbox.
    func updateTask(_ task: Task) async throws {
        try await db.collection("tasks").document(task.id).updateData([
            "title": task.title,
            "description": task.description,
            "isCompleted": task.isCompleted
        ])
    }

    /// DELETE
    func deleteTask(id: String) async throws {
        try await db.collection("tasks").document(id).delete()
    }
}
