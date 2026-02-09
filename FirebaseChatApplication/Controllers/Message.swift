import Foundation
import FirebaseFirestore

struct Message {
    let id: String
    let sender: String
    let body: String
    let timestamp: Timestamp
    let isRead: Bool
    let messageType: String
    let imageURL: String?
    let storagePath: String?
    var imageHeight: CGFloat?
}
