//
//  SessionDetailViewController.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/30.
//  Copyright © 2017年 Sihan Li. All rights reserved.
//

import UIKit

import SwiftRater
import CampNetKit

class SessionDetailViewController: UITableViewController {

    enum Section: Int {
        case details
        case logoutSession
    }

    @IBOutlet var ip: UILabel!
    @IBOutlet var id: UILabel!
    @IBOutlet var startTime: UILabel!
    @IBOutlet var usage: UILabel!
    @IBOutlet var mac: UILabel!

    @IBOutlet var logoutDeviceRow: UITableViewCell!

    var account: Account!
    var session: Session!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.title = session.device

        ip.text = session.ip.nonEmpty ?? " "
        id.text = session.id?.nonEmpty ?? " "
        if let startTime = session.startTime {
            self.startTime.text = DateFormatter.localizedString(from: startTime, dateStyle: .medium, timeStyle: .short)
        } else {
            self.startTime.text = " "
        }
        usage.text = session.usage?.usageString(decimalUnits: account.configuration.decimalUnits).nonEmpty ?? " "
        mac.text = session.mac?.nonEmpty ?? " "
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

        if indexPath.section == Section.logoutSession.rawValue {
            let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            menu.view.tintColor = #colorLiteral(red: 0.1934785199, green: 0.7344816453, blue: 0.9803921569, alpha: 1)

            let deleteAction = UIAlertAction(title: L10n.SessionDetail.LogoutAlert.Actions.logout,
                                             style: .destructive) { action in
                _ = self.account.logoutSession(session: self.session).done { _ in
                    SwiftRater.incrementSignificantUsageCount()
                }
                self.performSegue(withIdentifier: "sessionLoggedOut", sender: self)
            }
            let cancelAction = UIAlertAction(title: L10n.SessionDetail.LogoutAlert.Actions.cancel, style: .cancel,
                                             handler: nil)

            menu.addAction(deleteAction)
            menu.addAction(cancelAction)

            // Show as a popover on iPads.
            if let popoverPresentationController = menu.popoverPresentationController {
                popoverPresentationController.sourceView = logoutDeviceRow
                popoverPresentationController.sourceRect = logoutDeviceRow.bounds
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: Cell Menu

    override func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == Section.details.rawValue
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
