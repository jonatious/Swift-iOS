//
//  ForgotPassViewController.swift
//  FreebieFinder
//
//  Created by jony on 11/16/16.
//  Copyright © 2016 ubicomp3. All rights reserved.
//

import UIKit
import Firebase

class ForgotPassViewController: UIViewController, UITextFieldDelegate {

    var ref: FIRDatabaseReference!
    
    @IBOutlet weak var securityQuestion: UILabel!
    @IBOutlet weak var answer: UITextField!
    @IBOutlet weak var newPass: UITextField!
    @IBOutlet weak var confirmPass: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        answer.delegate = self
        newPass.delegate = self
        confirmPass.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        ref = FIRDatabase.database().reference()
        ref.child("Users/\(SignedInUser.sharedInstance.userName!.lowercased())").observeSingleEvent(of: .value, with: { (snapshot) in
            if let value = snapshot.value as? [String: String]
            {
                self.securityQuestion.text = value["Question"]
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Actions
    
    @IBAction func submitBtn(_ sender: Any) {
        
        ref.child("Users/\(SignedInUser.sharedInstance.userName!.lowercased())").observeSingleEvent(of: .value, with: { (snapshot) in
            if let value = snapshot.value as? [String: String]
            {
                if self.answer.text != value["Answer"]
                {
                    let ac = UIAlertController(title: "Security Question", message: "Please enter the correct answer", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(ac, animated: true)
                    return
                }
                
                if(self.newPass.text != self.confirmPass.text)
                {
                    let ac = UIAlertController(title: "Passwords do not match", message: "Please enter passwords correctly", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(ac, animated: true)
                    return
                }
                
                if((self.newPass.text?.characters.count)! < 6)
                {
                    let ac = UIAlertController(title: "Small Password", message: "Password should have at least 6 characters", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(ac, animated: true)
                    return
                }
                
                self.ref.child("Users/\(SignedInUser.sharedInstance.userName!.lowercased())/Password").setValue(String(describing: self.newPass.text!.hash))
                
                let ac = UIAlertController(title: "Password Change Successful", message: "Sign in to continue", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default, handler: {(alert: UIAlertAction!) in self.dismiss(animated: true, completion: nil)}))
                self.present(ac, animated: true)
                return
                
            }
        }) { (error) in
            print(error.localizedDescription)
        }
        
        
    }
    
    @IBAction func backBtn(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //Methods
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    //delegates
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }

}
