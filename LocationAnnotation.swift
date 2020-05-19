//
//  MapLocation.swift
//  DiscoverMelb
//
//  Created by 朱莎 on 2/9/19.
//  Copyright © 2019 Monash University. All rights reserved.
//

import UIKit
import MapKit

class LocationAnnotation: NSObject,MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var image: UIImage
    var category: String?
    
    init(newTitle: String, newSubtitle: String, lat: Double, long: Double, newImage: UIImage, newCategory: String) {
        self.title = newTitle
        self.subtitle = newSubtitle
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        self.image = newImage
        self.category = newCategory
        
        
    }
    
    
}
