//
//  SessionCell.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/16.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import UIKit
import CampNetKit

class SessionCell: UITableViewCell {

    @IBOutlet var device: UILabel!
    @IBOutlet var startTime: UILabel!
    @IBOutlet var usage: UILabel!
    
    func update(session: Session, decimalUnits: Bool) {
        device.text = session.device ?? session.ip
        if let time = session.startTime {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.day, .hour, .minute]
            formatter.unitsStyle = .abbreviated
            formatter.maximumUnitCount = 1
            
            startTime.text = formatter.string(from: -time.timeIntervalSinceNow)
        } else {
            startTime.text = nil
        }
        usage.text = session.usage?.usageString(decimalUnits: decimalUnits)
        
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
