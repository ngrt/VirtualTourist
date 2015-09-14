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
    
    @NSManaged var imageURL : String
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?){
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(imageURL: String, context: NSManagedObjectContext){
        
        let entity = NSEntityDescription.entityForName("Picture", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.imageURL = imageURL
    }
    
    var photoComputed: UIImage? {
        get {
            
            let url = NSURL(fileURLWithPath: imageURL)
            let fileName = url?.lastPathComponent
            
            return FlickrClient.Caches.imageCache.imageWithIdentifier(fileName!)
        }
        
        set {
            
            let url = NSURL(fileURLWithPath: imageURL)
            let fileName = url?.lastPathComponent
            
            FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: fileName!)
            
        }
    }
    
    override func prepareForDeletion() {
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        let pathArray = [dirPath, imageURL]
        let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
        NSFileManager.defaultManager().removeItemAtURL(fileURL, error: nil)
    }
    
}
