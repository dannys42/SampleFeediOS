//
//  LoginViewController.swift
//  SampleFeediOS
//
//  Created by Danny Sung on 02/01/2020.
//  Copyright © 2020 Sung Heroes. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet var keyboardToolbar: UIToolbar!
    
    public var didLogin: ()->Void = { }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.usernameTextField.inputAccessoryView = self.keyboardToolbar
        self.passwordTextField.inputAccessoryView = self.keyboardToolbar
    }
    
    @IBAction func loginDidPress(_ sender: UIButton) {
        self.login()
    }
    
    @IBAction func textDoneDidPress(_ sender: UIBarButtonItem) {
        self.usernameTextField.resignFirstResponder()
        self.passwordTextField.resignFirstResponder()
    }
    
    // MARK: - Convenience Functions
    fileprivate func login() {
        
//        self.performSegue(withIdentifier: "loginSegue", sender: self)
        self.didLogin()
    }
}

// MARK: - UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.usernameTextField {
            self.passwordTextField.becomeFirstResponder()
        } else if textField == self.passwordTextField {
            textField.resignFirstResponder()
            self.login()
        }
        
        return true
    }
}
