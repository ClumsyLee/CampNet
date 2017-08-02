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
    
    static let mainColor = #colorLiteral(red: 0.1934785199, green: 0.7344816453, blue: 0.9803921569, alpha: 1)
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
        }
    }
    
    func update(account: Account, isMain: Bool) {
        let profile = account.profile
        
        username.text = account.username
        if let name = profile?.name {
            self.name.text = "(\(name))"
        } else {
            self.name.text = nil
        }
        if let moneyString = profile?.balance?.moneyString {
            self.balance.text = "¥ \(moneyString)"
        } else {
            self.balance.text = nil
        }
        self.usage.text = profile?.usage?.usageString(decimalUnits: account.configuration.decimalUnits)
        
        self.isMain = isMain
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
