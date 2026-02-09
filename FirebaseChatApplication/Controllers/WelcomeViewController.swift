import UIKit
import LTMorphingLabel

final class WelcomeViewController: UIViewController {

    @IBOutlet private weak var titleLabel: LTMorphingLabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*titleLabel.text = ""
        var charIndex = 0.0
        let titleText = "💬Chatmosphere"
        for letter in titleText {
            Timer.scheduledTimer(withTimeInterval: 0.1 * charIndex, repeats: false) {
                (timer) in
                self.titleLabel.text?.append(letter)
            }
            charIndex += 1
        }*/
        
        titleLabel.morphingEffect = .scale
        titleLabel.text = ""
            
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.titleLabel.text = Constants.appName
        }
    }

}
