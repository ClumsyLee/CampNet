//
//  SettingsViewController.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/27.
//  Copyright © 2019年 Sihan Li. All rights reserved.
//

import UIKit
import Firebase
import CampNetKit

class SettingsViewController: UITableViewController {

    @IBOutlet var autoLoginSwitch: UISwitch!
    @IBOutlet var autoLogoutExpiredSessionsSwitch: UISwitch!
    @IBOutlet var usageAlertPercentage: UILabel!
    @IBOutlet var supportUs: UILabel!

    @IBAction func autoLoginChanged(_ sender: Any) {
        Defaults[.autoLogin] = autoLoginSwitch.isOn
        Analytics.setUserProperty(Defaults[.autoLogin].description, forName: "auto_login")
    }
    @IBAction func autoLogoutExpiredSessionsChanged(_ sender: Any) {
        Defaults[.autoLogoutExpiredSessions] = autoLogoutExpiredSessionsSwitch.isOn
        Analytics.setUserProperty(Defaults[.autoLogoutExpiredSessions].description, forName: "auto_logout_expired_sess")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)

        autoLoginSwitch.isOn = Defaults[.autoLogin]
        autoLogoutExpiredSessionsSwitch.isOn = Defaults[.autoLogoutExpiredSessions]
        if let ratio = Defaults[.usageAlertRatio] {
            usageAlertPercentage.text = "\(Int(ratio * 100))%"
        } else {
            usageAlertPercentage.text = L10n.Settings.UsageAlert.Values.off
        }

        if Defaults.potentialDonator {
            supportUs.textColor = #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1)
            supportUs.font = UIFont.systemFont(ofSize: supportUs.font.pointSize, weight: .semibold)
        } else {
            supportUs.textColor = .darkText
            supportUs.font = UIFont.systemFont(ofSize: supportUs.font.pointSize)
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

//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//    }

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
