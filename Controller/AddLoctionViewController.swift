//
//  AddLoctionViewController.swift
//  DiscoverMelb
//
//  Created by ShaZhu on 29/8/19.
//  Copyright © 2019 Monash University. All rights reserved.
//

import UIKit
import MapKit

class AddLoctionController: UIViewController, UISearchBarDelegate, UIImagePickerControllerDelegate,UINavigationControllerDelegate,UITextFieldDelegate, UITextViewDelegate{
    weak var databaseController: DatabaseProtocol?
    
    var locationName: String?
    var locationDescription: String?
    var locationCategory: String?
    var lai: Double = 0.0
    var long: Double = 0.0
    var sight: Sight?
    var locationImage: UIImage?
    var selectdCategory: String?
    
    let imagePicker = UIImagePickerController()
    
    @IBOutlet weak var nameInput: UITextField!
    
    @IBOutlet weak var descriptionInput: UITextView!
    
    @IBOutlet weak var addScrollView: UIScrollView!
    
    @IBOutlet weak var categoryText: UITextField!
    
    @IBOutlet weak var addMapView: MKMapView!
    
    @IBOutlet weak var locationImageView: UIImageView!
    
    @IBOutlet weak var categoryIcon: UIImageView!
    
    let category = ["Library","Museum","Parliament", "Cathedral", "Church", "Building"]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameInput.delegate = self
        descriptionInput.delegate = self
        
        //Change the navigation title
        if locationName != nil{
            navigationItem.title = "Edit location"
        }
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        addScrollView.contentSize = CGSize(width: 375, height: 2000)
        createCategoryPicker()
        createToolbar()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        databaseController = appDelegate.databaseController
        nameInput.becomeFirstResponder()
        
        if let locationName = locationName, let locationDescription = locationDescription, let locationImage = locationImage, let locationCategory = locationCategory, let lai: Double = lai, let long: Double = long, let sight = sight, locationName != "", locationDescription != ""{
            nameInput.text = locationName
            descriptionInput.text = locationDescription
            categoryText.text = locationCategory
            locationImageView.image = locationImage
            createAnnotation(latitude: lai, longtitude: long, title: locationName)
            focus(latitude: lai,longtitude: long)
        }
        imagePicker.delegate = self
    }
    
    //Enter keyborad return, the keyboard will disappear.(For textField)
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    //Enter keyborad return, the keyboard will disappear.(For textView)
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            print(">>textView")
            textView.resignFirstResponder()
            return true
        }
        
        return true
    }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    
    @IBAction func saveButton(_ sender: Any) {
        guard let image = locationImageView.image else {
            displayMessage(title: "No photos", message: "Error")
            return
        }
        
        let data = image.pngData() as! NSData
        // This is for edit.
        if locationName != nil && locationDescription != nil{
            if nameInput.text != "" && descriptionInput.text != "" && categoryText.text != "" && lai != 0.0 && long != 0.0 {
                let locationAddName = nameInput.text
                let locationAddDescription = descriptionInput.text
                let category = categoryText.text
                databaseController?.editLocation(sight: sight!, name: locationAddName!, imageName: data, category: category!, locationDescription: locationAddDescription!, latitude: lai, longitude: long)
                navigationController?.popViewController(animated: true)
            }
            
        }else{
            // This is for add new sight.
            if nameInput.text != "" && descriptionInput.text != "" && categoryText.text != "" && lai != 0.0 && long != 0.0 {
                let locationAddName = nameInput.text
                let locationAddDescription = descriptionInput.text
                let category = categoryText.text
                let _ = databaseController?.addLocation(name: locationAddName!, imageName: data as NSData, category: category!, locationDescription: locationAddDescription!, latitude: lai, longitude: long)
                navigationController?.popViewController(animated: true)
            }
        }
        
        var errorMsg = "Please ensure all fields are filled:\n"
        if nameInput.text == "" {
            errorMsg += "- Must provide a location name\n"
        }
        if descriptionInput.text == "" {
            errorMsg += "- Must provide location description"
        }
        
        self.displayMessage(title: "Not all fields filled", message: errorMsg)
        
    }
    
    
    
    @IBAction func searchButton(_ sender: Any) {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        present(searchController, animated: true, completion: nil)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Ignoring user
        UIApplication.shared.beginIgnoringInteractionEvents()
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.style = UIActivityIndicatorView.Style.gray
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        self.view.addSubview(activityIndicator)
        
        //Hide search bar
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
        
        //Create the search request
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchBar.text
        
        let activeSearch = MKLocalSearch(request: searchRequest)
        
        activeSearch.start { (response, error) in
            
            activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
            if response == nil
            {
                print("Error")
            }
            else{
                // Remove annotations
                let annotations = self.addMapView.annotations
                self.addMapView.removeAnnotations(annotations)
                
                // Getting data
                let latitude = response?.boundingRegion.center.latitude
                let lonitude = response?.boundingRegion.center.longitude
                
                //create annotation
                self.createAnnotation(latitude: latitude!, longtitude: lonitude!, title: searchBar.text!)
                
                // Zooming in on annotation
                self.focus(latitude: latitude!, longtitude: lonitude!)
                self.lai = latitude!
                self.long = lonitude!
            }
        }
    }
    
    func focus(latitude:Double, longtitude: Double){
        let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude,longtitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.1,longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: coordinate,span: span)
        self.addMapView.setRegion(region, animated: true)
    }
    
    func createAnnotation(latitude:Double, longtitude: Double, title: String){
        let annotation = MKPointAnnotation()
        annotation.title = title
        annotation.coordinate = CLLocationCoordinate2DMake(latitude, longtitude)
        self.addMapView.addAnnotation(annotation)
    }
    
    func createCategoryPicker(){
        let categoryPicker = UIPickerView()
        categoryPicker.delegate = self
        categoryText.inputView = categoryPicker
        
        categoryPicker.backgroundColor = .white
    }
    
    //For picker have done button
    func createToolbar(){
        
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(AddLoctionController.dismissKeyboard))
        toolBar.setItems([doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        categoryText.inputAccessoryView = toolBar
    }
    
    
    
    @objc func dismissKeyboard(){
        view.endEditing(true)
    }
    
    @IBAction func takePhotoButton(_ sender: Any) {
        let controller = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            controller.sourceType = .camera
            
        } else {
            controller.sourceType = .photoLibrary
        }
        controller.allowsEditing = false
        controller.delegate = self
        controller.modalPresentationStyle = .overCurrentContext
        self.present(controller, animated: true, completion: nil)
    }
    
    
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            locationImageView.image = pickedImage
            locationImageView.contentMode = .scaleAspectFit
            
        }
        dismiss(animated: true, completion: nil)
    }
    
    
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

}

extension AddLoctionController: UIPickerViewDelegate, UIPickerViewDataSource{
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return category.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return category[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectdCategory = category[row]
        categoryText.text = selectdCategory
        if categoryText.text == "Library"{
            categoryIcon.image = UIImage(named: "libraryicon")
        }else if categoryText.text == "Museum"{
            categoryIcon.image = UIImage(named: "museumicon")
        }else if categoryText.text == "Cathedral"{
            categoryIcon.image = UIImage(named: "cathedralicon")
        }else if categoryText.text == "Parliament"{
            categoryIcon.image = UIImage(named: "parliamenticon")
        }else if categoryText.text == "Church"{
            categoryIcon.image = UIImage(named: "churchicon")
        }else if categoryText.text == "Building"{
            categoryIcon.image = UIImage(named: "buildingicon")
        }
    }
    
    
    
    
    
}
