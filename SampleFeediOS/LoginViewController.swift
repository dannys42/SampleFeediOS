//
//  LoginViewController.swift
//  SampleFeediOS
//
//  Created by Danny Sung on 02/01/2020.
//  Copyright © 2020 Sung Heroes. All rights reserved.
//

import UIKit
import MBProgressHUD

class LoginViewController: UIViewController {
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet var keyboardToolbar: UIToolbar!
    @IBOutlet weak var serverButton: UIButton!
    
    public var customServerEnabled: Bool = false {
        didSet {
            if customServerEnabled != oldValue {
                DispatchQueue.main.async {
                    self.updateServerButton()
                }
            }
        }
    }
    public var customServer: String?
    
    public var didLogin: ()->Void = {  }
    
    private var serverUrl: URL {
        let productionUrl = FeedController.productionUrl
        guard !customServerEnabled,
            let customServer = self.customServer,
            let customServerUrl = URL(string: customServer) else {
                return productionUrl
        }
        return customServerUrl
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.usernameTextField.inputAccessoryView = self.keyboardToolbar
        self.passwordTextField.inputAccessoryView = self.keyboardToolbar
        
        self.loadDefaults()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateServerButton()
    }
    
    @IBAction func loginDidPress(_ sender: UIButton) {
        self.login()
    }
    
    @IBAction func textDoneDidPress(_ sender: UIBarButtonItem) {
        self.usernameTextField.resignFirstResponder()
        self.passwordTextField.resignFirstResponder()
    }
    
    @IBAction func serverButtonDidPress(_ sender: UIButton) {
        let inputVC = UIAlertController(title: "Choose Server", message: "Specify Custom URL", preferredStyle: .alert)
        inputVC.addTextField { (textField) in
            textField.placeholder = "https://www.example.com"
            textField.text = self.customServer
        }
        let disableAction = UIAlertAction(title: "Use Production Server", style: .default) { (alert) in
            self.customServerEnabled = false
        }
        let enableAction = UIAlertAction(title: "Set Custom Server", style: .cancel) { (alert) in
            let textField = inputVC.textFields![0] as UITextField
            
            // Only allow server names that at least specify http/https correctly
            guard let scheme = URL(string: textField.text ?? "")?.scheme,
                scheme == "http" || scheme == "https" else {
                    self.customServerEnabled = false
                    return
                }
            
            self.customServer = textField.text
            self.customServerEnabled = true
        }
        
        inputVC.addAction(disableAction)
        inputVC.addAction(enableAction)
        
        self.present(inputVC, animated: true)
    }
    
    // MARK: - Convenience Functions
    fileprivate func login() {
        guard let username = self.usernameTextField.text,
            let password = self.passwordTextField.text else {
                // Do nothing if attmept to login with no username/password
                return
        }
        
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.mode = .indeterminate
        hud.label.text = "Attempting to log in"
        FeedController.shared.login(username: username, password: password) { error in
            defer {
                DispatchQueue.main.async {
                    hud.hide(animated: true)
                }
            }
            
            DispatchQueue.main.async {
                self.saveDefaults()
            }
            if let error = error {
                DispatchQueue.main.async {
                    self.present(error: error)
                }
                return
            }
            
            FeedController.shared.serverUrl = self.serverUrl
            self.didLogin()
        }
    }
    
    fileprivate func updateServerButton() {
        let newTitle: String
        if self.customServerEnabled {
            newTitle = self.customServer ?? "(no server)"
            self.serverButton.alpha = 1.0
        } else {
            newTitle = "Production"
            self.serverButton.alpha = 0.25
        }
        self.serverButton.setTitle(newTitle, for: .normal)
    }
    
    // MARK: Persist user entry
    enum DefaultsKey: String {
        case customServerEnabled
        case customServer
        
        case username
        // FIXME: Convenience during development.  Password should use keychain in production.
        case password
    }
    fileprivate func loadDefaults() {
        let store = UserDefaults.standard
        
        self.usernameTextField.text = store.string(forKey: DefaultsKey.username.rawValue)
        self.passwordTextField.text = store.string(forKey: DefaultsKey.password.rawValue)
        self.customServer = store.string(forKey: DefaultsKey.customServer.rawValue)
        self.customServerEnabled = store.bool(forKey: DefaultsKey.customServerEnabled.rawValue)
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
        
        if let text = self.customServer {
            store.set(text, forKey: DefaultsKey.customServer.rawValue)
        } else {
            store.removeObject(forKey: DefaultsKey.customServer.rawValue)
        }

        store.set(self.customServerEnabled, forKey: DefaultsKey.customServerEnabled.rawValue)
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
