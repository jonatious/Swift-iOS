//
//  SignedInUser.swift
//  FreebieFinder
//
//  Created by jony on 11/1/16.
//  Copyright © 2016 ubicomp3. All rights reserved.
//

import Foundation
import MapKit

class SignedInUser: NSObject {
    
    static let sharedInstance = SignedInUser()
    
    var signedIn = false
    var userName: String?
    var messages: [String: Any]?
    var currentLocation: CLLocationCoordinate2D?
}
