import Foundation


struct Task: Identifiable, Hashable {
    var id: String
    var title: String
    var description: String
    var isCompleted: Bool
    var userId: String
}
