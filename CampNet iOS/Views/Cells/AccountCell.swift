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

    @IBOutlet var username: UILabel!
    @IBOutlet var name: UILabel!
    @IBOutlet var balance: UILabel!
    @IBOutlet var usage: UILabel!
    
    var unauthorized: Bool = false {
        didSet {
            username.textColor = unauthorized ? .red : .darkText
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
