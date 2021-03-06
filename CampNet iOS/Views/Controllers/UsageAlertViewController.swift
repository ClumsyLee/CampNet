//
//  UsageAlertViewController.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/27.
//  Copyright © 2019年 Sihan Li. All rights reserved.
//

import UIKit
import Firebase
import CampNetKit

class UsageAlertViewController: UITableViewController {
    static let ratios = [nil, 0.95, 0.90, 0.80, 0.70]

    var selectedRow: Int?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        let ratio = Defaults[.usageAlertRatio]
        self.selectedRow = UsageAlertViewController.ratios.firstIndex { $0 == ratio }
    }

    override func viewDidLayoutSubviews() {
        if let row = selectedRow {
            tableView.cellForRow(at: IndexPath(row: row, section: 0))?.accessoryType = .checkmark
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

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == selectedRow {
            return
        }

        if let row = selectedRow {
            tableView.cellForRow(at: IndexPath(row: row, section: 0))?.accessoryType = .none
        }
        selectedRow = indexPath.row

        Defaults[.usageAlertRatio] = UsageAlertViewController.ratios[indexPath.row]
        Analytics.setUserProperty(Defaults[.usageAlertRatio]?.description ?? "off", forName: "usage_alert_ratio")

        tableView.cellForRow(at: IndexPath(row: indexPath.row, section: 0))?.accessoryType = .checkmark
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

}
