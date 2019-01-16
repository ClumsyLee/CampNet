//
//  CustomConfigurationController.swift
//  CampNet iOS
//
//  Created by Thomas Lee on 1/16/19.
//  Copyright © 2019 Sihan Li. All rights reserved.
//

import UIKit

import BRYXBanner
import CampNetKit

class CustomConfigurationController: UIViewController {

    @IBOutlet var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textView.text = Defaults[.customConfiguration]
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Defaults[.customConfiguration] = textView.text
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
