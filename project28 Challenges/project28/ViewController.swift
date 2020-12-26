//
//  ViewController.swift
//  project28
//
//  Created by Anisha Lamichhane on 12/25/20.
//
import LocalAuthentication
import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var secret: UITextView!
    var doneButton: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Nothing to see here"
        
        let notificationCenter = NotificationCenter.default
        //that asks iOS to tell us when the keyboard changes or when it hides. As a double reminder: the hide is required because we do a little
        //hack to make the hardware keyboard toggle work correctly – see project 19 if you don't remember why this is needed.
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        //notify me and call saveSecretMessage when the app is not active or is running in background or else
        notificationCenter.addObserver(self, selector: #selector(saveSecretMessage), name: UIApplication.willResignActiveNotification, object: nil)
        doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(saveSecretMessage))
        self.navigationItem.rightBarButtonItem = nil
        
    }
    // challenge 2
    // it is based on the general concept that 1. First the user needs to register using email and password and then when pressing the authenticate button the email and the password is then verified.
    //taking email and password from the user
    // this is called when user taps the done button.
    
    @IBAction func registerTapped(_ sender: UIButton) {
        let ac = UIAlertController(title: "Register", message: "Enter password and Email", preferredStyle: .alert)
        ac.addTextField {textEmail in
            textEmail.placeholder = "Enter your Email"
        }
        ac.addTextField {textPassword in
            textPassword.isSecureTextEntry = true
            textPassword.placeholder = "Enter your password"
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default){ action in
            let emailField = ac.textFields![0]
            let passwordField = ac.textFields![1]
            //save it to the keychain
            guard !emailField.text!.isEmpty, !passwordField.text!.isEmpty else { return }
            KeychainWrapper.standard.set(emailField.text!, forKey: "Login")
            KeychainWrapper.standard.set(passwordField.text!, forKey: "Password")
            print("register tapped is clicked")
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        ac.addAction(saveAction)
        ac.addAction(cancelAction)
        present(ac, animated: true, completion: nil)
    }
    
    @IBAction func authenticationTapped(_ sender: UIButton) {
        // to verify the email and password
        //challenge 2
        let ac = UIAlertController(title: "Enter the Email and Password", message: nil, preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Login", style: .default) { [weak self] action in
            let loginField = ac.textFields![0]
            let passwordField = ac.textFields![1]
            //load from keychain
            guard !loginField.text!.isEmpty, !passwordField.text!.isEmpty else { return }
            
            if (KeychainWrapper.standard.string(forKey: "Login") == loginField.text)&&(KeychainWrapper.standard.string(forKey: "Password") == passwordField.text) {
                self?.authBiometric()
            } else {
                let ac  = UIAlertController(title: "Wrong", message: "Password or Login not match", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "Ok", style: .default))
                self?.present(ac, animated: true)
            }
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        ac.addTextField { textEmail in
            textEmail.placeholder = "Enter your login"
        }
        
        ac.addTextField { textPassword in
            textPassword.isSecureTextEntry = true
            textPassword.placeholder = "Enter your password"
        }
        
        ac.addAction(saveAction)
        ac.addAction(cancelAction)
        
        present(ac, animated: true, completion: nil)
    }
    
    func authBiometric() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify yourself!"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                [weak self] success, authenticationError in
                
                DispatchQueue.main.async {
                    if success {
                        self?.unlockSecretMessage()
                        self?.navigationItem.rightBarButtonItem = self?.doneButton
                    } else {
                        // error
                        let ac = UIAlertController(title: "Authentication failed", message: "You could not be verified; please try again.", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(ac, animated: true)
                    }
                }
            }
        } else {
            // no biometry
            let ac = UIAlertController(title: "Biometry unavailable", message: "Your device is not configured for biometric authentication.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
//    the code to adjust the toggling of the keyboard
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue // the size is relative to screen not our view
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            secret.contentInset = .zero // we are hiding
        } else { // we are not hiding
            secret.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }

        secret.scrollIndicatorInsets = secret.contentInset

        let selectedRange = secret.selectedRange
        secret.scrollRangeToVisible(selectedRange)
    }
    
    func unlockSecretMessage() {
        secret.isHidden = false
        title = "secret Stuff!"
        secret.text = KeychainWrapper.standard.string(forKey: "secretMessage") ?? "" // put the code in our textview
        
    }
 
// this is used to write to the keychain
    @objc func saveSecretMessage() {
        guard secret.isHidden == false else { return } // if we save while the app is unlocked then the text is overwritten in the keychain two times
        KeychainWrapper.standard.set(secret.text, forKey: "secretMessage")
        secret.resignFirstResponder() //tell our text view that we're finished editing it, so the keyboard can be hidden
        secret.isHidden =  true
        title = "Nothing to see here"
        
    }
}

