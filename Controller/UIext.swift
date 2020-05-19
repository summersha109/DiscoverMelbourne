//
//  UIext.swift
//  DiscoverMelb
//
//  Created by 朱莎 on 5/9/19.
//  Copyright © 2019 Monash University. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController{
    
    func displayMessage(title: String, message: String) {
        // Setup an alert to show user details about the Person
        // UIAlertController manages an alert instance
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertAction.Style.default,handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    
   
    
}
