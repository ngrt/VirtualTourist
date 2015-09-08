//
//  Picture.swift
//  VirtualTourist
//
//  Created by Nawfal on 05/09/2015.
//  Copyright (c) 2015 Noufel Gouirhate. All rights reserved.
//

import CoreData
import MapKit

class Picture: NSManagedObject {
    
    @NSManaged var imagePath : String
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?){
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(imagePath: String, context: NSManagedObjectContext){
        
        let entity = NSEntityDescription.entityForName("Picture", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.imagePath = imagePath
    }
    
    var image: UIImage? {
        
        get {
            return Flickr.Caches.imageCache.imageWithIdentifier(imagePath)
        }
        
        set {
            Flickr.Caches.imageCache.storeImage(newValue, withIdentifier: imagePath)
        }
    }
    
}
