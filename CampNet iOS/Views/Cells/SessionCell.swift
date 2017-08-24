//
//  SessionCell.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/16.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import UIKit
import CampNetKit

enum SessionType {
    case normal
    case current
    case expired
}

class SessionCell: UITableViewCell {
    @IBOutlet var device: UILabel!
    @IBOutlet var startTime: UILabel!
    @IBOutlet var usage: UILabel!
    
    var type: SessionType = .normal {
        didSet {
            let color: UIColor
            switch type {
            case .normal: color = .darkText
            case .current: color = #colorLiteral(red: 0.1934785199, green: 0.7344816453, blue: 0.9803921569, alpha: 1)
            case .expired: color = #colorLiteral(red: 1, green: 0.3300932944, blue: 0.2421161532, alpha: 1)
            }
            device.textColor = color
        }
    }
    
    func update(session: Session, type: SessionType, decimalUnits: Bool) {
        device.text = session.device ?? session.ip
        updateStartTime(date: session.startTime)
        usage.text = session.usage?.usageString(decimalUnits: decimalUnits)
        
        self.type = type
    }
    
    func updateStartTime(date: Date?) {
        if let time = date {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.day, .hour, .minute]
            formatter.unitsStyle = .abbreviated
            formatter.maximumUnitCount = 1
            
            startTime.text = formatter.string(from: -time.timeIntervalSinceNow)
        } else {
            startTime.text = nil
        }
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
