//
//  NetworkViewController.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/8/5.
//  Copyright © 2019年 Sihan Li. All rights reserved.
//

import UIKit
import NetworkExtension

import Firebase

import CampNetKit

class NetworkViewController: UITableViewController {

    enum Section: Int {
        case details
        case onCampus
    }

    @IBOutlet var ipLabel: UILabel!
    @IBOutlet var bssid: UILabel!
    @IBOutlet var signalStrength: UILabel!

    @IBOutlet var onCampusSwitch: UISwitch!

    var account: Account?
    var network: NEHotspotNetwork!
    var ip: String!

    @IBAction func onCampusChanged(_ sender: Any) {
        guard let configuration = account?.configuration, !configuration.ssids.contains(network.ssid) else {
            return
        }

        Defaults[.onCampus(id: configuration.identifier, ssid: network.ssid)] = onCampusSwitch.isOn
        Analytics.logEvent(onCampusSwitch.isOn ? "remember_network" : "forget_network",
                           parameters: ["network": network.ssid])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.title = network.ssid

        ipLabel.text = ip.nonEmpty ?? " "
        bssid.text = network.bssid.nonEmpty ?? " "
        signalStrength.text = "\(Int(network.signalStrength * 100))%"

        if let configuration = account?.configuration {
            if configuration.ssids.contains(network.ssid) {
                onCampusSwitch.isOn = true
                onCampusSwitch.isEnabled = false
            } else {
                onCampusSwitch.isOn = Defaults[.onCampus(id: configuration.identifier, ssid: network.ssid)]
                onCampusSwitch.isEnabled = true
            }
        } else {
            onCampusSwitch.isOn = false
            onCampusSwitch.isEnabled = false
        }
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

            Analytics.logEvent("network_detail_copy", parameters: ["index": indexPath.row])
        }
    }
}
