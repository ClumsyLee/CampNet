//
//  ConfigurationSetupViewController.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/13.
//  Copyright © 2019年 Sihan Li. All rights reserved.
//

import UIKit
import CampNetKit

class ConfigurationSetupViewController: UITableViewController {

    @IBOutlet fileprivate var usernameField: UITextField!
    @IBOutlet var accountExistedLabel: UILabel!
    @IBOutlet fileprivate var passwordField: UITextField!
    @IBOutlet fileprivate var doneButton: UIBarButtonItem!

    var configurationIdentifier: String!
    var configurationDisplayName: String!
    var existedUsernames: Set<String>!

    var firstAppear: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        clearStates()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if firstAppear {
            navigationItem.title = configurationDisplayName
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if firstAppear {
            usernameField.becomeFirstResponder()
            firstAppear = false
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        clearStates()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func clearStates() {
        usernameField.text = ""
        accountExistedLabel.isHidden = true
        passwordField.text = ""
        doneButton.isEnabled = false

        firstAppear = true
    }

    // MARK: - Table view data source

    /*
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
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

    // MARK: - Navigation

    @IBAction func doneButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "accountAdded", sender: self)
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.

        // Resign first responder no matter what.
        view.endEditing(true)

        if segue.identifier == "accountAdded" {
            if let username = usernameField.text {
                Account.add(configurationIdentifier: configurationIdentifier, username: username,
                            password: passwordField.text ?? "")
            }
        }
    }

    // MARK: - UITextField

    @IBAction func usernameChanged(_ sender: Any) {
        let username = usernameField.text ?? ""
        let notExisted = !existedUsernames.contains(username)
        doneButton.isEnabled = !username.isEmpty && notExisted
        accountExistedLabel.isHidden = notExisted
    }

    @IBAction func usernameEntered(_ sender: Any) {
        if !existedUsernames.contains(usernameField.text ?? "") {
            passwordField.becomeFirstResponder()
        }
    }

    @IBAction func passwordEntered(_ sender: Any) {
        if doneButton.isEnabled {
            performSegue(withIdentifier: "accountAdded", sender: self)
        }
    }
}
