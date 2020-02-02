//
//  UIViewController+Errors.swift
//  SampleFeediOS
//
//  Created by Danny Sung on 02/01/2020.
//  Copyright © 2020 Sung Heroes. All rights reserved.
//

import UIKit

public extension UIViewController {
    func present(error: Error, completion: @escaping ()->Void = { }) {
        let alertVC = UIAlertController(title: "Error", message: "\(error.localizedDescription)", preferredStyle: .alert)
        
        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel) { (_) in
            completion()
        }
        
        alertVC.addAction(dismissAction)
        
        self.present(alertVC, animated: true)
    }
}
