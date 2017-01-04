//
//  ViewController.swift
//  FreebieFinder
//
//  Created by ubicomp3 on 9/26/16.
//  Copyright © 2016 ubicomp3. All rights reserved.
//

import UIKit
import Firebase
import LocalAuthentication
import MapKit

class ViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate {

    var ref: FIRDatabaseReference!
    var locationManager = CLLocationManager()
    let authContext = LAContext()
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var rememberMe: UISegmentedControl!
    @IBOutlet weak var touchID: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        username.delegate = self
        password.delegate = self
        
        self.touchID.isEnabled = false
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        self.checkTouchID()
        
        self.checkLocationAuthorizationStatus()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.requestLocation()
        }
        
        ref = FIRDatabase.database().reference()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Actions

    @IBAction func loginBtn(sender: AnyObject) {
        
        let defaults = UserDefaults.standard
        
        if self.rememberMe.selectedSegmentIndex == 0
        {
            defaults.set(self.username.text!, forKey: "Username")
            
            if self.touchID.selectedSegmentIndex == 0
            {
                defaults.set("Yes", forKey: "TouchIDEnabled")
            }
            else
            {
                defaults.set("No", forKey: "TouchIDEnabled")
            }
        }
        else
        {
            defaults.removeObject(forKey: "Username")
        }
        
        self.loginAction()
    }
    
    @IBAction func rememberBtn(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0
        {
            self.touchID.isEnabled = true
        }
        else
        {
            self.touchID.isEnabled = false
            self.touchID.selectedSegmentIndex = 1
        }
    }
    
    @IBAction func touchIDBtn(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0
        {
            guard authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
                self.touchID.selectedSegmentIndex = 1
                
                let ac = UIAlertController(title: "Touch ID Error", message: "This device does not have touch ID sensor", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(ac, animated: true)
                return
            }
        }
    }
    
    @IBAction func forgotPass(_ sender: Any) {
        ref.child("Users/\(self.username.text!.lowercased())").observeSingleEvent(of: .value, with: { (snapshot) in
            if (snapshot.value as? [String: String]) != nil
            {
                SignedInUser.sharedInstance.userName = self.username.text!
                self.performSegue(withIdentifier: "forgotPassSegue", sender: self)
            }
            else
            {
                let ac = UIAlertController(title: "Username not found", message: "Please enter username correctly", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(ac, animated: true)
                return
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    //Methods
    
    func showTouchIDAuthentication()
    {
        authContext.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Sign In with Touch ID to continue as " + self.username.text!,
            reply: { [unowned self] (success, error) -> Void in
                
                if( success ) {
                    DispatchQueue.main.async {
                        
                        self.loginUser(username: self.username.text!)
                        self.performSegue(withIdentifier: "LoginSegue", sender: self)
                    }
                }
                else
                {
                    if error!.localizedDescription != "Canceled by user."
                    {
                        if error!.localizedDescription == "UI canceled by system."
                        {
                            let ac = UIAlertController(title: "Touch ID Login Canceled", message: "Please sign in to continue.", preferredStyle: .alert)
                            ac.addAction(UIAlertAction(title: "OK", style: .default))
                            self.present(ac, animated: true)
                            return
                        }
                        
                        if error != nil {
                            let ac = UIAlertController(title: "Touch ID Error", message: error?.localizedDescription, preferredStyle: .alert)
                            ac.addAction(UIAlertAction(title: "OK", style: .default))
                            self.present(ac, animated: true)
                        }
                    }
                }
        })
    }
    
    func checkTouchID()
    {
        let defaults = UserDefaults.standard
        
        if let user = defaults.string(forKey: "Username")
        {
            self.username.text = user
            self.rememberMe.selectedSegmentIndex = 0
            self.touchID.isEnabled = true
            
            if let touchIDenabled = defaults.string(forKey: "TouchIDEnabled")
            {
                if touchIDenabled == "Yes"
                {
                    self.touchID.selectedSegmentIndex = 0
                    self.showTouchIDAuthentication()
                }
            }
        }
    }
    
    func loginAction()
    {
        ref.child("Users/\(self.username.text!.lowercased())").observeSingleEvent(of: .value, with: { (snapshot) in
            if let value = snapshot.value as? [String: String]
            {
                if let pass = self.password.text?.hash
                {
                    if(String(describing: pass) == value["Password"])
                    {
                        self.loginUser(username: self.username.text!)
                        self.performSegue(withIdentifier: "LoginSegue", sender: self)
                    }
                    else
                    {
                        let ac = UIAlertController(title: "Invalid Password", message: "Please enter password correctly", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
                        return
                    }
                }
            }
            else
            {
                let ac = UIAlertController(title: "Username not found", message: "Please enter username correctly", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(ac, animated: true)
                return
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    public func loginUser(username : String)
    {
        SignedInUser.sharedInstance.signedIn = true
        SignedInUser.sharedInstance.userName = username
    }
    
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    //delegates
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            SignedInUser.sharedInstance.currentLocation = location.coordinate
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.username
        {
            textField.resignFirstResponder()
        }
        else
        {
            self.loginAction()
        }
        return true
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }

}

