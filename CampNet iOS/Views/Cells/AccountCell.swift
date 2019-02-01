//
//  AccountCell.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/13.
//  Copyright © 2019年 Sihan Li. All rights reserved.
//

import UIKit
import CampNetKit

class AccountCell: UITableViewCell {

    @IBOutlet var checkmark: UIImageView!
    @IBOutlet var username: UILabel!
    @IBOutlet var balance: UILabel!
    @IBOutlet var usage: UILabel!

    var isMain = false {
        didSet {
            username.textColor = isMain ? #colorLiteral(red: 0.1934785199, green: 0.7344816453, blue: 0.9803921569, alpha: 1) : .darkText
        }
    }

    var isDelegate = false {
        didSet {
            checkmark.isHidden = !isDelegate
        }
    }

    func update(account: Account, isMain: Bool, isDelegate: Bool) {
        let profile = account.profile

        if let name = profile?.name {
            self.username.text = "\(account.username) (\(name))"
        } else {
            self.username.text = account.username
        }
        if let moneyString = profile?.balance?.moneyString {
            self.balance.text = "¥ \(moneyString)"
        } else {
            self.balance.text = nil
        }
        self.usage.text = profile?.usage?.usageString(decimalUnits: account.configuration.decimalUnits)

        self.isMain = isMain
        self.isDelegate = isDelegate
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
