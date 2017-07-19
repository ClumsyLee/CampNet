//
//  SecondViewController.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/1/17.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import UIKit
import CampNetKit

class MeViewController: UITableViewController {
    
    @IBAction func cancelLoginIp(segue: UIStoryboardSegue) {}
    @IBAction func loggedInIp(segue: UIStoryboardSegue) {}
    
    enum Section: Int {
        case mainAccount
        case sessions
    }
    
    var mainAccount: Account?
    var profile: Profile?
    var sessions: [Session] {
        return profile?.sessions ?? []
    }
    var canLoginIp: Bool {
        return mainAccount?.configuration.actions[.loginIp] != nil
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
        
        // Update main account section.
        let indexPath = IndexPath(row: 0, section: Section.mainAccount.rawValue)
        if let cell = tableView.cellForRow(at: indexPath) as? MainAccountCell {
            cell.update(profile: profile, decimalUnits: account.configuration.decimalUnits)
        } else {
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        
        // Update sessions section.
        let ips = profile.sessions.map({ $0.ip })

        var rows: [IndexPath] = []
        for (index, oldIp) in oldIps.enumerated() {
            if !ips.contains(oldIp) {
                rows.append(IndexPath(row: index, section: Section.sessions.rawValue))
            }
        }
        tableView.deleteRows(at: rows, with: .automatic)
        
        rows = []
        for (index, ip) in ips.enumerated() {
            if !oldIps.contains(ip) {
                rows.append(IndexPath(row: index, section: Section.sessions.rawValue))
            }
        }
        tableView.insertRows(at: rows, with: .automatic)
        
        tableView.endUpdates()
    }
    
    func authorizationChanged(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account,
              mainAccount == account else {
            return
        }
        let cell = tableView.cellForRow(at: IndexPath(row: 0, section: Section.mainAccount.rawValue)) as! MainAccountCell
        cell.unauthorized = account.unauthorized
    }
    
    func refresh(sender:AnyObject)
    {
        if let account = mainAccount {
            _ = account.profile(on: DispatchQueue.global(qos: .userInitiated)).always {
                self.refreshControl?.endRefreshing()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.mainAccount = Account.main
        self.profile = self.mainAccount?.profile
        
        self.refreshControl?.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)

        NotificationCenter.default.addObserver(self, selector: #selector(mainChanged(_:)), name: .mainAccountChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(profileUpdated(_:)), name: .accountProfileUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(authorizationChanged(_:)), name: .accountAuthorizationChanged, object: nil)
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
        return (mainAccount == nil) ? 1 : 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case Section.mainAccount.rawValue:
            return 1
        case Section.sessions.rawValue:
            return sessions.count + 1
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case Section.sessions.rawValue:
            return NSLocalizedString("Online Devices", comment: "Header title of the sessions section of MeView.")
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case Section.mainAccount.rawValue:
            return (mainAccount == nil) ? 48 : 81
        case Section.sessions.rawValue:
            return 48
        default:
            return tableView.rowHeight
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == Section.mainAccount.rawValue {
            guard let account = mainAccount else {
                return tableView.dequeueReusableCell(withIdentifier: "noAccountsCell", for: indexPath)
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "mainAccountCell", for: indexPath) as! MainAccountCell
            
            // Configure the cell...
            let profile = account.profile
            
            cell.logo.image = account.configuration.logo
            cell.username.text = account.username
            cell.unauthorized = account.unauthorized
            cell.update(profile: profile, decimalUnits: account.configuration.decimalUnits)
        
            return cell
        } else {
            if indexPath.row < sessions.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: "sessionCell", for: indexPath) as! SessionCell
                
                cell.update(session: sessions[indexPath.row], decimalUnits: mainAccount?.configuration.decimalUnits ?? false)
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "loginIpCell", for: indexPath) as! LoginIpCell
                
                cell.label.textColor = canLoginIp ? cell.tintColor : UIColor.darkGray
                
                return cell
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == Section.sessions.rawValue {
            
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == Section.sessions.rawValue {
            return indexPath.row < sessions.count
        } else {
            return false
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return NSLocalizedString("Logout", comment: "Title for delete confirmation button for sessions.")
    }
 
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let session = sessions[indexPath.row]
            _ = mainAccount?.logoutSession(session: session, on: DispatchQueue.global(qos: .userInitiated))
        }
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
