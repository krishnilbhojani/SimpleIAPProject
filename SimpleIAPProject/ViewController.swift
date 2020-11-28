//
//  ViewController.swift
//  SimpleIAPProject
//
//  Created by Krishnil Bhojani on 29/11/20.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func buy1SessionButtonPressed(_ sender: UIButton) {
        IAPManager.shared.purchaseProduct(product: .one_session) {
            print("Success - 1 session")
        }
    }
    
    @IBAction func buy2SessionButtonPressed(_ sender: UIButton) {
        IAPManager.shared.purchaseProduct(product: .one_session) {
            print("Success - 1 session")
        }
    }
    
}

