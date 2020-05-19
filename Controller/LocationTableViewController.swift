//
//  LocationTableViewController.swift
//  DiscoverMelb
//
//  Created by 朱莎 on 28/8/19.
//  Copyright © 2019 Monash University. All rights reserved.
//

import UIKit
import CoreData
import MapKit


class LocationTableController: UITableViewController, DatabaseListener, UISearchResultsUpdating{
    
    weak var databaseController: DatabaseProtocol?
    var listenerType = ListenerType.location
    var locations:[Sight] = []
    var filteredLocations: [Sight] = []
    var row = 0
    var isAddding: Bool = false
    var isEdit: Bool = false
    var mapViewDelegate: MapViewDelegate?
    
    let searchController = UISearchController(searchResultsController: nil)
    
    @IBOutlet var locationTableView: UITableView!
    
    override func viewDidLoad() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        databaseController = appDelegate.databaseController// Get core data

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Locations"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
        // Load image.
        func loadImageData(fileName: String) -> UIImage?{
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
            let url = NSURL(fileURLWithPath: path)
            var image: UIImage?
            if let pathComponent = url.appendingPathComponent(fileName)
            {
                let filePath = pathComponent.path
                let fileManager = FileManager.default
                let fileData = fileManager.contents(atPath: filePath)
                image = UIImage(data: fileData!)
            }
            return image
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    // Sort A to Z function
    @IBAction func sortAZButton(_ sender: Any) {
        filteredLocations = filteredLocations.sorted() {$0.name! < $1.name!}
        tableView.reloadData()
    }
    // Sort Z to A function
    @IBAction func sortZAButton(_ sender: Any) {
        filteredLocations = filteredLocations.sorted() {$0.name! > $1.name!}
        print(filteredLocations)
        tableView.reloadData()
    }
    
    func onLocationChange(change: DatabaseChange, locationSights: [Sight]) {
        locations = locationSights
        updateSearchResults(for: navigationItem.searchController!)
    }
    
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, searchText.count > 0 {
            
            filteredLocations = locations.filter { sight in
                guard let name = sight.name else {
                    return false
                }
                return name.contains(searchText)
            }
        }
        else {
            filteredLocations = locations;
        }
        
        tableView.reloadData()
    }
    
    @IBAction func addSightButton(_ sender: Any) {
        isAddding = true
        self.performSegue(withIdentifier: "newSight", sender:self)
        
    }
    

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return filteredLocations.count
    }
    
    // Pass data to table cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "locationCell", for: indexPath) as? LocationTableViewCell else {
            return UITableViewCell()
        }
        cell.locationImage.image =  UIImage(data: filteredLocations[indexPath.row].imageName! as Data)
        cell.locationNameLabel.text = filteredLocations[indexPath.row].name
        cell.locationDescriptionLabel.text = filteredLocations[indexPath.row].locationDescription
        return cell
    }
    
    //Select cell will jump to map
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let lai = locations[indexPath.row].latitude
        let long = locations[indexPath.row].longitude
        mapViewDelegate?.focusLocation(coordinate: CLLocationCoordinate2D(latitude: lai, longitude: long))
        navigationController?.popToRootViewController(animated: true)
    }
    
    
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //If identifier is newsight, will jump to addlocation view.
        if segue.identifier == "newSight"{
            // When click the addsight button, the isAddding become true, will jump to add sight
            if isAddding == true{
                segue.destination as! AddLoctionController
            }else{
                //Pass the data to addloction view for edit
              
                let vc = segue.destination as! AddLoctionController
                vc.locationName = filteredLocations[self.row].name
                vc.locationDescription = filteredLocations[self.row].locationDescription
                vc.locationImage = UIImage(data: filteredLocations[self.row].imageName! as Data)
                vc.locationCategory = filteredLocations[self.row].category
                vc.lai = filteredLocations[self.row].latitude
                vc.long = filteredLocations[self.row].longitude
                vc.sight = filteredLocations[self.row]
            }
        }
        else if  segue.identifier == "showDetail"{
            let detailController = segue.destination as! LocationInforViewController
            let cell = sender as! LocationTableViewCell
            let detailRow = locationTableView.indexPath(for: cell)!.row
            // If the search is active, will use fliterlocation data.
            if !searchController.isActive{
                detailController.locationName = locations[detailRow].name
                detailController.locationDescription = locations[detailRow].locationDescription
                detailController.laititude = locations[detailRow].latitude
                detailController.longtitude = locations[detailRow].longitude
                detailController.sightImage = UIImage(data: locations[detailRow].imageName! as Data)
            }
                
            else{
                detailController.locationName = filteredLocations[detailRow].name
                detailController.locationDescription = filteredLocations[detailRow].locationDescription
                detailController.laititude = filteredLocations[detailRow].latitude
                detailController.longtitude = filteredLocations[detailRow].longitude
                detailController.sightImage = UIImage(data: filteredLocations[detailRow].imageName! as Data)
            }
            
        }
    }
    
    //Swip button. Edit or delete cell.
    override func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        let edit = UITableViewRowAction(style: .normal, title: "Edit") { action, index in
            self.row = editActionsForRowAt.row
            self.performSegue(withIdentifier: "newSight", sender:self)
        }
        edit.backgroundColor = .orange
        
        let delete = UITableViewRowAction(style: .normal, title: "Delete") { action, index in
            self.databaseController?.deleteLocation(location: self.locations[self.row])
        }
        delete.backgroundColor = .red
        
        return [edit, delete]
    }
}






