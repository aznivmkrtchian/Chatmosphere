import UIKit
import FirebaseAuth
import FirebaseFirestore

final class RegisterViewController: UIViewController {
    
    private let db = Firestore.firestore()
    
    @IBOutlet private weak var emailTextfield: UITextField!
    @IBOutlet private weak var passwordTextfield: UITextField!
    @IBOutlet private weak var firstNameTextfield: UITextField!
    @IBOutlet private weak var lastNameTextfield: UITextField!
    
    @IBAction private func registerPressed(_ sender: UIButton) {
        guard
            let first = firstNameTextfield.text, !first.isEmpty,
            let last = lastNameTextfield.text, !last.isEmpty,
            let email = emailTextfield.text, !email.isEmpty,
            let password = passwordTextfield.text, !password.isEmpty
        else {
            showErrorAlert("Please fill in all fields.")
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }

            if let e = error {
                self.showErrorAlert("Registration failed: \(e.localizedDescription)")
                return
            }

            guard let user = authResult?.user else {
                self.showErrorAlert("Something went wrong. Please try again.")
                return
            }

            self.db.collection("users").document(user.uid).setData([
                "uid": user.uid,
                "email": email,
                "firstName": first,
                "lastName": last,
                "createdAt": FieldValue.serverTimestamp()
            ]) { err in
                if let err = err {
                    self.showErrorAlert("Error saving user: \(err.localizedDescription)")
                } else {
                    print("User saved successfully")
                    self.performSegue(withIdentifier: "GoToUsers", sender: self)
                }
            }
        }
    }

    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
}
