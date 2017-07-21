//
//  SessionDetailCell.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/20.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import UIKit
import CampNetKit

class SessionDetailCell: UITableViewCell {

    enum SessionDetail: Int {
        case startTime = 1
        case ip
        case mac
    }
    static let types = 3
    
    @IBOutlet var name: UILabel!
    @IBOutlet var value: UILabel!
    
    func update(session: Session, offset: Int) {
        switch offset {
        case SessionDetail.startTime.rawValue:
            name.text = NSLocalizedString("Login Time", comment: "Name of startTime field in session detail cell.")
            if let startTime = session.startTime {
                value.text = DateFormatter.localizedString(from: startTime, dateStyle: .medium, timeStyle: .short)
            } else {
                value.text = nil
            }
        case SessionDetail.ip.rawValue:
            name.text = NSLocalizedString("IP Address", comment: "Name of ip field in session detail cell.")
            value.text = session.ip
        case SessionDetail.mac.rawValue:
            name.text = NSLocalizedString("MAC Address", comment: "Name of mac field in session detail cell.")
            value.text = session.mac
        default:
            name.text = nil
            value.text = nil
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
