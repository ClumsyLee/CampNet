//
//  ConfigurationsViewController.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 2017/7/13.
//  Copyright © 2019年 Sihan Li. All rights reserved.
//

import UIKit
import SafariServices

import Firebase

import CampNetKit

class ConfigurationsViewController: UITableViewController, UISearchResultsUpdating {

    static let repoUrl = URL(string: "https://github.com/ClumsyLee/CampNet-Configurations")!

    var searchController: UISearchController!

    var names: [(identifier: String, name: String, domain: String)] = []
    var searchResults: [(identifier: String, name: String, domain: String)] = []

    var githubRow: Int {
        return searchController.isActive ? searchResults.count : names.count
    }

    // Without it, the status bar will go dark when using searchbar.
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    func filter(for searchText: String) {
        searchResults = names.filter { (identifier, name, domain) -> Bool in
            return identifier.localizedCaseInsensitiveContains(searchText) ||
                   name.localizedCaseInsensitiveContains(searchText) ||
                   domain.localizedCaseInsensitiveContains(searchText)
        }
    }

    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            filter(for: searchText)
            tableView.reloadData()

            Analytics.logEvent(AnalyticsEventSearch, parameters: [
                AnalyticsParameterSearchTerm: searchText])
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        self.searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        if #available(iOS 9.1, *) {
            searchController.obscuresBackgroundDuringPresentation = false
        } else {
            // Fallback on earlier versions
            searchController.dimsBackgroundDuringPresentation = false
        }
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            // Set text colors to white.
            searchController.searchBar.tintColor = .white
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes =
                convertToNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.white])
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
        self.definesPresentationContext = true  // For navigation bar.

        self.names = Configuration.displayNames.map {
            (identifier: $0.key, name: $0.value, domain: $0.key.reverseDomained)
        }
        .sorted { $0.name < $1.name || ($0.name == $1.name && $0.identifier < $1.identifier) }
    }

    deinit {
        searchController.view.removeFromSuperview()  // A bug in iOS 9. See https://stackoverflow.com/questions/32282401/attempting-to-load-the-view-of-a-view-controller-while-it-is-deallocating-uis
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return githubRow + 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == githubRow {
            return tableView.dequeueReusableCell(withIdentifier: "githubCell", for: indexPath)
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "configurationCell",
                                                     for: indexPath) as! ConfigurationCell

            // Configure the cell...
            let (identifier, name, domain) = searchController.isActive ? searchResults[indexPath.row]
                                                                       : names[indexPath.row]
            cell.logo.image = UIImage(named: identifier)
            cell.name.text = name
            cell.domain.text = domain

            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == githubRow {
            let controller = SFSafariViewController(url: ConfigurationsViewController.repoUrl)
            present(controller, animated: true)
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

        if segue.identifier == "showConfigurationSetup" {
            let indexPath = tableView.indexPathForSelectedRow!
            let (configurationIdentifier, name, _) = searchController.isActive ? searchResults[indexPath.row]
                                                                               : names[indexPath.row]

            Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
                AnalyticsParameterItemID: configurationIdentifier,
                AnalyticsParameterContentType: "new_account"])

            var existedUsernames: Set<String> = []
            for (configuration, accountArray) in Account.all {
                if configuration.identifier == configurationIdentifier {
                    existedUsernames.formUnion(accountArray.map{ $0.username })
                    break
                }
            }

            let controller = segue.destination as! ConfigurationSetupViewController
            controller.configurationIdentifier = configurationIdentifier
            controller.configurationDisplayName = name
            controller.existedUsernames = existedUsernames
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSAttributedStringKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.Key: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
