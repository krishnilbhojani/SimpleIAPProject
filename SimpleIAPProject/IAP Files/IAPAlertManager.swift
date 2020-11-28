//
//  IAPAlertManager.swift
//  SimpleIAPProject
//
//  Created by Krishnil Bhojani on 7/18/20.

import Foundation
import UIKit
import SwiftyStoreKit
import SVProgressHUD

enum AlertCase {
    case getInfo
    case purchase
    case none
}

protocol IAPAlertManagerDelegate{
    func didOkPressed(alertCase: AlertCase)
}

class IAPAlertManager{
    
    static let shared = IAPAlertManager()
    var delegate: IAPAlertManagerDelegate?
    
    private init(){
        SVProgressHUD.setDefaultMaskType(.black)
    }
    
    //Show Progress HUD
    func showProgressAlert(){
        DispatchQueue.main.async {
            SVProgressHUD.show()
        }
    }
    
    func dismissProgressAlert(){
        DispatchQueue.main.async {
            SVProgressHUD.dismiss()
        }
    }
    
    // Setup UIAlertController with title and returns instance
    func alertWithTitle(title : String, message : String, alertCase: AlertCase! = .none) -> UIAlertController {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if alertCase == .none {
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        }
        else if alertCase == .getInfo{
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Purchase / Restore", style: .destructive, handler: { (action) in
                if self.delegate != nil {
                    self.delegate!.didOkPressed(alertCase: alertCase)
                }
            }))
        }
        else if alertCase == .purchase{
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                if self.delegate != nil {
                    self.delegate!.didOkPressed(alertCase: .purchase)
                }
            }))
        }
        
        return alert
    }
    
    // Present Alert on ViewController
    func showAlert(alert : UIAlertController) {
        guard let vc = (UIApplication.shared.delegate as? AppDelegate)?.getTopMostViewController() else { return }
        vc.present(alert, animated: true, completion: nil)
    }
    
    // Alert for Get Info
    func alertForProductRetrievalInfo(result : RetrieveResults) {
        
        var alertVC : UIAlertController!
        
        if let product = result.retrievedProducts.first {
            let priceString = product.localizedPrice!
            alertVC = alertWithTitle(title: product.localizedTitle, message: "\(product.localizedDescription) - \(priceString)", alertCase: .getInfo)
        }
        else if let invalidProductID = result.invalidProductIDs.first {
            alertVC = alertWithTitle(title: "Could not retreive products info", message: "Invalid identifier: \(invalidProductID)")
        }
        else {
            let errorString = result.error?.localizedDescription ?? "Unknown Error. Please Contact Support"
            alertVC =  alertWithTitle(title: "Could not retreive product info" , message: errorString)
        }
        
        self.showAlert(alert: alertVC)
    }
    
    // Alert for Purchase Product
    func alertForPurchaseResult(result : PurchaseResult) {
        
        var alertVC : UIAlertController!
        
        switch result {
        case .success(let product):
            print("Purchase Succesful: \(product.productId)")
            alertVC = alertWithTitle(title: "Thank You", message: "Purchase completed",alertCase: .purchase)
        
        case .error(let error):
            print("Purchase Failed: \(error)")
            
            switch error.code {
            case .cloudServiceNetworkConnectionFailed:
                alertVC = alertWithTitle(title: "Purchase Failed", message: "Check your internet connection or try again later.")
            
            case .cloudServicePermissionDenied:
                alertVC = alertWithTitle(title: "Purchase Failed", message: "Access to cloud service information is not allowed")
                
            case .cloudServiceRevoked:
                alertVC = alertWithTitle(title: "Purchase Failed", message: "Permission to use this cloud service is revoked")
                
            case .storeProductNotAvailable:
                alertVC = alertWithTitle(title: "Purchase Failed", message: "Product not found")
            
            case .paymentNotAllowed , .clientInvalid:
                alertVC = alertWithTitle(title: "Purchase Failed", message: "You are not allowed to make payments")
            
            case.paymentCancelled:
                alertVC = alertWithTitle(title: "Purchase Failed", message: "Payment is canceled")
                
            default:
                alertVC = alertWithTitle(title: "Purchase Failed", message: "Please contact support")
            }
        }
        
        showAlert(alert: alertVC)
    }
    
    // Alert for Restore Purchases
    func alertForRestorePurchases(result : RestoreResults) {
        var alertVC : UIAlertController!
        if result.restoreFailedPurchases.count > 0 {
            print("Restore Failed: \(result.restoreFailedPurchases)")
            alertVC = alertWithTitle(title: "Restore Failed", message: "Unknown Error. Please Contact Support")
        }
        else if result.restoredPurchases.count > 0 {
            alertVC = alertWithTitle(title: "Purchases Restored", message: "All purchases have been restored.")
        }
        else {
            alertVC = alertWithTitle(title: "Nothing To Restore", message: "No previous purchases were made.")
        }
        
        showAlert(alert: alertVC)
    }
    
    // Alert for Verify Purchase
    func alertForVerifyPurchase(result : VerifyPurchaseResult) {
        var alertVC : UIAlertController!
        switch result {
        case .purchased:
            alertVC = alertWithTitle(title: "Product is Purchased", message: "")
        case .notPurchased:
            alertVC = alertWithTitle(title: "Product not purchased", message: "Product depleted/not purchased")
        }
        showAlert(alert: alertVC)
    }
    
    // Alert for Verify Subscriptions
    func alertForVerifySubscriptions(result : VerifySubscriptionResult) {
        var alertVC : UIAlertController!
        switch result {
        case .purchased(expiryDate: _, items: _):
            alertVC = alertWithTitle(title: "Subscription is Purchased", message: "")
        case .notPurchased:
            alertVC = alertWithTitle(title: "Subsctiption not purchased", message: "Subsctiption not purchased")
        case .expired(_, _):
            alertVC = alertWithTitle(title: "Subsctiption has been expired", message: "Subsctiption has been expired")
        }
        self.showAlert(alert: alertVC)
    }
    
}
