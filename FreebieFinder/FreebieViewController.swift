//
//  FreebieViewController.swift
//  FreebieFinder
//
//  Created by ubicomp3 on 9/26/16.
//  Copyright © 2016 ubicomp3. All rights reserved.
//

import UIKit
import Firebase
import MapKit
import CoreLocation

class FreebieViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, UITextViewDelegate, MKMapViewDelegate, CLLocationManagerDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate{
    
    var locationManager = CLLocationManager()
    var ref : FIRDatabaseReference!
    var messages : [String: Any]!
    var categoryArray = ["Food", "T-Shirt", "Other"]
    var freebieLocation: CLLocationCoordinate2D!
    var editFreebie: Freebie!
    
    @IBOutlet weak var titleOutlet: UITextField!
    @IBOutlet weak var place: UITextField!
    @IBOutlet weak var descOutlet: UITextView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var submitBtn: UIButton!
    
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var delImg: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleOutlet.delegate = self
        place.delegate = self
        descOutlet.delegate = self
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        if SignedInUser.sharedInstance.currentLocation == nil
        {
            if CLLocationManager.locationServicesEnabled() {
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                locationManager.requestLocation()
            }
        }
        else
        {
            self.setInitialMapLocation()
        }
        
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.selectRow(0, inComponent: 0, animated: true)

        self.ref = FIRDatabase.database().reference()
        
        submitBtn.isEnabled = false
        deleteBtn.isHidden = true
        delImg.isHidden = true
        
        if(self.editFreebie != nil)
        {
            deleteBtn.isHidden = false
            delImg.isHidden = false
            submitBtn.titleLabel?.text = "Save"
            self.loadEditFreebie()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Actions
    
    @IBAction func GotoCurrentLocation(_ sender: Any) {
        setInitialMapLocation()
    }
    
    @IBAction func deleteBtn(_ sender: Any) {
        self.deleteFreebie()
    }
    
    @IBAction func tapGestureHandler(recogniser: UITapGestureRecognizer)
    {
        self.deleteFreebie()
    }
    
    @IBAction func submitBtn(sender: AnyObject) {
        
        var id: String!
        
        if(self.editFreebie != nil)
        {
            id = self.editFreebie.id
        }
        else
        {
            id = String(describing: arc4random())
        }
        
        var newFreebie: Freebie!
        
        if(self.freebieLocation != nil)
        {
            newFreebie  = Freebie(id: id!, owner: SignedInUser.sharedInstance.userName!, title: titleOutlet.text!, place: place.text!, description: descOutlet.text!, category: categoryArray[pickerView.selectedRow(inComponent: 0)], thumbsup: 0, thumbsdown: 0, lat: self.freebieLocation.latitude, long: self.freebieLocation.longitude, lks: "", dlks: "", ctds: Date().string!)
        }
        else if(self.freebieLocation == nil && self.editFreebie == nil)
        {
            newFreebie  = Freebie(id: id!, owner: SignedInUser.sharedInstance.userName!, title: titleOutlet.text!, place: place.text!, description: descOutlet.text!, category: categoryArray[pickerView.selectedRow(inComponent: 0)], thumbsup: 0, thumbsdown: 0, lat: (SignedInUser.sharedInstance.currentLocation?.latitude)!, long: (SignedInUser.sharedInstance.currentLocation?.longitude)!, lks: "", dlks: "", ctds: Date().string!)
        }
        else
        {
            newFreebie  = Freebie(id: id!, owner: SignedInUser.sharedInstance.userName!, title: titleOutlet.text!, place: place.text!, description: descOutlet.text!, category: categoryArray[pickerView.selectedRow(inComponent: 0)], thumbsup: 0, thumbsdown: 0, lat: self.editFreebie.latitude, long: self.editFreebie.longitude, lks: "", dlks: "", ctds: Date().string!)
        }
        
        let newItem = self.createDictionary(freebie: newFreebie)
        
        SignedInUser.sharedInstance.messages?[newFreebie.id] = newItem
        
        self.ref.child("Freebies/\(newFreebie.id)").setValue(newItem)
        
        //self.performSegue(withIdentifier: "submitSegue", sender: self)
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func handleLongPress(recognizer:UILongPressGestureRecognizer) {
        if(recognizer.state == .began)
        {
            let allAnnotations = self.mapView.annotations
            self.mapView.removeAnnotations(allAnnotations)
            
            let touchpoint = recognizer.location(in: self.mapView)
            let newCoordinate = self.mapView.convert(touchpoint, toCoordinateFrom: self.mapView)
            
            self.freebieLocation = CLLocationCoordinate2D()
            
            self.freebieLocation.latitude = newCoordinate.latitude
            self.freebieLocation.longitude = newCoordinate.longitude
            
            self.createAnnotations(title: "Freebie is here", latitude: newCoordinate.latitude, longitude: newCoordinate.longitude)
        }
    }
    
    //Delegates
    
    //Location Manager
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            SignedInUser.sharedInstance.currentLocation = location.coordinate
            self.setInitialMapLocation()
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    //Text Fields
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if(titleOutlet.text != "" && descOutlet.text != "" && place.text != "")
        {
            submitBtn.isEnabled = true
        }
        else
        {
            submitBtn.isEnabled = false
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if(titleOutlet.text != "" && descOutlet.text != "" && place.text != "")
        {
            submitBtn.isEnabled = true
        }
        else
        {
            submitBtn.isEnabled = false
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    //Picker View
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categoryArray.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categoryArray[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        var pickerLabel = view as? UILabel;
        
        if (pickerLabel == nil)
        {
            pickerLabel = UILabel()
            
            pickerLabel?.font = UIFont.boldSystemFont(ofSize: 20)
            pickerLabel?.textAlignment = NSTextAlignment.center
            pickerLabel?.textColor = UIColor.white
        }
        
        pickerLabel?.text = categoryArray[row]
        
        return pickerLabel!;
    }
    
    //Map
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if(!(annotation.title!! == "My Location"))
        {
            let identifier = "pin"
            var view: MKPinAnnotationView
            
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                as? MKPinAnnotationView { // 2
                dequeuedView.annotation = annotation
                view = dequeuedView
            }
            else
            {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                view.pinTintColor = UIColor.red
                
                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure) as UIView
            }
            
            return view
        }
        return nil
    }
    
    //Methods
    
    func deleteFreebie()
    {
        let ac = UIAlertController(title: "Confirm Delete?", message: "Are you sure you want to delete the thread?", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Yes", style: .default, handler: {(alert: UIAlertAction!) in
            self.ref.child("Freebies/\(self.editFreebie.id)").setValue(nil)
            self.performSegue(withIdentifier: "submitSegue", sender: self)
        }))
        ac.addAction(UIAlertAction(title: "No", style: .default))
        self.present(ac, animated: true)
    }
    
    func createAnnotations(title: String, latitude: Double, longitude: Double)
    {
        let fetchedLocation = MKPointAnnotation()
        fetchedLocation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        fetchedLocation.title = title
        
        mapView.addAnnotation(fetchedLocation)
    }
    
    func setInitialMapLocation()
    {
        let initialLocation = CLLocation(latitude: (SignedInUser.sharedInstance.currentLocation?.latitude)!, longitude: (SignedInUser.sharedInstance.currentLocation?.longitude)!)
        
        let regionRadius: CLLocationDistance = 3000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(initialLocation.coordinate,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func loadEditFreebie()
    {
        titleOutlet.text = self.editFreebie.title
        place.text = self.editFreebie.place
        descOutlet.text = self.editFreebie.description
        pickerView.selectRow(categoryArray.index(of: self.editFreebie.category)!, inComponent: 0, animated: true)
        submitBtn.isEnabled = true
        
        self.createAnnotations(title: "Freebie is here", latitude: self.editFreebie.latitude, longitude: self.editFreebie.longitude)
    }
    
    func createDictionary(freebie : Freebie) -> [String : Any]
    {
        var newItem = [String : Any]()
        newItem["Category"] = freebie.category
        newItem["Description"] = freebie.description
        newItem["Owner"] = freebie.owner
        newItem["Place"] = freebie.place
        newItem["Title"] = freebie.title
        newItem["disLikes"] = freebie.disLikes
        newItem["likes"] = freebie.likes
        newItem["latitude"] = freebie.latitude
        newItem["longitude"] = freebie.longitude
        newItem["thumbsUp"] = freebie.thumbsUp
        newItem["thumbsDown"] = freebie.thumbsDown
        newItem["Active"] = 1
        newItem["CTDS"] = freebie.CTDS.string
        
        return newItem
    }

}
