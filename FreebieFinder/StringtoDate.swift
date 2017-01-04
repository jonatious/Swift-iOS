//
//  StringtoDate.swift
//  FreebieFinder
//
//  Created by jony on 11/10/16.
//  Copyright © 2016 ubicomp3. All rights reserved.
//

import Foundation

extension String
{
    var date : Date?
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyy hh:mm:ss a"
        
        return dateFormatter.date(from: self)
    }
}

extension Date
{
    var string : String?
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyy hh:mm:ss a"
        
        return dateFormatter.string(from: self)
    }
}
