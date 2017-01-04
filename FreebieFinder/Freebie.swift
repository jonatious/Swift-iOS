//
//  Freebie.swift
//  FreebieFinder
//
//  Created by ubicomp3 on 9/26/16.
//  Copyright © 2016 ubicomp3. All rights reserved.
//

import Foundation
import MapKit

class Freebie
{
    var id : String
    var owner : String
    var title : String
    var place : String
    var description : String
    var category : String
    var thumbsUp : Int
    var thumbsDown : Int
    var latitude : Double
    var longitude : Double
    var likes : String
    var disLikes : String
    var CTDS : Date
    
    init(id: String, owner : String, title : String, place : String, description : String, category : String, thumbsup : Int, thumbsdown : Int, lat : Double, long : Double, lks : String, dlks: String, ctds: String)
    {
        self.id = id
        self.owner = owner
        self.title = title
        self.place = place
        self.description = description
        self.category = category
        self.thumbsUp = thumbsup
        self.thumbsDown = thumbsdown
        self.latitude = lat
        self.longitude = long
        self.likes = lks
        self.disLikes = dlks
        self.CTDS = ctds.date!
    }
    
    var coordinate : CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(self.latitude, self.longitude)
    }
}
