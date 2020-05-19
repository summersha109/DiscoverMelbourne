//
//  ImageMeteData+CoreDataProperties.swift
//  DiscoverMelb
//
//  Created by 朱莎 on 3/9/19.
//  Copyright © 2019 Monash University. All rights reserved.
//
//

import Foundation
import CoreData


extension ImageMeteData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ImageMeteData> {
        return NSFetchRequest<ImageMeteData>(entityName: "ImageMeteData")
    }

    @NSManaged public var filename: String?

}
