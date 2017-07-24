//
//  SecondViewController.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/1/17.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import UIKit
import CampNetKit

class SessionsViewController: UITableViewController {
    
    @IBAction func ipLoggedIn(segue: UIStoryboardSegue) {
        if let controller = segue.source as? LoginIpViewController,
           let ip = controller.ipField.text,
           let account = mainAccount {
            
            let delegate = UIApplication.shared.delegate as! AppDelegate
            
            delegate.setNetworkActivityIndicatorVisible(true)
            account.login(ip: ip, on: DispatchQueue.global(qos: .userInitiated)).always {
                delegate.setNetworkActivityIndicatorVisible(false)
            }
            .catch { error in
                if let error = error as? CampNetError {
                    self.presentAlert(title: String.localizedStringWithFormat(NSLocalizedString("Unable to Login %@", comment: "Alert title when failed to login IP."), ip), message: error.localizedDescription)
                }
            }
        }
    }
    
    @IBAction func refresh(_ sender: Any) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        
        delegate.setNetworkActivityIndicatorVisible(true)
        
        if let account = mainAccount {
            account.profile(on: DispatchQueue.global(qos: .userInitiated)).always {
                self.refreshControl?.endRefreshing()
                delegate.setNetworkActivityIndicatorVisible(false)
                }
                .catch { error in
                    if let error = error as? CampNetError {
                        self.presentAlert(title: String.localizedStringWithFormat(NSLocalizedString("Unable to Update Profile of \"%@\"", comment: "Alert title when failed to update account profile."), account.username), message: error.localizedDescription)
                    }
            }
        }
    }
    
    enum Section: Int {
        case sessions
        case newSession
    }
    
    var mainAccount: Account?
    var profile: Profile?
    
    var sessions: [Session] {
        return profile?.sessions ?? []
    }
    var expandedIndex: Int = -1
    var expandedHeight: Int {
        return (expandedIndex < 0) ? 0 : SessionDetailCell.types
    }
    var expansionRange: Range<Int> {
        return (expandedIndex + 1)..<(expandedIndex + expandedHeight + 1)
    }
    var canLoginIp: Bool {
        return mainAccount?.configuration.actions[.loginIp] != nil
    }
    
    func indexPaths(for index: Int) -> [IndexPath] {
        if index < expandedIndex {
            return [IndexPath(row: index, section: Section.sessions.rawValue)]
        } else if index > expandedIndex {
            return [IndexPath(row: index + expandedHeight, section: Section.sessions.rawValue)]
        } else {
            return (0...expandedHeight).map {
                IndexPath(row: index + $0, section: Section.sessions.rawValue)
            }
        }
    }
    
    var expandedIndexPaths: [IndexPath] {
        return (1..<(expandedHeight + 1)).map {
            IndexPath(row: expandedIndex + $0, section: Section.sessions.rawValue)
        }
    }
    
    func isSessionCell(_ row: Int) -> Bool {
        return !(expansionRange ~= row || row >= sessions.count + expandedHeight)
    }

    func mainChanged(_ notification: Notification) {
        mainAccount = Account.main
        profile = mainAccount?.profile
        
        tableView.reloadData()
    }
    
    func profileUpdated(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let profile = notification.userInfo?["profile"] as? Profile,
              mainAccount == account else {
            return
        }
        
        tableView.beginUpdates()
        
        let oldIps = sessions.map({ $0.ip })
        self.profile = profile
        
        // Update sessions section.
        let ips = profile.sessions.map({ $0.ip })

        var rows: [IndexPath] = []
        for (index, oldIp) in oldIps.enumerated() {
            let indexPaths = self.indexPaths(for: index)
            
            if let index = ips.index(of: oldIp) {
                let cell = tableView.cellForRow(at: indexPaths.first!) as! SessionCell
                let session = sessions[index]
                
                cell.update(session: session, decimalUnits: account.configuration.decimalUnits)
                
                // Update detail cells if needed.
                for offset in 1..<indexPaths.count {
                    let cell = tableView.cellForRow(at: indexPaths[offset]) as! SessionDetailCell
                    cell.update(session: session, offset: offset)
                }
            } else {
                rows.append(contentsOf: indexPaths)
            }
        }
        tableView.deleteRows(at: rows, with: .automatic)
        
        if expandedIndex > 0 {
            if let index = ips.index(of: oldIps[expandedIndex]) {
                expandedIndex = index
            } else {
                expandedIndex = -1
            }
        }
        
        rows = []
        for (index, ip) in ips.enumerated() {
            if !oldIps.contains(ip) {
                rows.append(contentsOf: indexPaths(for: index))
            }
        }
        tableView.insertRows(at: rows, with: .automatic)
        
        tableView.endUpdates()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.mainAccount = Account.main
        self.profile = self.mainAccount?.profile
        
        NotificationCenter.default.addObserver(self, selector: #selector(mainChanged(_:)), name: .mainAccountChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(profileUpdated(_:)), name: .accountProfileUpdated, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return canLoginIp ? 2 : 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.sessions.rawValue:
            return sessions.count + expandedHeight
        case Section.newSession.rawValue:
            return 1
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case Section.sessions.rawValue:
            return 48
        case Section.newSession.rawValue:
            return 48
        default:
            return tableView.rowHeight
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == Section.sessions.rawValue {
            switch indexPath.row {
            case expansionRange:
                let cell = tableView.dequeueReusableCell(withIdentifier: "sessionDetailCell", for: indexPath) as! SessionDetailCell
                
                cell.update(session: sessions[expandedIndex], offset: indexPath.row - expandedIndex)
                
                return cell

            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "sessionCell", for: indexPath) as! SessionCell
                
                cell.update(session: sessions[indexPath.row], decimalUnits: mainAccount?.configuration.decimalUnits ?? false)
                
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "loginIpCell", for: indexPath)
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == Section.sessions.rawValue {
            tableView.deselectRow(at: indexPath, animated: true)
            
            if isSessionCell(indexPath.row) {
                if expandedIndex < 0 {
                    expandedIndex = indexPath.row
                    tableView.insertRows(at: self.expandedIndexPaths, with: .top)
                } else if expandedIndex == indexPath.row {
                    let indexPaths = expandedIndexPaths
                    expandedIndex = -1
                    
                    tableView.deleteRows(at: indexPaths, with: .top)
                } else {
                    let indexPathsToDelete = expandedIndexPaths
                    if indexPath.row < expandedIndex {
                        expandedIndex = indexPath.row
                    } else {
                        expandedIndex = indexPath.row - expandedHeight
                    }
                    let indexPathsToInsert = expandedIndexPaths
                    
                    tableView.beginUpdates()
                    tableView.deleteRows(at: indexPathsToDelete, with: .top)
                    tableView.insertRows(at: indexPathsToInsert, with: .top)
                    tableView.endUpdates()
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == Section.sessions.rawValue {
            return isSessionCell(indexPath.row)
        } else {
            return false
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return NSLocalizedString("Logout", comment: "Title for delete confirmation button for sessions.")
    }
 
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            var index = indexPath.row
            if indexPath.row > expandedIndex {
                index -= expandedHeight
            }
            let session = sessions[index]
            let delegate = UIApplication.shared.delegate as! AppDelegate
            
            delegate.setNetworkActivityIndicatorVisible(true)
            
            _ = mainAccount?.logoutSession(session: session, on: DispatchQueue.global(qos: .userInitiated)).catch { error in
                if let error = error as? CampNetError {
                    self.presentAlert(title: String.localizedStringWithFormat(NSLocalizedString("Unable to Logout \"%@\"", comment: "Alert title when failed to logout a session."), session.device ?? session.ip), message: error.localizedDescription)
                }
            }
            .always {
                delegate.setNetworkActivityIndicatorVisible(false)
            }
        }
        
        tableView.setEditing(false, animated: true)
    }

    
    /*
      Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
      Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
      Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
      MARK: - Navigation
     
      In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      Get the new view controller using segue.destinationViewController.
      Pass the selected object to the new view controller.
     }
     */
    
}
