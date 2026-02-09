import UIKit
import FirebaseAuth
import FirebaseFirestore
import IQKeyboardManagerSwift
import FirebaseStorage
import Kingfisher

final class ChatViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var messageTextfield: UITextField!
    @IBOutlet private weak var inputBarBottomConstraint: NSLayoutConstraint!
    
    private let db = Firestore.firestore()
    private var messages: [Message] = []
    private var userNames: [String: (first: String, last: String)] = [:]
    private var listener: ListenerRegistration?

    var receiverEmail: String?
    var receiverName: String?

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, HH:mm"
        return f
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = receiverName ?? Constants.appName

        tableView.dataSource = self
        tableView.delegate = self

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80

        tableView.register(
            UINib(nibName: Constants.cellNibName, bundle: nil),
            forCellReuseIdentifier: Constants.cellIdentifier
        )

        loadUserNames { [weak self] in
            self?.loadMessages()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        IQKeyboardManager.shared.isEnabled = false

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        listener?.remove()
        listener = nil

        IQKeyboardManager.shared.isEnabled = true
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let frame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }

        let keyboardHeight = frame.height - view.safeAreaInsets.bottom
        inputBarBottomConstraint.constant = -keyboardHeight

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }

        scrollToBottom(animated: true)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        inputBarBottomConstraint.constant = 0

        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }

    private func scrollToBottom(animated: Bool = true) {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }

    @IBAction private func sendPressed(_ sender: UIButton) {
        guard
            let body = messageTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            !body.isEmpty,
            let rawSender = Auth.auth().currentUser?.email,
            let rawReceiver = receiverEmail
        else { return }

        let senderEmail = rawSender.lowercased()
        let receiverEmail = rawReceiver.lowercased()

        db.collection(Constants.FStore.collectionName)
            .addDocument(data: [
                Constants.FStore.senderField: senderEmail,
                Constants.FStore.receiverField: receiverEmail,
                Constants.FStore.bodyField: body,
                Constants.FStore.messageTypeField: "text",
                Constants.FStore.imageURLField: "",
                "storagePath": "",
                Constants.FStore.dateField: FieldValue.serverTimestamp(),
                Constants.FStore.isReadField: false
            ]) { [weak self] error in
                guard let self = self else { return }
                if let e = error {
                    self.showErrorAlert("Could not send message: \(e.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        self.messageTextfield.text = ""
                    }
                }
            }
    }
    
    @IBAction private func logOutPressed(_ sender: UIBarButtonItem) {
        view.endEditing(true)

        listener?.remove()
        listener = nil

        do {
            try Auth.auth().signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch {
            showErrorAlert("Error signing out: \(error.localizedDescription)")
        }
    }

    @IBAction private func attachImagePressed(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        picker.dismiss(animated: true)

        guard
            let image = info[.originalImage] as? UIImage,
            let imageData = image.jpegData(compressionQuality: 0.7),
            let rawSender = Auth.auth().currentUser?.email,
            let rawReceiver = receiverEmail
        else { return }

        let senderEmail = rawSender.lowercased()
        let receiverEmail = rawReceiver.lowercased()

        let fileName = UUID().uuidString + ".jpg"
        let storagePath = "chat_images/\(fileName)"
        let storageRef = Storage.storage().reference().child(storagePath)

        storageRef.putData(imageData, metadata: nil) { [weak self] _, error in
            guard let self = self else { return }

            if let error = error {
                self.showErrorAlert("Upload failed: \(error.localizedDescription)")
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    self.showErrorAlert("Failed to get URL: \(error.localizedDescription)")
                    return
                }

                guard let urlString = url?.absoluteString else { return }

                self.db.collection(Constants.FStore.collectionName)
                    .addDocument(data: [
                        Constants.FStore.senderField: senderEmail,
                        Constants.FStore.receiverField: receiverEmail,
                        Constants.FStore.bodyField: "",
                        Constants.FStore.messageTypeField: "image",
                        Constants.FStore.imageURLField: urlString,
                        "storagePath": storagePath,
                        Constants.FStore.dateField: FieldValue.serverTimestamp(),
                        Constants.FStore.isReadField: false
                    ]) { error in
                        if let error = error {
                            self.showErrorAlert("Could not send image: \(error.localizedDescription)")
                        }
                    }
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    private func loadMessages() {
        guard
            let myRawEmail = Auth.auth().currentUser?.email,
            let otherRawEmail = receiverEmail
        else { return }

        let myEmail = myRawEmail.lowercased()
        let otherEmail = otherRawEmail.lowercased()

        listener = db.collection(Constants.FStore.collectionName)
            .order(by: Constants.FStore.dateField)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }

                if let error = error {
                    self.showErrorAlert("Failed: \(error.localizedDescription)")
                    return
                }

                guard let docs = querySnapshot?.documents else { return }

                var newMessages: [Message] = []

                for doc in docs {
                    let data = doc.data()

                    guard
                        let sender = data[Constants.FStore.senderField] as? String,
                        let receiver = data[Constants.FStore.receiverField] as? String
                    else { continue }

                    let senderLower = sender.lowercased()
                    let receiverLower = receiver.lowercased()

                    let isMyMessage = senderLower == myEmail && receiverLower == otherEmail
                    let isTheirMessage = senderLower == otherEmail && receiverLower == myEmail
                    if !(isMyMessage || isTheirMessage) { continue }

                    guard let timestamp = data[Constants.FStore.dateField] as? Timestamp else { continue }

                    let isRead = data[Constants.FStore.isReadField] as? Bool ?? false
                    let messageType = data[Constants.FStore.messageTypeField] as? String ?? "text"
                    let body = data[Constants.FStore.bodyField] as? String ?? ""
                    let imageURL = data[Constants.FStore.imageURLField] as? String
                    let storagePath = data["storagePath"] as? String

                    newMessages.append(
                        Message(
                            id: doc.documentID,
                            sender: senderLower,
                            body: body,
                            timestamp: timestamp,
                            isRead: isRead,
                            messageType: messageType,
                            imageURL: imageURL,
                            storagePath: storagePath
                        )
                    )
                }

                for doc in docs {
                    let data = doc.data()
                    if
                        let sender = data[Constants.FStore.senderField] as? String,
                        let receiver = data[Constants.FStore.receiverField] as? String,
                        sender.lowercased() == otherEmail,
                        receiver.lowercased() == myEmail,
                        (data[Constants.FStore.isReadField] as? Bool ?? false) == false
                    {
                        doc.reference.updateData([Constants.FStore.isReadField: true])
                    }
                }

                newMessages.sort { $0.timestamp.dateValue() < $1.timestamp.dateValue() }
                self.messages = newMessages

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.scrollToBottom()
                }
            }
    }

    private func loadUserNames(completion: @escaping () -> Void) {
        db.collection("users").getDocuments { [weak self] snapshot, _ in
            guard let self = self else { return }

            if let documents = snapshot?.documents {
                for doc in documents {
                    let data = doc.data()
                    if let email = data["email"] as? String,
                       let first = data["firstName"] as? String,
                       let last = data["lastName"] as? String {
                        self.userNames[email.lowercased()] = (first, last)
                    }
                }
            }
            completion()
        }
    }

    private func getInitials(for senderEmail: String) -> String {
        let key = senderEmail.lowercased()
        if let name = userNames[key] {
            let first = name.first.first?.uppercased() ?? ""
            let last  = name.last.first?.uppercased() ?? ""
            return first + last
        }
        return "?"
    }

    private func deleteMessage(_ message: Message) {
       
        db.collection(Constants.FStore.collectionName)
            .document(message.id)
            .delete { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    self.showErrorAlert("Delete failed: \(error.localizedDescription)")
                    return
                }
            }

        if message.messageType == "image",
           let path = message.storagePath,
           !path.isEmpty {
            Storage.storage().reference().child(path).delete(completion: nil)
        }
    }

    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension ChatViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let message = messages[indexPath.row]

        let cell = tableView.dequeueReusableCell(
            withIdentifier: Constants.cellIdentifier,
            for: indexPath
        ) as! MessageCell

        cell.accessibilityIdentifier = message.id

        cell.texttLabel.isHidden = false
        cell.texttLabel.text = ""
        cell.messageImageView.isHidden = true
        cell.messageImageHeightConstraint.constant = 0
        cell.messageImageView.image = nil
        cell.messageImageView.kf.cancelDownloadTask()

        cell.dateLabel.text = dateFormatter.string(from: message.timestamp.dateValue())

        if message.messageType == "image",
           let urlString = message.imageURL,
           !urlString.isEmpty {

            cell.texttLabel.isHidden = true
            cell.messageImageView.isHidden = false

            let maxWidth = tableView.bounds.width * 0.6

            cell.messageImageView.kf.setImage(with: URL(string: urlString)) { [weak tableView, weak cell] result in
                guard let tableView = tableView,
                      let cell = cell else { return }

                guard cell.accessibilityIdentifier == message.id else { return }

                if case let .success(value) = result {
                    let image = value.image
                    let ratio = image.size.height / max(image.size.width, 1)
                    cell.messageImageHeightConstraint.constant = maxWidth * ratio

                    UIView.performWithoutAnimation {
                        tableView.beginUpdates()
                        tableView.endUpdates()
                    }
                }
            }

        } else {
            cell.texttLabel.isHidden = false
            cell.texttLabel.text = message.body
            cell.messageImageView.isHidden = true
            cell.messageImageHeightConstraint.constant = 0
        }

        let myEmail = Auth.auth().currentUser?.email?.lowercased()

        if message.sender.lowercased() == myEmail {
            cell.rightImageView.isHidden = false
            cell.leftImageLabel.isHidden = true
            cell.nameLabel.isHidden = true

            cell.messageBubble.backgroundColor = UIColor(named: Constants.BrandColors.brandPink)
            cell.texttLabel.textColor = .white
            cell.dateLabel.textAlignment = .right
        } else {
            cell.rightImageView.isHidden = true
            cell.leftImageLabel.isHidden = false
            cell.nameLabel.isHidden = false

            cell.messageBubble.backgroundColor = UIColor(named: Constants.BrandColors.lightPurple)
            cell.texttLabel.textColor = .black
            cell.dateLabel.textAlignment = .left

            cell.leftImageLabel.text = getInitials(for: message.sender)
            if let name = userNames[message.sender.lowercased()] {
                cell.nameLabel.text = "\(name.first) \(name.last)"
            } else {
                cell.nameLabel.text = "Unknown User"
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        let message = messages[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            self?.deleteMessage(message)
            done(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
