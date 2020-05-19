//
//  LocationInforViewController.swift
//  DiscoverMelb
//
//  Created by 朱莎 on 29/8/19.
//  Copyright © 2019 Monash University. All rights reserved.
//

import UIKit
import MapKit

class LocationInforViewController: UIViewController{
    var locationName: String?
    var locationDescription: String?
    var laititude: Double = 0.0
    var longtitude: Double = 0.0
    var sightImage: UIImage?
    
    @IBOutlet weak var locationNameLabel: UILabel!
    
    @IBOutlet weak var locationImage: UIImageView!
    
    
    @IBOutlet weak var locationDescripLabel: UILabel!
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var locatonScrollView: UIScrollView!
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        locatonScrollView.contentSize = CGSize(width: 375, height: 1200)
        //Data is passed from table view.
        if let locationName = locationName, let locationDescription = locationDescription,  let laititude: Double = laititude, let longtitude: Double = longtitude{
            locationNameLabel.text = locationName
            locationImage.image = sightImage
            locationDescripLabel.text = locationDescription
            focus(latitude: laititude, longtitude: longtitude)
            createAnnotation(latitude: laititude, longtitude: longtitude, title: locationName)
        }
    }
    //The focus will get sight location. The lai and long from tableview.
    func focus(latitude:Double, longtitude: Double){
        let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude,longtitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.1,longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: coordinate,span: span)
        self.mapView.setRegion(region, animated: true)
    }
    
    func createAnnotation(latitude:Double, longtitude: Double, title: String){
        let annotation = MKPointAnnotation()
        annotation.title = title
        annotation.coordinate = CLLocationCoordinate2DMake(latitude, longtitude)
        self.mapView.addAnnotation(annotation)
    }
    
    
    
}
