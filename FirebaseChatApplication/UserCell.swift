import UIKit

final class UserCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var unreadBadgeView: UIView!
    @IBOutlet weak var unreadBadgeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        unreadBadgeView.clipsToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        unreadBadgeView.layer.cornerRadius = unreadBadgeView.bounds.height / 2
    }
}
