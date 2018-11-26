//
//  AccountDetailViewController.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/29.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import UIKit
import CampNetKit

class AccountDetailViewController: UITableViewController {

    enum Section: Int {
        case profile
        case changePassword
        case deleteAccount
    }

    @IBOutlet var name: UILabel!
    @IBOutlet var billingGroup: UILabel!
    @IBOutlet var balance: UILabel!
    @IBOutlet var usage: UILabel!

    @IBOutlet var deleteAccountRow: UITableViewCell!

    @IBAction func cancelChangingPassword(segue: UIStoryboardSegue) {}
    @IBAction func passwordChanged(segue: UIStoryboardSegue) {
        _ = account.update(on: DispatchQueue.global(qos: .userInitiated))
    }

    @IBAction func refreshTable(_ sender: Any) {
        account.profile(on: DispatchQueue.global(qos: .userInitiated)).ensure {
            self.refreshControl?.endRefreshing()
        }
    }

    var account: Account!

    func reloadProfile() {
        let profile = account.profile

        name.text = profile?.name?.nonEmpty ?? " "
        billingGroup.text = account.configuration.billingGroups[profile?.billingGroupName ?? ""]?.displayName?
            .nonEmpty ?? " "
        if let moneyString = profile?.balance?.moneyString {
            balance.text = "¥ \(moneyString)"
        } else {
            balance.text = " "
        }
        usage.text = profile?.usage?.usageString(decimalUnits: account.configuration.decimalUnits).nonEmpty ?? " "
    }

    func reload() {
        navigationItem.title = account.username

        reloadProfile()
    }

    @objc func profileUpdated(_ notification: Notification) {
        guard let account = notification.userInfo?["account"] as? Account, account == self.account else {
            return
        }

        reloadProfile()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        NotificationCenter.default.addObserver(self, selector: #selector(profileUpdated(_:)),
                                               name: .accountProfileUpdated, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if refreshControl!.isRefreshing {
            // See https://stackoverflow.com/questions/21758892/uirefreshcontrol-stops-spinning-after-making-application-inactive
            let offset = tableView.contentOffset
            refreshControl?.endRefreshing()
            refreshControl?.beginRefreshing()
            tableView.contentOffset = offset
        }

        reload()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    /*
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }
    */

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == Section.deleteAccount.rawValue {
            let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            menu.view.tintColor = #colorLiteral(red: 0.1934785199, green: 0.7344816453, blue: 0.9803921569, alpha: 1)

            let deleteAction = UIAlertAction(title: L10n.AccountDetail.DeleteAccountAlert.Actions.delete,
                                             style: .destructive) { action in
                Account.remove(self.account)
                self.performSegue(withIdentifier: "accountDeleted", sender: self)
            }
            let cancelAction = UIAlertAction(title: L10n.AccountDetail.DeleteAccountAlert.Actions.cancel,
                                             style: .cancel, handler: nil)

            menu.addAction(deleteAction)
            menu.addAction(cancelAction)

            // Show as a popover on iPads.
            if let popoverPresentationController = menu.popoverPresentationController {
                popoverPresentationController.sourceView = deleteAccountRow
                popoverPresentationController.sourceRect = deleteAccountRow.bounds
            }

            present(menu, animated: true, completion: nil)
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table
            //   view
        }
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.

        if segue.identifier == "changePassword" {
            let controller = (segue.destination as! UINavigationController)
                .topViewController as! ChangePasswordViewController

            controller.account = account
        }
    }

    // MARK: Cell Menu

    override func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == Section.profile.rawValue
    }

    override func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath,
                            withSender sender: Any?) -> Bool {
        if action == #selector(copy(_:)) {
            if let detail = tableView.cellForRow(at: indexPath)?.detailTextLabel?.text, detail != " " {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }

    override func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath,
                            withSender sender: Any?) {
        if action == #selector(copy(_:)) {
            let cell = tableView.cellForRow(at: indexPath)
            UIPasteboard.general.string = cell?.detailTextLabel?.text
        }
    }
}
