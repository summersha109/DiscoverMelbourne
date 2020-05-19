//
//  CoreDataController.swift
//  DiscoverMelb
//
//  Created by ShaZHu on 3/9/19.
//  Copyright © 2019 Monash University. All rights reserved.
//

import UIKit
import CoreData

extension UIImage {
    
    func toData() -> Data? {
        return pngData()
    }
}

class CoreDataController: NSObject, DatabaseProtocol, NSFetchedResultsControllerDelegate {
    
    
    var listeners = MulticastDelegate<DatabaseListener>()
    var persistantContainer: NSPersistentContainer
    
    var oneLocationFetchedResultsController: NSFetchedResultsController<Sight>?
    
    // Results
    var allLocationFetchedResultsController: NSFetchedResultsController<Sight>?
    //var imageFetchedResultsController: NSFetchedResultsController<ImageMeteData>?
    override init() {
        persistantContainer = NSPersistentContainer(name: "Location")
        persistantContainer.loadPersistentStores() { (description, error) in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        
        super.init()
        
        // If there are no heroes in the database assume that the app is running
        // for the first time. Create the default team and initial superheroes.
        if fetchAllLocations().count == 0 {
            createDefaultEntries()
        }
    }
    
    func saveContext() {
        if persistantContainer.viewContext.hasChanges {
            do {
                try persistantContainer.viewContext.save()
            } catch {
                fatalError("Failed to save data to Core Data: \(error)")
            }
        }
    }
    
    func addLocation(name: String, imageName: NSData, category: String, locationDescription: String, latitude: Double, longitude: Double) -> Sight {
        let location = NSEntityDescription.insertNewObject(forEntityName: "Sight", into: persistantContainer.viewContext) as! Sight
        location.name = name
        location.imageName = imageName
        location.category = category
        location.locationDescription = locationDescription
        location.latitude = latitude
        location.longitude = longitude
        
        // This less efficient than batching changes and saving once at end.
        saveContext()
        return location
    }
    
    //    func addImage(filename: String) -> ImageMeteData {
    //        let image = NSEntityDescription.insertNewObject(forEntityName: "ImageMeteData", into: persistantContainer.viewContext) as! ImageMeteData
    //
    //        image.filename = filename
    //        // This less efficient than batching changes and saving once at end.
    //        saveContext()
    //        return image
    //    }
    
    func editLocation(sight: Sight,name: String,imageName: NSData, category: String, locationDescription: String, latitude: Double, longitude: Double) {
        let editingLocation: NSManagedObject?
        if getUpdatedLocation(location: sight) != nil {
            editingLocation = (getUpdatedLocation(location: sight)! as NSManagedObject)
            editingLocation?.setValue(name, forKey: "name")
            editingLocation?.setValue(imageName, forKey: "imageName")
            editingLocation?.setValue(locationDescription, forKey: "locationDescription")
            editingLocation?.setValue(latitude, forKey: "latitude")
            editingLocation?.setValue(longitude, forKey: "longitude")
            
            saveContext()
        }
    }
    
    //    func editLocationImage(location: Sight, image: NSData) {
    //
    //        location.image = image
    //    }
    
    func getUpdatedLocation(location: Sight) -> Sight?{
        let fetchRequest: NSFetchRequest<Sight> = Sight.fetchRequest()
        let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [nameSortDescriptor]
        let predicate = NSPredicate(format: "name == %@", location.name!)
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        oneLocationFetchedResultsController = NSFetchedResultsController<Sight>(fetchRequest: fetchRequest, managedObjectContext: persistantContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        oneLocationFetchedResultsController?.delegate = self
        do {
            try oneLocationFetchedResultsController?.performFetch()
        } catch {
            print("Fetch Request failed: \(error)")
        }
        
        
        if oneLocationFetchedResultsController?.fetchedObjects != nil && !(oneLocationFetchedResultsController?.fetchedObjects?.isEmpty)!  {
            return (oneLocationFetchedResultsController?.fetchedObjects)!.first!
        }
        return nil
    }
    
    
    
    
    func deleteLocation(location: Sight) {
        persistantContainer.viewContext.delete(location)
        // This less efficient than batching changes and saving once at end.
        saveContext()
    }
    
    //    func deleteImage(image: ImageMeteData) {
    //        persistantContainer.viewContext.delete(image)
    //        // This less efficient than batching changes and saving once at end.
    //        saveContext()
    //    }
    
    func addListener(listener: DatabaseListener) {
        listeners.addDelegate(listener)
        
        if listener.listenerType == ListenerType.location {
            listener.onLocationChange(change: .update, locationSights: fetchAllLocations())
        }
        
        //        if listener.listenerType == ListenerType.image {
        //            listener.onImageChange(change: .update, imageList: fetchAllImages())
        //        }
    }
    
    func removeListener(listener: DatabaseListener) {
        listeners.removeDelegate(listener)
    }
    
    func fetchAllLocations() -> [Sight] {
        let fetchRequest: NSFetchRequest<Sight> = Sight.fetchRequest()
        let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [nameSortDescriptor]
        allLocationFetchedResultsController = NSFetchedResultsController<Sight>(fetchRequest:
            fetchRequest, managedObjectContext: persistantContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        allLocationFetchedResultsController?.delegate = self
        do {
            try allLocationFetchedResultsController?.performFetch()
        } catch {
            print("Fetch Request failed: \(error)")
        }
        
        
        var locations = [Sight]()
        if allLocationFetchedResultsController?.fetchedObjects != nil {
            locations = (allLocationFetchedResultsController?.fetchedObjects)!
        }
        
        return locations
    }
    
    //    func fetchAllImages() -> [ImageMeteData] {
    //        if imageFetchedResultsController == nil {
    //            let fetchRequest: NSFetchRequest<ImageMeteData> = ImageMeteData.fetchRequest()
    //            let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
    //            fetchRequest.sortDescriptors = [nameSortDescriptor]
    //
    //            imageFetchedResultsController =
    //                NSFetchedResultsController<ImageMeteData>(fetchRequest: fetchRequest, managedObjectContext: persistantContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    //            imageFetchedResultsController?.delegate = self
    //
    //            do {
    //                try imageFetchedResultsController?.performFetch()
    //            } catch {
    //                print("Fetch Request failed: \(error)")
    //            }
    //        }
    
    //        var images = [ImageMeteData]()
    //        if imageFetchedResultsController?.fetchedObjects != nil {
    //            images = (imageFetchedResultsController?.fetchedObjects)!
    //        }
    //
    //        return images
    //    }
    
    // MARK: - Fetched Results Conttroller Delegate
    func controllerDidChangeContent(_ controller:
        NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == allLocationFetchedResultsController {
            listeners.invoke { (listener) in
                if listener.listenerType == ListenerType.location {
                    listener.onLocationChange(change: .update, locationSights: fetchAllLocations())
                }
            }
        }
        //        else if controller == imageFetchedResultsController {
        //            listeners.invoke { (listener) in
        //                if listener.listenerType == ListenerType.image {
        //                    listener.onImageChange(change: .update, imageList: fetchAllImages())
        //                }
        //            }
        //        }
    }
    
    func createDefaultEntries() {
        let _ = addLocation(name: "Flinders Street Station",
                            imageName: UIImage(named: "Flinders Street Station")?.toData() as! NSData,
                            category: "Building",
                            locationDescription: "Stand beneath the clocks of Melbourne's iconic railway station, as tourists and Melburnians have done for generations. Take a train for outer-Melbourne explorations, join a tour to learn more about the history of the grand building, or go underneath the station to see the changing exhibitions that line Campbell Arcade.",
                            latitude: -37.8174,
                            longitude: 144.9673)
        
        let _ = addLocation(name: "St Paul's Cathedral",
                            imageName: UIImage(named: "cathedral_melb")?.toData() as! NSData,
                            category: "Cathedral",
                            locationDescription: "Leave the bustling Flinders Street Station intersection behind and enter the peaceful place of worship that's been at the heart of city life since the mid 1800s. Join a tour and admire the magnificent organ, the Persian Tile and the Five Pointed Star of the historic St Paul's Cathedral.",
                            latitude: -37.81706,
                            longitude: 144.96761)
        
        let _ = addLocation(name: "The Scots' Church", imageName: UIImage(named: "scots_church")?.toData() as! NSData, category: "Church", locationDescription: "Look up to admire the 120-foot spire of the historic Scots' Church, once the highest point of the city skyline. Nestled between modern buildings on Russell and Collins streets, the decorated Gothic architecture and stonework is an impressive sight, as is the interior's timber panelling and stained glass. Trivia buffs, take note: the church was built by David Mitchell, father of Dame Nellie Melba (once a church chorister).", latitude: -37.81469, longitude: 144.96904)
        
        let _ = addLocation(name: "Rippon Lea Estate",
                            imageName: UIImage(named: "lee")?.toData() as! NSData,
                            category: "Building",
                            locationDescription: "An intact example of 19th century suburban high life, the National Heritage Listed Rippon Lea Estate is like a suburb all to itself, an authentic Victorian mansion amidst 14 acres of breathtaking gardens.Make yourself at home exploring over 20 rooms in the original estate, its sweeping heritage grounds, a picturesque lake and waterfall, an original 19th century fruit orchard and the largest fernery in the Southern Hemisphere.Keep your eyes peeled for the Gruffalo’s latest hideout.Open all year, Rippon Lea Estate is Victoria’s grandest backyard.",
                            latitude:-37.87793882,
                            longitude:144.9979202)
        
        let _ = addLocation(name: "Royal Exhibition Building",
                            imageName: UIImage(named: "RoyMuseum")?.toData() as! NSData,
                            category: "Museum",
                            locationDescription: "North of the city centre, the majestic Royal Exhibition Building is surrounded by Carlton Gardens.The building is one of the world's oldest remaining exhibition pavilions and was originally built for the Great Exhibition of 1880. Later it housed the first Commonwealth Parliament from 1901, and was the first building in Australia to achieve a World Heritage listing in 2004.With a meticulously restored interior, expansive galleries and soaring dome, the Royal Exhibition Building's Great Hall continues to be an impressive setting for trade shows, fairs, cultural and community events. The International Flower and Garden Show are held here annually.Tours of the Royal Exhibition Building depart from Melbourne Museum.",
                            latitude: -37.80469,
                            longitude: 144.97165)
        
        let _ = addLocation(name: "Shrine of Remembrance",
                            imageName: UIImage(named: "memory")?.toData() as! NSData,
                            category: "",
                            locationDescription: "The Shrine of Remembrance is a building with a soul. Opened in 1934, the Shrine is the Victorian state memorial to Australians who served in global conflicts throughout our nation’s history. Inspired by Classical architecture, the Shrine was designed and built by veterans of the First World War.",
                            latitude: -37.8311011,
                            longitude: 144.9766951)
        
        let _ = addLocation(name: "NGV International",
                            imageName: UIImage(named: "ngv")?.toData() as! NSData,
                            category: "Museum",
                            locationDescription: "he National Gallery of Victoria has two magnificent galleries located a short walk apart, both with free entry to the permanent collection.NGV International houses a whole world of international art, displaying the National Gallery of Victoria's collections of European, Asian, Oceanic and American art. Since the National Gallery of Victoria opened in St Kilda Road in 1968, the total collection has doubled in size to more than 70,000 works of art. A truly iconic Melbourne building, the gallery has been totally redesigned to house one of the most impressive collections in the Southern Hemisphere.",
                            latitude:37.8198009,
                            longitude:144.9605502)
        
        let _ = addLocation(name: "Parliament of Victoria",
                            imageName: UIImage(named: "pali")?.toData() as! NSData,
                            category: "Parliament",
                            locationDescription: "The Parliament of Victoria welcomes you to share in our history and heritage. Sit in the chambers where Victoria's laws are made, take in the majesty of Queen's Hall, and see where Australia's first Federal Parliament conducted proceedings for 26 years.",
                            latitude: 37.8116284,
                            longitude:144.9732506)
        
        let _ = addLocation(name: "Trades Hall",
                            imageName: UIImage(named: "hall")?.toData() as! NSData,
                            category: "Building",
                            locationDescription: "Established in 1859 as a meeting hall and a place to educate workers and their families - Trades Hall is still home to trade unions and political events - but has grown to embrace a diverse cultural focus. It's now a regular venue for theatre, art exhibitions, Melbourne International Comedy Festival and Melbourne Fringe Festival.",
                            latitude:-37.806686,
                            longitude:144.966225)
        
        let _ = addLocation(name: "Royal Arcade",
                            imageName: UIImage(named: "royal block")?.toData() as! NSData,
                            category: "Building",
                            locationDescription: "Built in 1869, Royal Arcade is Melbourne's oldest covered shopping precinct and the longest standing arcade in the country. Connecting Bourke Street Mall, Elizabeth Street and Little Collins Street, this ornate, heritage-listed arcade hosts a range of popular boutiques, cafes and specialty stores.Look up to fully appreciate the spectacular Italianate architectural features designed by renowned architect Charles Webb, who was also responsible for the iconic Windsor Hotel on Spring Street. Marvel at the glass and wrought iron ceiling and watch the famous statues of Gog and Magog strike the clock on the hour.",
                            latitude: -37.81453,
                            longitude: 144.9641)
        
        let _ = addLocation(name: "Arts Centre Melbourne",
                            imageName: UIImage(named: "art")?.toData() as! NSData,
                            category: "Building",
                            locationDescription: "Arts Centre Melbourne is both a defining Melbourne landmark and Australia's largest performing arts centre.For more than 30 years, Arts Centre Melbourne has been Melbourne’s leading venue for world-class theatre, dance, music and more. In the Theatres Building, directly under the venue’s iconic Spire, are three separate theatres – the State Theatre, which boasts one of the world’s largest stages and hosts performances by Opera Australia and The Australian Ballet, the Playhouse and the intimate Fairfax Studio. ",
                            latitude: -37.8200888,
                            longitude:144.9681294 )
        
        let _ = addLocation(name: "Dukes at Ross House",
                            imageName: UIImage(named: "duck")?.toData() as! NSData,
                            category: "Building",
                            locationDescription: "With sustainability at the heart of Dukes, it stands to reason that the coffee roasters would set up in Ross House to bring coffee to the masses. An important social justice hotspot, Ross House also boasts a prime Flinders Lane address. A percentage of sales go back to the Ross House community, so it makes sense to get your morning coffee and fine pastries from Dukes.",
                            latitude: -37.81676,
                            longitude:144.96606)
        
        let _ = addLocation(name: "Manchester Unity Building",
                            imageName: UIImage(named: "manchester")?.toData() as! NSData,
                            category: "Building",
                            locationDescription: "The Manchester Unity Building is one of Melbourne's most iconic Art Deco landmarks. It was built in 1932 for the Manchester Unity Independent Order of Odd Fellows (IOOF), a friendly society providing sickness and funeral insurance. Melbourne architect Marcus Barlow took inspiration from the 1927 Chicago Tribune Building. His design incorporated a striking New Gothic style façade of faience tiles with ground-floor arcade and mezzanine shops, café and rooftop garden. Step into the arcade for a glimpse of the marble interior, beautiful friezes and restored lift – or book a tour for a peek upstairs.",
                            latitude: -37.81529,
                            longitude: 144.9664)
        
        let _ = addLocation(name: "Federation Square",
                            imageName: UIImage(named: "square")?.toData() as! NSData,
                            category: "Building",
                            locationDescription: "It is increasingly hard to imagine Melbourne without Federation Square. As a home to major cultural attractions, world-class events, tourism experiences and an exceptional array of restaurants, bars and specialty stores, this modern piazza has become the city's meeting place. Since opening in 2002, Fed Square has become one of the most visited attractions in Melbourne with more than 10 million visits a year. It is host to more than 2,000 events a year and home to the National Gallery of Victoria's Australian collection, The Ian Potter Centre as well as the Australian Centre for the Moving Image (ACMI).",
                            latitude: -37.8164851,
                            longitude:144.9669885)
        
        let _ = addLocation(name: "State Library Victoria",
                            imageName: UIImage(named: "state library")?.toData() as! NSData,
                            category: "Library",
                            locationDescription: "The fourth most popular library in the world and the busiest in Australia, State Library Victoria is a must-visit Melbourne icon. Dating back to 1856, the State Library boasts incredible heritage architecture, free exhibitions, programs and events. Experience the majestic domed La Trobe Reading Room – one of the city’s most magnificent and photographed spaces. Enjoy free exhibitions showcasing some of the Library’s most precious treasures from its collection of more than five million items. And visit the recently opened redeveloped spaces including two new reading rooms and the Russell Street Welcome Zone – a vibrant lounge and meeting space that includes a stunning artwork spanning a 29x5 metre wall by Melbourne artist Tai Snaith. Free entry and wi-fi available. Relax before or after your visit at one of the two onsite cafes.",
                            latitude:-37.8098044,
                            longitude:144.9629957)
        
        let _ = addLocation(name: "St Patrick's Cathedral",
                            imageName: UIImage(named: "st")?.toData() as! NSData,
                            category: "Cathedral",
                            locationDescription: "Approach the mother church of the Catholic Archdiocese of Melbourne from the impressive Pilgrim Path, absorbing the tranquil sounds of running water and spiritual quotes before seeking sanctuary beneath the gargoyles and spires. Admire the splendid sacristy and chapels within, as well as the floor mosaics and brass items.",
                            latitude:-37.81082,
                            longitude:144.97693 )
        
        let _ = addLocation(name: "Old Melbourne Gaol",
                            imageName: UIImage(named: "old goal")?.toData() as! NSData,
                            category: "Building",
                            locationDescription: "Step back in time to Melbourne’s most feared destination since 1845, Old Melbourne Gaol.Shrouded in secrets, wander the same cells and halls as some of history’s most notorious criminals, from Ned Kelly to Squizzy Taylor, and discover the stories that never left. Hosting day and night tours, exclusive events and kids activities throughout school holidays and an immersive lock-up experience in the infamous City Watch House, the Gaol remains Melbourne’s most spell-binding journey into its past.",
                            latitude:-37.807514,
                            longitude:144.965018 )
        
    }
    
}
