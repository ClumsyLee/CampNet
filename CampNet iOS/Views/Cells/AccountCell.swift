//
//  AccountCell.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/13.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import UIKit
import CampNetKit

class AccountCell: UITableViewCell {
    
    static let mainColor = #colorLiteral(red: 0.1568627451, green: 0.7230392156, blue: 0.9803921569, alpha: 1)
    static let normalColor = UIColor.darkText

    @IBOutlet var username: UILabel!
    @IBOutlet var name: UILabel!
    @IBOutlet var balance: UILabel!
    @IBOutlet var usage: UILabel!
    
    var isMain = false {
        didSet {
            let color = isMain ? AccountCell.mainColor : AccountCell.normalColor
            
            username.textColor = color
            name.textColor = color
            balance.textColor = color
            usage.textColor = color
        }
    }
    
    func update(profile: Profile?, decimalUnits: Bool) {
        if let name = profile?.name {
            self.name.text = "(\(name))"
        } else {
            self.name.text = nil
        }
        if let balance = profile?.balance {
            self.balance.text = "¥ \(balance)"
        } else {
            self.balance.text = nil
        }
        self.usage.text = profile?.usage?.usageString(decimalUnits: decimalUnits)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
