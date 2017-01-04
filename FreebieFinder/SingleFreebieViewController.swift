//
//  SingleFreebieViewController.swift
//  FreebieFinder
//
//  Created by ubicomp3 on 9/26/16.
//  Copyright © 2016 ubicomp3. All rights reserved.
//

import UIKit
import Firebase
import MapKit
import CoreLocation

class SingleFreebieViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    var selectedFreebie: Freebie!
    var ref : FIRDatabaseReference!
    var messages: [String: Any]!
    var isLiked = Bool()
    var isDisliked = Bool()
    var locationManager = CLLocationManager()
    
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var placeField: UITextField!
    @IBOutlet weak var descField: UITextView!
    @IBOutlet weak var thumbsUpCnt: UILabel!
    @IBOutlet weak var thumbsDownCnt: UILabel!
    @IBOutlet weak var owner: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleField.text = selectedFreebie.title
        placeField.text = selectedFreebie.place
        descField.text = selectedFreebie.description
        thumbsUpCnt.text = String(selectedFreebie.thumbsUp)
        thumbsDownCnt.text = String(selectedFreebie.thumbsDown)
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        let postedTime = Calendar.current.dateComponents([.minute,.second], from: selectedFreebie.CTDS, to: Date())
        
        owner.text = "posted by \(selectedFreebie.owner) \(postedTime.minute!) minute(s) \(postedTime.second!) second(s) ago"
        
        ref = FIRDatabase.database().reference()
        
        self.checkLikeDislike()
        
        mapView.delegate = self
        
        if CLLocationManager.locationServicesEnabled() {
            mapView.showsUserLocation = true
        }
        
        if SignedInUser.sharedInstance.currentLocation == nil
        {
            if CLLocationManager.locationServicesEnabled() {
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                locationManager.requestLocation()
            }
        }
        
        self.setInitialMapLocation()
        
        let allAnnotations = self.mapView.annotations
        self.mapView.removeAnnotations(allAnnotations)
        
        self.createAnnotations(title: "Freebie is HERE!", latitude: self.selectedFreebie.latitude, longitude: self.selectedFreebie.longitude)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //Actions
    
    @IBAction func goToCurrentLoc(_ sender: Any) {
        self.setInitialMapLocation()
    }
    
    @IBAction func likeTap(recogniser : UITapGestureRecognizer)
    {
        self.likeAction()
    }
    
    @IBAction func unLikeTap(recogniser : UITapGestureRecognizer)
    {
        self.dislikeAction()
    }
    
    //Preview items
    
    override var previewActionItems: [UIPreviewActionItem]{
        let NotName = Notification.Name("load")
        let likeAction = UIPreviewAction(title: "Like", style: .default) { (action, viewController) -> Void in
            self.likeAction()
            NotificationCenter.default.post(name: NotName, object: nil)
        }
        
        let deleteAction = UIPreviewAction(title: "DisLike", style: .destructive) { (action, viewController) -> Void in
            self.dislikeAction()
            NotificationCenter.default.post(name: NotName, object: nil)
        }
        
        return [likeAction, deleteAction]
    }
    
    //MAPS Methods
    
    func createAnnotations(title: String, latitude: Double, longitude: Double)
    {
        let fetchedLocation = MKPointAnnotation()
        fetchedLocation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        fetchedLocation.title = title
        
        mapView.addAnnotation(fetchedLocation)
    }
    
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
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if((view.annotation?.title)! == "Freebie is HERE!")
        {
            self.openMapForPlace(lat: (view.annotation?.coordinate.latitude)!, long: (view.annotation?.coordinate.longitude)!)
        }
    }
    
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
    
    
    //Methods
    
    func checkLikeDislike()
    {
        self.ref.child("Freebies/\(self.selectedFreebie.id)/likes").observeSingleEvent(of: .value, with: { (snapshot) in
            if(!snapshot.exists())
            {
                let ac = UIAlertController(title: "Error", message: "Freebie Deleted", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default, handler: {(alert: UIAlertAction!) in _ = self.navigationController?.popViewController(animated: true)}))
                self.present(ac, animated: true)
                return
            }
            
            let msg = snapshot.value as! String
            let users = msg.components(separatedBy: ",")
            self.isLiked = false
            
            for user in users
            {
                if user == SignedInUser.sharedInstance.userName
                {
                    self.isLiked = true
                }
            }
        })
        
        self.ref.child("Freebies/\(self.selectedFreebie.id)/disLikes").observeSingleEvent(of: .value, with: { (snapshot) in
            if(!snapshot.exists())
            {
                return
            }
            
            let msg = snapshot.value as! String
            let users = msg.components(separatedBy: ",")
            self.isDisliked = false
            
            for user in users
            {
                if user == SignedInUser.sharedInstance.userName
                {
                    self.isDisliked = true
                }
            }
        })
    }
    
    func openMapForPlace(lat: CLLocationDegrees, long: CLLocationDegrees) {
        
        let regionDistance:CLLocationDistance = 10000
        let coordinates = CLLocationCoordinate2DMake(lat, long)
        let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates, regionDistance, regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "\(placemark.name)"
        mapItem.openInMaps(launchOptions: options)
        
    }
    
    public func setInitialMapLocation()
    {
        if(SignedInUser.sharedInstance.currentLocation != nil)
        {
            let freebieLocation = CLLocation(latitude: self.selectedFreebie.latitude, longitude: self.selectedFreebie.longitude)
            let userLocation = CLLocation(latitude: (SignedInUser.sharedInstance.currentLocation?.latitude)!, longitude: (SignedInUser.sharedInstance.currentLocation?.longitude)!)
        
            let initialLocationDist = freebieLocation.distance(from: userLocation)
            let initialLocation = self.GetMidpoint(point1: freebieLocation, point2: userLocation)
        
            let regionRadius = initialLocationDist + 2000
            let coordinateRegion = MKCoordinateRegionMakeWithDistance(initialLocation.coordinate,
                                                                  regionRadius, regionRadius)
            mapView.setRegion(coordinateRegion, animated: true)
        }
    }
    
    func GetMidpoint(point1 : CLLocation, point2 : CLLocation) -> CLLocation
    {
        var c1 = point1.coordinate
        var c2 = point2.coordinate
        
        c1.latitude = ToRadian(x: c1.latitude)
        c2.latitude = ToRadian(x: c2.latitude)
        let dLon : CLLocationDegrees = ToRadian(x: c2.longitude - c1.longitude)
        let bx : CLLocationDegrees = cos(c2.latitude) * cos(dLon)
        let by : CLLocationDegrees = cos(c2.latitude) * sin(dLon)
        let latitude : CLLocationDegrees = atan2(sin(c1.latitude) + sin(c2.latitude), sqrt((cos(c1.latitude) + bx) * (cos(c1.latitude) + bx) + by*by))
        let longitude : CLLocationDegrees = ToRadian(x: c1.longitude) + atan2(by, cos(c1.latitude) + bx)
        
        var midpointCoordinate = CLLocationCoordinate2D()
        midpointCoordinate.longitude = ToDegrees(x: longitude)
        midpointCoordinate.latitude = ToDegrees(x: latitude)
        
        return CLLocation(latitude: midpointCoordinate.latitude, longitude: midpointCoordinate.longitude)
    }
    
    func likeAction()
    {
        if(!self.isLiked)
        {
            self.selectedFreebie.thumbsUp += 1
            if let name = SignedInUser.sharedInstance.userName
            {
                if self.selectedFreebie.likes != ""
                {self.selectedFreebie.likes.append(",\(name)")}
                else
                {self.selectedFreebie.likes.append("\(name)")}
            }
            self.ref.child("Freebies/\(self.selectedFreebie.id)/thumbsUp").setValue(self.selectedFreebie.thumbsUp)
            self.ref.child("Freebies/\(self.selectedFreebie.id)/likes").setValue(self.selectedFreebie.likes)
            self.isLiked = true
        }
        
        if(self.isDisliked)
        {
            if let name = SignedInUser.sharedInstance.userName
            {
                if self.selectedFreebie.disLikes.contains(",\(name)")
                {
                    self.selectedFreebie.disLikes = self.selectedFreebie.disLikes.replacingOccurrences(of: ",\(name)", with: "")
                }
                else if self.selectedFreebie.disLikes.contains("\(name),")
                {
                    self.selectedFreebie.disLikes = self.selectedFreebie.disLikes.replacingOccurrences(of: "\(name),", with: "")
                }
                else
                {
                    self.selectedFreebie.disLikes = self.selectedFreebie.disLikes.replacingOccurrences(of: "\(name)", with: "")
                }
            }
            self.selectedFreebie.thumbsDown -= 1
            self.ref.child("Freebies/\(self.selectedFreebie.id)/thumbsDown").setValue(self.selectedFreebie.thumbsDown)
            self.ref.child("Freebies/\(self.selectedFreebie.id)/disLikes").setValue(self.selectedFreebie.disLikes)
            self.isDisliked = false
        }
        
        self.viewDidLoad()
    }
    
    func dislikeAction()
    {
        if(self.isLiked)
        {
            if let name = SignedInUser.sharedInstance.userName
            {
                if self.selectedFreebie.likes.contains(",\(name)")
                {
                    self.selectedFreebie.likes = self.selectedFreebie.likes.replacingOccurrences(of: ",\(name)", with: "")
                }
                else if self.selectedFreebie.likes.contains("\(name),")
                {
                    self.selectedFreebie.likes = self.selectedFreebie.likes.replacingOccurrences(of: "\(name),", with: "")
                }
                else
                {
                    self.selectedFreebie.likes = self.selectedFreebie.likes.replacingOccurrences(of: "\(name)", with: "")
                }
            }
            self.selectedFreebie.thumbsUp -= 1
            self.ref.child("Freebies/\(self.selectedFreebie.id)/thumbsUp").setValue(self.selectedFreebie.thumbsUp)
            self.ref.child("Freebies/\(self.selectedFreebie.id)/likes").setValue(self.selectedFreebie.likes)
            self.isLiked = false
        }
        
        if(!self.isDisliked)
        {
            self.selectedFreebie.thumbsDown += 1
            if let name = SignedInUser.sharedInstance.userName
            {
                if self.selectedFreebie.disLikes != ""
                {self.selectedFreebie.disLikes.append(",\(name)")}
                else
                {self.selectedFreebie.disLikes.append("\(name)")}
            }
            self.ref.child("Freebies/\(self.selectedFreebie.id)/thumbsDown").setValue(self.selectedFreebie.thumbsDown)
            self.ref.child("Freebies/\(self.selectedFreebie.id)/disLikes").setValue(self.selectedFreebie.disLikes)
            self.isDisliked = true
        }
        self.viewDidLoad()
    }
    
    func ToRadian(x : CLLocationDegrees) -> CLLocationDegrees
    {
        return x * M_PI/180
    }
    
    func ToDegrees(x : CLLocationDegrees) -> CLLocationDegrees
    {
        return x * 180/M_PI
    }
}
