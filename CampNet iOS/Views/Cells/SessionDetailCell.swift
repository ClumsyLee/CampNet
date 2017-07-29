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
    
    func update(session: Session, offset: Int) {
        switch offset {
        case SessionDetail.startTime.rawValue:
            textLabel?.text = NSLocalizedString("Login Time", comment: "Name of startTime field in session detail cell.")
            if let startTime = session.startTime {
                detailTextLabel?.text = DateFormatter.localizedString(from: startTime, dateStyle: .medium, timeStyle: .short)
            } else {
                detailTextLabel?.text = nil
            }
        case SessionDetail.ip.rawValue:
            textLabel?.text = NSLocalizedString("IP Address", comment: "Name of ip field in session detail cell.")
            detailTextLabel?.text = session.ip
        case SessionDetail.mac.rawValue:
            textLabel?.text = NSLocalizedString("MAC Address", comment: "Name of mac field in session detail cell.")
            detailTextLabel?.text = session.mac
        default:
            textLabel?.text = nil
            detailTextLabel?.text = nil
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
