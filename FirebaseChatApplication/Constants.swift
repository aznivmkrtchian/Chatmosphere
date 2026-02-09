struct Constants {
    static let appName = "💬Chatmosphere"
    static let cellIdentifier = "ReusableCell"
    static let cellNibName = "MessageCell"
    static let registerSegue = "RegisterToChat"
    static let loginSegue = "LoginToChat"
    
    struct BrandColors {
        static let lightPurple = "BrandLightPurple"
        static let brandPink = "BrandLightPink"
        static let burgundy = "BrandBurgundy"
        static let darkPink = "BrandDarkPink"
    }
    
    struct FStore {
        static let collectionName = "messages"
        static let senderField = "sender"
        static let receiverField = "receiver"
        static let bodyField = "body"
        static let dateField = "date"
        static let isReadField = "isRead"
        static let imageURLField = "imageURL"
        static let messageTypeField = "messageType"
    }
}
