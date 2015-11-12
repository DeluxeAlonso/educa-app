//
//  PaymentService.swift
//  EducaApp
//
//  Created by Alonso on 11/6/15.
//  Copyright © 2015 Alonso. All rights reserved.
//

import UIKit

let PaymentPath = "payment_calendar"
let RegisterPaymentPath = "payment"

class PaymentService: NSObject {
  
  class func fetchPayments(completion: (responseObject: NSObject?, error: NSError?) -> Void) {
    NetworkManager.sharedInstance.requestSerializer.setValue(User.getAuthToken(), forHTTPHeaderField: Constants.Api.Header)
    NetworkManager.sharedInstance.GET(UrlBuilder.UrlForApiaryPath(PaymentPath), parameters: nil, success: { (operation: AFHTTPRequestOperation, responseObject: AnyObject?) in
      completion(responseObject: responseObject! as? NSObject, error: nil)
      }, failure: {(operation: AFHTTPRequestOperation, error: NSError) in
        completion(responseObject: nil, error: error)
    })
  }
  
  class func registerPayment(feeId: String, voucherCode: String, date: Double, completion: (responseObject: NSObject?, error: NSError?) -> Void) {
    let parameters = ["fee_id": feeId, "voucher_code": voucherCode , "date": date]
      NetworkManager.sharedInstance.requestSerializer.setValue(User.getAuthToken(), forHTTPHeaderField: Constants.Api.Header)
      NetworkManager.sharedInstance.POST(UrlBuilder.UrlForApiaryPath(RegisterPaymentPath), parameters: parameters, success: { (operation: AFHTTPRequestOperation, responseObject: AnyObject?) in
      completion(responseObject: responseObject! as? NSObject, error: nil)
      }, failure: {( operation: AFHTTPRequestOperation, error: NSError) in
      completion(responseObject: nil, error: error)
      })
  }


}
