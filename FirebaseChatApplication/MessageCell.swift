import UIKit
import Kingfisher

final class MessageCell: UITableViewCell {
    
    @IBOutlet weak var messageBubble: UIView!
    @IBOutlet weak var texttLabel: UILabel!
    @IBOutlet weak var rightImageView: UIImageView!
    @IBOutlet weak var leftImageLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var messageImageView: UIImageView!
    @IBOutlet weak var messageImageHeightConstraint: NSLayoutConstraint!
        
    override func awakeFromNib() {
        super.awakeFromNib()
        
        leftImageLabel.clipsToBounds = true
        rightImageView.clipsToBounds = true
        
        messageBubble.layer.cornerRadius = 15
        messageBubble.clipsToBounds = true
        
        messageImageView.layer.cornerRadius = 12
        messageImageView.clipsToBounds = true
        messageImageView.contentMode = .scaleAspectFit
        
        messageImageView.isHidden = true
        messageImageHeightConstraint.constant = 0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        leftImageLabel.layer.cornerRadius = leftImageLabel.bounds.height / 2
        rightImageView.layer.cornerRadius = rightImageView.bounds.height / 2
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        texttLabel.text = ""
        messageImageView.image = nil
        messageImageView.kf.cancelDownloadTask()

        messageImageView.isHidden = true
        messageImageHeightConstraint.constant = 0

    }
}




