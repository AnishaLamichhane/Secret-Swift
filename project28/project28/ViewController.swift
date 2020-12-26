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
    }

    @IBAction func authenticationTapped(_ sender: Any) {
        let context = LAContext()
        var error: NSError?
        //says can we use toucn ID or face ID
        // we use & to locate the adress of error as it asked for a pointer
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify Yourself!"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
             [weak self]  success , authenticationError in
                DispatchQueue.main.async { //pushing the work in main thread for some reason it might be running in background
                    if success {
                        self?.unlockSecretMessage()
                    } else {
                        // error
                        print("couldnot match the face id")
                        let ac = UIAlertController(title: "Authentication failed", message: "You could not be verified; please try again.", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.   present(ac, animated: true)
                    }
                }
            }
        } else {
            //no biometry
            print("nO biometry")
            let ac = UIAlertController(title: "Biometry unavailable", message: "Your device is not configured for biometric authentication.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(ac, animated: true)
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
    
    @objc func saveSecretMessage() {
        guard secret.isHidden == false else { return } // if we save while the app is unlocked then the text is overwritten in the keychain two times
        KeychainWrapper.standard.set(secret.text, forKey: "secretMessage")
        secret.resignFirstResponder() //tell our text view that we're finished editing it, so the keyboard can be hidden
        secret.isHidden =  true
        title = "Nothing to see here"
        
    }
}

