//
//  CustomConfigurationViewController.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 1/22/19.
//  Copyright © 2019 Sihan Li. All rights reserved.
//

import UIKit
import CampNetKit

class CustomConfigurationViewController: UITableViewController {

    @IBOutlet var cancelButton: UIBarButtonItem!
    @IBOutlet var saveButton: UIBarButtonItem!
    var activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
    var saveActivityButton: UIBarButtonItem!
    @IBOutlet var configurationUrl: UITextField!

    var firstAppear: Bool = true

    @IBAction func saveButtonPressed(_ sender: Any) {
        let urlString = configurationUrl.text ?? ""

        // Remove the custom configuration if empty.
        if urlString.isEmpty {
            removeCustomConfiguration()
            self.performSegue(withIdentifier: "customConfigurationRemoved", sender: self)
            return
        }

        // Otherwise, load the new custom configuration.
        guard let url = URL(string: urlString) else {
            return
        }

        showSaveActivityButton()
        activityIndicator.startAnimating()
        Action.changeNetworkActivityCount(1)
        configurationUrl.isEnabled = false

        _ = URLSession.shared.dataTask(.promise, with: URLRequest(url: url)).compactMap(String.init).done { string in
            guard let configuration = Configuration(identifier: Configuration.customIdentifier, string: string) else {
                showErrorBanner(title: L10n.Notifications.LoadConfiguration.ParseError.title)
                self.clearStates()
                self.configurationUrl.becomeFirstResponder()
                return
            }

            // Valid configuration, save it and reload custom accounts.
            self.saveCustomConfiguration(url: url.description, string: string, configuration: configuration)
            self.performSegue(withIdentifier: "customConfigurationLoaded", sender: self)
        }.ensure {
            self.activityIndicator.stopAnimating()
            Action.changeNetworkActivityCount(-1)
        }.catch { err in
            showErrorBanner(title: L10n.Notifications.LoadConfiguration.FetchError.title,
                            body: err.localizedDescription)
            self.clearStates()
            self.configurationUrl.becomeFirstResponder()
        }
    }

    func removeCustomConfiguration() {
        Defaults[.customConfiguration] = ""
        Defaults[.customConfigurationUrl] = ""

        for (configuration, accounts) in Account.all {
            guard configuration.identifier == Configuration.customIdentifier else {
                continue
            }

            for account in accounts {
                Account.remove(account)
            }
            break
        }
    }

    func saveCustomConfiguration(url: String, string: String, configuration: Configuration) {
        Defaults[.customConfiguration] = string
        Defaults[.customConfigurationUrl] = url

        let oldAccounts = Account.all[configuration] ?? []
        let oldMain = Account.main
        // Remove all the accounts first to make sure the old configuration is released.
        for account in oldAccounts {
            Account.remove(account)
        }
        // Add them back.
        for account in oldAccounts {
            Account.add(configurationIdentifier: configuration.identifier, username: account.username, password: account.password)
        }
        // Recover main if needed.
        for account in Account.all[configuration] ?? [] {
            if account == oldMain {
                Account.makeMain(account)
                break
            }
        }
    }

    @IBAction func configurationUrlChanged(_ sender: Any) {
        let urlString = configurationUrl.text ?? ""
        saveButton.isEnabled = urlString.isEmpty || URL(string: urlString) != nil
    }

    @IBAction func configurationUrlEntered(_ sender: Any) {
        saveButtonPressed(sender)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        saveActivityButton = UIBarButtonItem.init(customView: activityIndicator)
        clearStates()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if firstAppear {
            configurationUrl.text = Defaults[.customConfigurationUrl]
            configurationUrlChanged(self)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if firstAppear {
            configurationUrl.becomeFirstResponder()
            firstAppear = false
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        clearStates()
    }

    func clearStates() {
        showSaveButton()
        configurationUrl.isEnabled = true
    }

    func showSaveButton() {
        navigationItem.setLeftBarButton(cancelButton, animated: true)
        navigationItem.setRightBarButton(saveButton, animated: true)
    }

    func showSaveActivityButton() {
        navigationItem.setLeftBarButton(nil, animated: true)
        navigationItem.setRightBarButton(saveActivityButton, animated: true)
    }

    // MARK: - Table view data source

//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }

//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return 0
//    }

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
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
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
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.

        // Resign first responder no matter what.
        view.endEditing(true)
    }

}
