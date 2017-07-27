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
           let account = account {
            
            let delegate = UIApplication.shared.delegate as! AppDelegate
            delegate.setNetworkActivityIndicatorVisible(true)
            
            account.login(ip: ip, on: DispatchQueue.global(qos: .userInitiated)).always {
                delegate.setNetworkActivityIndicatorVisible(false)
            }
        }
    }
    
    @IBAction func refresh(_ sender: Any) {
        guard let account = account else {
            self.refreshControl?.endRefreshing()
            return
        }
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.setNetworkActivityIndicatorVisible(true)

        account.profile(on: DispatchQueue.global(qos: .userInitiated)).always {
            self.refreshControl?.endRefreshing()
            delegate.setNetworkActivityIndicatorVisible(false)
        }
    }
    
    enum Section: Int {
        case sessions
        case newSession
    }
    
    var account: Account?
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
        return account?.configuration.actions[.loginIp] != nil
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
    
    func reloadModel() {
        account = Account.main
        profile = account?.profile
    }

    func mainChanged(_ notification: Notification) {
        reloadModel()
        tableView.reloadData()
    }
    
    func profileUpdated(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              let profile = notification.userInfo?["profile"] as? Profile,
              account == account else {
            return
        }
        
        let oldIps = sessions.map({ $0.ip })
        self.profile = profile
        let ips = profile.sessions.map({ $0.ip })

        if oldIps.isEmpty && !ips.isEmpty {
            tableView.insertSections(IndexSet(integer: Section.sessions.rawValue), with: .automatic)
        } else if !oldIps.isEmpty && ips.isEmpty {
            tableView.deleteSections(IndexSet(integer: Section.sessions.rawValue), with: .automatic)
        } else if !oldIps.isEmpty && !ips.isEmpty {
            
            var rowsToDelete: [IndexPath] = []
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
                    rowsToDelete.append(contentsOf: indexPaths)
                }
            }
            
            if expandedIndex > 0 {
                if let index = ips.index(of: oldIps[expandedIndex]) {
                    expandedIndex = index
                } else {
                    expandedIndex = -1
                }
            }
            
            var rowsToInsert: [IndexPath] = []
            for (index, ip) in ips.enumerated() {
                if !oldIps.contains(ip) {
                    rowsToInsert.append(contentsOf: indexPaths(for: index))
                }
            }
            
            tableView.beginUpdates()
            tableView.deleteRows(at: rowsToDelete, with: .automatic)
            tableView.insertRows(at: rowsToInsert, with: .automatic)
            tableView.endUpdates()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.reloadModel()
        
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
        return (!sessions.isEmpty ? 1 : 0) + (canLoginIp ? 1 : 0)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sessions.isEmpty {
            return 1
        } else {
            switch section {
            case Section.sessions.rawValue:
                return sessions.count + expandedHeight
            case Section.newSession.rawValue:
                return 1
            default:
                return 0
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if sessions.isEmpty || indexPath.section == Section.newSession.rawValue {
            let cell = tableView.dequeueReusableCell(withIdentifier: "loginIpCell", for: indexPath)
            
            return cell
        } else {
            switch indexPath.row {
            case expansionRange:
                let cell = tableView.dequeueReusableCell(withIdentifier: "sessionDetailCell", for: indexPath) as! SessionDetailCell
                
                cell.update(session: sessions[expandedIndex], offset: indexPath.row - expandedIndex)
                
                return cell
                
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "sessionCell", for: indexPath) as! SessionCell
                
                cell.update(session: sessions[indexPath.row], decimalUnits: account?.configuration.decimalUnits ?? false)
                
                return cell
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if !sessions.isEmpty && indexPath.section == Section.sessions.rawValue && isSessionCell(indexPath.row) {
            
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
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return !sessions.isEmpty && indexPath.section == Section.sessions.rawValue && isSessionCell(indexPath.row)
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
            
            _ = account?.logoutSession(session: session, on: DispatchQueue.global(qos: .userInitiated)).always {
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
