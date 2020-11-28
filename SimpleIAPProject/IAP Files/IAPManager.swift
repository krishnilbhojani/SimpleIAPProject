//
//  IAPManager.swift
//  SimpleIAPProject
//
//  Created by Krishnil Bhojani on 7/18/20.

import Foundation
import SwiftyStoreKit

enum IAPConstants: String{
    case hasPurchaseVisitPlan = "hasPurchasedVisitPlan"
    case hasPurchasedAdvancePlan = "hasPurchasedAdvancePlan"
}

// These are the products added on Apple Itunes Connect
enum RegisteredProduct: String{
    case one_session = "MeetingSessionQTY1"
    case three_session = "MeetingSessionQTY2"
}

class IAPManager {
    
    static let shared = IAPManager()
    
    //Secret Key from Apple Itunes Connect Account
    private let sharedSecretKey: String = ""
    
    let bundledId: String = Bundle.main.bundleIdentifier ?? ""
    
    private init() {
        SwiftyStoreKit.shouldAddStorePaymentHandler = { (payment, product) in
            /**
             * Return true to continue the transaction in your app.
             * Return false to defer or cancel the transaction.
             **/
            return false
        }
    }

    func completeTransaction(){
        
        SwiftyStoreKit.completeTransactions(atomically: false){ purchases in
            
            for purchase in purchases {
                
                switch purchase.transaction.transactionState {
                    
                case .purchased:
                    if purchase.needsFinishTransaction{
                        // Deliver content from server, then:
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    print("IN APP PURCHASE STATUS : purchased")
                    break
                case .purchasing:
                    print("IN APP PURCHASE STATUS : purchasing")
                    break
                case .deferred:
                    print("IN APP PURCHASE STATUS : deferred")
                    break
                case .failed:
                    print("IN APP PURCHASE STATUS : failed")
                    break
                case .restored:
                    if purchase.needsFinishTransaction{
                        // Deliver content from server, then:
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    print("IN APP PURCHASE STATUS : restored")
                    break
                }
                
            }
        }
        
    }
    
    //MARK:- Get Product Info
    func fetchProducts(completion: @escaping (RetrieveResults) -> Void){
        
        IAPAlertManager.shared.showProgressAlert()
        
        let products: Set<String> = [RegisteredProduct.one_session.rawValue,
                                     RegisteredProduct.three_session.rawValue]
        
        SwiftyStoreKit.retrieveProductsInfo(products) { (results) in
            
            IAPAlertManager.shared.dismissProgressAlert()
            
            DispatchQueue.main.async {
                //IAPAlertManager.shared.alertForProductRetrievalInfo(result: results)
                completion(results)
            }
        }
    }
    
    //MARK:- Purchase Product
    func purchaseProduct(product: RegisteredProduct, successCompletion: @escaping () -> Void ){

        IAPAlertManager.shared.showProgressAlert()
        
        SwiftyStoreKit.purchaseProduct(product.rawValue) { (results) in
            
            IAPAlertManager.shared.dismissProgressAlert()
            
            if case .success(let product) = results {
                if product.needsFinishTransaction {
                    //Server request to save state ....
                    SwiftyStoreKit.finishTransaction(product.transaction)
                }
                // Perform Relevant Action
                successCompletion()
            }
            IAPAlertManager.shared.alertForPurchaseResult(result: results)
        }
    }
    
    //MARK:- Restore Products/Subscription
    /**
    *  This is only reqiured for Non-Consumable and Auto-Renewable Subscription products
    */
    func restorePurchases(product: RegisteredProduct, completion: @escaping (RestoreResults) -> Void){
        
        IAPAlertManager.shared.showProgressAlert()
        
        SwiftyStoreKit.restorePurchases(atomically: true) { (results) in
        
            IAPAlertManager.shared.dismissProgressAlert()
            
            for product in results.restoredPurchases {
                if product.needsFinishTransaction {
            
                    //Server request to save state ....
                    //For non-atomically
                    SwiftyStoreKit.finishTransaction(product.transaction)
                }
            }
            
            if !results.restoredPurchases.isEmpty{
                // Perform Relevant Action
                completion(results)
            }
            
            IAPAlertManager.shared.alertForRestorePurchases(result: results)
        }
    }
    
    //MARK:- Verify Purchase
    //Refresh the encrypted receipt and perform validation
    func verifyPurchasWithRecieptRefresh(forceRefresh: Bool){

        IAPAlertManager.shared.showProgressAlert()
        
        let appleValidator = AppleReceiptValidator(service: .sandbox, sharedSecret: sharedSecretKey)
        SwiftyStoreKit.verifyReceipt(using: appleValidator, forceRefresh: forceRefresh) { result in
            
            IAPAlertManager.shared.dismissProgressAlert()
            
            switch result {
            case .success(let receipt):
                
                DispatchQueue.main.async {
                    /// Verify the purchase of products
                    //self.verifyPurchase(product: .consumable01, receiptInfo: receipt)
                    
                    /// Verify the purchase of subscription
                    //self.verifySubscription(product: .subscription, receiptInfo: receipt)
                }
                
            case .error(let error):
                print("Receipt verification failed: \(error)")
            }
        }
    }
    
    //MARK:- Verify Purchase from Receipt
    //(either Purchase or notPurchased)
    func verifyPurchase(product: RegisteredProduct, receiptInfo: ReceiptInfo){
        let result = SwiftyStoreKit.verifyPurchase(productId:product.rawValue, inReceipt: receiptInfo)
        
        switch result {
        case .purchased(let receiptItem):
            print("\(product.rawValue) is purchased: \(receiptItem)")
        case .notPurchased:
            print("The user has never purchased \(product.rawValue)")
        }
        
        IAPAlertManager.shared.alertForVerifyPurchase(result: result)
    }
    
    //MARK:- Verify Subscription from Receipt
    //(either Purchase or notPurchased)
    func verifySubscription(product: RegisteredProduct, receiptInfo: ReceiptInfo){
        
        // validDuration: time interval in seconds
        let purchaseResult = SwiftyStoreKit.verifySubscription(
            ofType: .nonRenewing(validDuration: 3600 * 24 * 30),
            productId: "\(product.rawValue)",
            inReceipt: receiptInfo)
        
        switch purchaseResult {
        case .purchased(let expiryDate, let items):
            print("\(product.rawValue) is valid until \(expiryDate)\n\(items)\n")
        case .expired(let expiryDate, let items):
            print("\(product.rawValue) is expired since \(expiryDate)\n\(items)\n")
        case .notPurchased:
            print("The user has never purchased \(product.rawValue)")
        }
        IAPAlertManager.shared.alertForVerifySubscriptions(result: purchaseResult)
    }
    
}
