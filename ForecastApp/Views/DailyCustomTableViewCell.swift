import UIKit

class DailyCustomTableViewCell: UITableViewCell {

    
    @IBOutlet weak var parameterLabel: UILabel!
    @IBOutlet weak var secondParameterLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var secondValueLabel: UILabel!

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
