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
        
        self.loadDefaults()
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
        guard let username = self.usernameTextField.text,
            let password = self.passwordTextField.text else {
                // Do nothing if attmept to login with no username/password
                return
        }
        FeedController.shared.login(username: username, password: password) { error in
            
            DispatchQueue.main.async {
                self.saveDefaults()
            }
            if let error = error {
                DispatchQueue.main.async {
                    self.present(error: error)
                }
                return
            }
            
            self.didLogin()
        }
    }
    
    // FIXME: Convenience during development.  Remove these in production.
    enum DefaultsKey: String {
        case username
        case password
    }
    fileprivate func loadDefaults() {
        let store = UserDefaults.standard
        
        self.usernameTextField.text = store.string(forKey: DefaultsKey.username.rawValue)
        self.passwordTextField.text = store.string(forKey: DefaultsKey.password.rawValue)
    }
    fileprivate func saveDefaults() {
        let store = UserDefaults.standard

        if let text = self.usernameTextField.text {
            store.set(text, forKey: DefaultsKey.username.rawValue)
        } else {
            store.removeObject(forKey: DefaultsKey.username.rawValue)
        }
        if let text = self.passwordTextField.text {
            store.set(text, forKey: DefaultsKey.password.rawValue)
        } else {
            store.removeObject(forKey: DefaultsKey.password.rawValue)
        }
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
