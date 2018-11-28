//
//  SupportUsViewController.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 11/28/18.
//  Copyright © 2018 Sihan Li. All rights reserved.
//

import UIKit
import SwiftRater
import SwiftyButton

class SupportUsViewController: UIViewController {

    @IBOutlet var donateButton: PressableButton!
    @IBOutlet var rateButton: PressableButton!

    @IBAction func rateButtonPressed(_ sender: Any) {
        SwiftRater.rateApp()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        donateButton.colors = .init(button: #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1), shadow: #colorLiteral(red: 0.78, green: 0.4101724125, blue: 0.5513793254, alpha: 1))
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
