//
//  MainAccountCell.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/16.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import UIKit
import CampNetKit

class MainAccountCell: UITableViewCell {

    @IBOutlet var logo: UIImageView!
    @IBOutlet var username: UILabel!
    @IBOutlet var name: UILabel!
    @IBOutlet var balance: UILabel!
    @IBOutlet var usage: UILabel!
    
    var unauthorized: Bool = false {
        didSet {
            if let attributedText = username.attributedText {
                let text = NSMutableAttributedString(attributedString: attributedText)
                let range = NSMakeRange(0, text.length)
                
                if unauthorized {
                    text.addAttribute(NSStrikethroughStyleAttributeName, value: 1, range: range)
                } else {
                    text.removeAttribute(NSStrikethroughStyleAttributeName, range: range)
                }
                
                username.attributedText = text
            }
        }
    }
    
    func update(profile: Profile?, decimalUnits: Bool) {
        if let name = profile?.name {
            self.name.text = "(\(name))"
        } else {
            self.name.text = nil
        }
        if let balance = profile?.balance {
            self.balance.text = String(format: "¥ %.2f", balance)
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
