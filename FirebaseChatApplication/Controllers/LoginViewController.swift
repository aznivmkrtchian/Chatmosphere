import UIKit
import FirebaseAuth

final class LoginViewController: UIViewController {
    
    @IBOutlet private weak var emailTextfield: UITextField!
    @IBOutlet private weak var passwordTextfield: UITextField!
    
    @IBAction private func loginPressed(_ sender: UIButton) {
        guard let email = emailTextfield.text,
              let password = passwordTextfield.text,
            !email.isEmpty, !password.isEmpty else {
                showErrorAlert("Please enter both email and password.")
                return
            }
        
        sender.isEnabled = false
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            guard let self = self else { return }
            sender.isEnabled = true
            if let e = error {
                self.showErrorAlert("Login failed: \(e.localizedDescription)")
                return
            }
            self.performSegue(withIdentifier: "GoToUsers", sender: self)
        }
    }
    
    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
}
