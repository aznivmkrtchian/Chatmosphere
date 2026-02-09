import UIKit
import FirebaseAuth
import FirebaseFirestore

final class UsersViewController: UIViewController {
    
    @IBOutlet private weak var tableView: UITableView!
    
    private let db = Firestore.firestore()
    private var users: [(email: String, name: String)] = []
    private var unreadCounts: [String: Int] = [:]
    private var unreadListener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Users💬"
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(UINib(nibName: "UserCell", bundle: nil),
                           forCellReuseIdentifier: "UserCell")
        
        loadUsers()
    }
    
    private func loadUsers() {
        
        db.collection("users").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let e = error {
                print("Error loading users: \(e.localizedDescription)")
                return
            }
            
            var list: [(email: String, name: String)] = []
            let myEmail = Auth.auth().currentUser?.email?.lowercased()
            
            snapshot?.documents.forEach { doc in
                let d = doc.data()
                let rawEmail = d["email"] as? String ?? ""
                let email = rawEmail.lowercased()
                let first = d["firstName"] as? String ?? ""
                let last = d["lastName"]  as? String ?? ""
                
                if !email.isEmpty, email != myEmail {
                    list.append((email: email, name: "\(first) \(last)"))
                }
            }
            
            self.users = list.sorted { $0.name < $1.name }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
            self.loadUnreadCounts()
        }
    }
    
    private func loadUnreadCounts() {
        
        guard let myEmail = Auth.auth().currentUser?.email?.lowercased() else { return }
        
        unreadListener = db.collection(Constants.FStore.collectionName)
            .whereField(Constants.FStore.receiverField, isEqualTo: myEmail)
            .whereField(Constants.FStore.isReadField, isEqualTo: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let e = error {
                    print("Error loading unread counts: \(e.localizedDescription)")
                    return
                }
                
                var newCounts: [String: Int] = [:]
                
                snapshot?.documents.forEach { doc in
                    let data = doc.data()
                    if let sender = data[Constants.FStore.senderField] as? String {
                        let key = sender.lowercased()
                        newCounts[key, default: 0] += 1
                    }
                }
                
                self.unreadCounts = newCounts
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
    
    deinit {
        unreadListener?.remove()
    }
}
    
extension UsersViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        users.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "UserCell",
            for: indexPath
        ) as! UserCell

        let user = users[indexPath.row]

        cell.nameLabel.text  = user.name
        cell.emailLabel.text = user.email

        let key = user.email.lowercased()
        
        if let count = unreadCounts[key], count > 0 {
            cell.unreadBadgeView.isHidden = false
            cell.unreadBadgeLabel.text    = "\(count)"
        } else {
            cell.unreadBadgeView.isHidden = true
        }

        return cell
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        
        let selected = users[indexPath.row]
        performSegue(withIdentifier: "GoToChat", sender: selected)
        
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToChat",
           let dest = segue.destination as? ChatViewController,
           let selected = sender as? (email: String, name: String) {
                dest.receiverEmail = selected.email
                dest.receiverName  = selected.name
            }
    }
}
