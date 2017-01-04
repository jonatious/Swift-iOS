//
//  SignUpController.swift
//  FreebieFinder
//
//  Created by Jonatious Joseph Jawahar on 10/15/16.
//  Copyright © 2016 ubicomp3. All rights reserved.
//

import UIKit
import Firebase

class SignUpController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {

    var ref: FIRDatabaseReference!
    var questionsArray = ["What is your pet’s name?", "Name your first crush", "Your first job's manager", "Where was your first kiss?", "What is your dream job?", "What is your favourite restaurant?", "Who is your childhood friend?", "What is your first phone?"]
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var confirmPassword: UITextField!
    @IBOutlet weak var answer: UITextField!
    @IBOutlet weak var securityQuestion: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        username.delegate = self
        password.delegate = self
        confirmPassword.delegate = self
        answer.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        securityQuestion.delegate = self
        securityQuestion.dataSource = self
        securityQuestion.selectRow(2, inComponent: 0, animated: true)
        
        ref = FIRDatabase.database().reference()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Actions
    
    @IBAction func signUpBtn(_ sender: AnyObject) {
        ref.child("Users").observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            var value = snapshot.value as? [String:Any]
            
            if (value?[self.username.text!]) != nil
            {
                let ac = UIAlertController(title: "Username already exixsts", message: "Please try a different username", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(ac, animated: true)
                return
            }
            
            if(self.password.text != self.confirmPassword.text)
            {
                let ac = UIAlertController(title: "Passwords do not match", message: "Please enter passwords correctly", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(ac, animated: true)
                return
            }
            
            if((self.password.text?.characters.count)! < 6)
            {
                let ac = UIAlertController(title: "Small Password", message: "Password should have at least 6 characters", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(ac, animated: true)
                return
            }
            
            if(self.password.text == "" || self.username.text == "")
            {
                let ac = UIAlertController(title: "Empty Username/Password", message: "Please enter a valid Username/Password", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(ac, animated: true)
                return
            }
            
            var newUser = [String : Any]()
            newUser["Password"] = String(describing: self.password.text!.hash)
            newUser["Question"] = self.questionsArray[self.securityQuestion.selectedRow(inComponent: 0)]
            newUser["Answer"] = String(describing: self.answer.text!)
            
            value?[self.username.text!.lowercased()] = newUser
            
            self.ref.child("Users").setValue(value)
            
            SignedInUser.sharedInstance.signedIn = true
            SignedInUser.sharedInstance.userName = self.username.text!
            
            let ac = UIAlertController(title: "Sign Up Success", message: "Enjoy the freebies!", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: {(alert: UIAlertAction!) in self.performSegue(withIdentifier: "signUpSegue", sender: self)}))
            self.present(ac, animated: true)
            
            
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
    
    //Picker View
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return questionsArray.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return questionsArray[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        var pickerLabel = view as? UILabel;
        
        if (pickerLabel == nil)
        {
            pickerLabel = UILabel()
            
            pickerLabel?.font = UIFont.boldSystemFont(ofSize: 18)
            pickerLabel?.textAlignment = NSTextAlignment.center
            pickerLabel?.textColor = UIColor.white
        }
        
        pickerLabel?.text = questionsArray[row]
        
        return pickerLabel!;
    }
    
    //Text Fields
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
}
