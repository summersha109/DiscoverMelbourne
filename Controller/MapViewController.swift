//
//  MapViewController.swift
//  DiscoverMelb
//
//  Created by 朱莎 on 2/9/19.
//  Copyright © 2019 Monash University. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import UserNotifications

protocol MapViewDelegate: AnyObject {
    func focusLocation(coordinate: CLLocationCoordinate2D)
    
}

class MapViewController: UIViewController,DatabaseListener, CLLocationManagerDelegate, UNUserNotificationCenterDelegate, MapViewDelegate{
    
    @IBOutlet weak var mapView: MKMapView!
    private let locationManager = CLLocationManager()
    private var currentCoordinate: CLLocationCoordinate2D?
    weak var databaseController: DatabaseProtocol?
    var listenerType = ListenerType.location
    
    var locations:[Sight] = []
    var mapLocations: [LocationAnnotation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let center = UNUserNotificationCenter.current()
        
        let options: UNAuthorizationOptions = [.sound, .alert]
        
        center.requestAuthorization(options: options) {(granted, error) in
            if error != nil{}
        } // Get user authrize for notifiction.
        
        center.delegate = self
        locationManager.delegate = self
        mapView.delegate = self
        
        // Data base delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        databaseController = appDelegate.databaseController
        databaseController?.addListener(listener: self)
        // focus to Melbourne city
        focusLocation(coordinate: CLLocationCoordinate2D(latitude: -37.814, longitude: 144.96332))
        configureLocationServices()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        databaseController?.addListener(listener: self) // Get core data
    }
    
    
    override func didReceiveMemoryWarning(){
        super.didReceiveMemoryWarning()
    }
    
    func onLocationChange(change: DatabaseChange, locationSights: [Sight]) {
        // Remove annotations
        let annotations = self.mapView.annotations
        self.mapView.removeAnnotations(annotations)
        locations = locationSights
        addAnnotations()
    }
    
       override func viewWillDisappear(_ animated: Bool) {
           databaseController?.removeListener(listener: self)
        }
    
    // Send notifiction function
    func sendNotice(name: String){
        let content = UNMutableNotificationContent()
        content.title = "You enter the view area"
        content.body = "You have enter \(name)"
        content.badge = 1
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "enterLocation", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: {(error) in
        })
        
    }
    
    // Get user authorize
    func configureLocationServices(){
        let status = CLLocationManager.authorizationStatus()
        if  status == .notDetermined{
            locationManager.requestAlwaysAuthorization()
        }else if status == .authorizedWhenInUse{
            beginLocationUpdates(locationManger: locationManager)
        }else if status == .authorizedAlways{
            beginLocationSignificantUpdates(locationManger: locationManager)
        }
        
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Did get latest loction")
        guard let latestLocation = locations.first else { return }
        if currentCoordinate != nil{
            addAnnotations()
        }
        currentCoordinate = latestLocation.coordinate
    }
    
    //When user change autorization.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("The status changed")
        if status == .authorizedWhenInUse{
            beginLocationUpdates(locationManger: manager)
        }else if status == .authorizedAlways{
            beginLocationSignificantUpdates(locationManger: manager)
        }
    }
    
    // Present notice sound and alert
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert,.sound])
    }
    
    
    private func beginLocationUpdates(locationManger: CLLocationManager){
        mapView.showsUserLocation = true
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
    }
    
    private func beginLocationSignificantUpdates(locationManger: CLLocationManager){
        mapView.showsUserLocation = true
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    // Jump to map view from table view. Pass data to map view
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "map") {
            let destination = segue.destination as! LocationTableController
            destination.mapViewDelegate = self
        }
    }
    
    //func zoomToLatestLocation(with coordinate: CLLocationCoordinate2D){
    func focusLocation(coordinate: CLLocationCoordinate2D) {
        let zoomRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(mapView.regionThatFits(zoomRegion), animated: true)
        
    }
    
    func addAnnotations(){
        for i in 0..<locations.count{
            let sightAnnotation = LocationAnnotation(newTitle: locations[i].name!, newSubtitle: locations[i].locationDescription!, lat: locations[i].latitude, long: locations[i].longitude, newImage: UIImage(data: locations[i].imageName! as Data)!, newCategory: locations[i].category!)
            mapLocations.append(sightAnnotation) // add annotaion
            self.mapView.addAnnotation(sightAnnotation) // add annotation to map view
            let geoLocation = CLCircularRegion(center: sightAnnotation.coordinate, radius: 10, identifier: sightAnnotation.title!)
            geoLocation.notifyOnEntry = true
            locationManager.startMonitoringSignificantLocationChanges()
            locationManager.startMonitoring(for: geoLocation)
            
        }
        
    }
    
}

extension MapViewController: MKMapViewDelegate{
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? LocationAnnotation else { return nil }
        let identifier = "pin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil{
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView!.annotation = annotation
        }
        
        let locationLabel = UILabel() // create a popup label
        locationLabel.numberOfLines = 0
        locationLabel.font = locationLabel.font.withSize(13)
        locationLabel.text = (annotationView!.annotation as! LocationAnnotation).category
        annotationView!.detailCalloutAccessoryView = locationLabel // use calloutaccessoryview to add the popup label
        
        let mapButton = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        let image = (annotationView!.annotation as! LocationAnnotation).image
        mapButton.setBackgroundImage(image, for: UIControl.State())
        
        annotationView!.leftCalloutAccessoryView =  mapButton
        // Change the annotation icon style.
        if locationLabel.text == "Library"{
            annotationView?.image = UIImage(named: "libraryicon")
        }else if locationLabel.text == "Museum"{
            annotationView?.image = UIImage(named: "meseumicon")
        }else if locationLabel.text == "Cathedral"{
            annotationView?.image = UIImage(named: "cathedralicon")
        }else if locationLabel.text == "Parliament"{
            annotationView?.image = UIImage(named: "parliamenticon")
        }else if locationLabel.text == "Church"{
            annotationView?.image = UIImage(named: "churchicon")
        }else if locationLabel.text == "Building"{
            annotationView?.image = UIImage(named: "buildingicon")
        }
        
        annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure) // Add the information button

        return annotationView
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        sendNotice(name: region.identifier)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("The annotation was selected:\(String(describing: view.annotation?.title))")
    }
    
    // Pass data to detail view
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let annView = view.annotation as! LocationAnnotation
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let detailVc = storyboard.instantiateViewController(withIdentifier: "Detail") as! LocationInforViewController
        // Pass data
        detailVc.locationName = annView.title
        detailVc.locationDescription = annView.subtitle
        detailVc.laititude = annView.coordinate.latitude
        detailVc.longtitude = annView.coordinate.longitude
        detailVc.sightImage = annView.image
        self.navigationController?.pushViewController(detailVc, animated: true)
        
    }
}


