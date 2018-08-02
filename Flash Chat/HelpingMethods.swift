//
//  HelpingMethods.swift
//  Flash Chat
//
//  Created by Adel on 7/25/18.
//  Copyright © 2018 London App Brewery. All rights reserved.
//

import Foundation
import UIKit

class HelpingMethods {
    
    class func showAlert(title: String, message: String,action:UIAlertAction,actionName:String)-> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title:actionName, style: .default, handler: nil)
        alertController.addAction(okAction)
        alertController.addAction(action)
        return alertController
    }
}
