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
    
    struct Keys {
        static let Title = "title"
        static let ID = "id"
        static let Secret = "secret"
        static let Server = "server"
        static let Farm = "farm"
    }
    
    @NSManaged var title : String
    @NSManaged var id : String
    @NSManaged var secret : String
    @NSManaged var server : String
    @NSManaged var farm : NSNumber
    @NSManaged var pin: Pin?
    
    var imagePath = ""
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?){
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        imagePath = "\(id)_\(secret)_m.jpg"
    }
    
    init(dictionary : [String : AnyObject], context: NSManagedObjectContext){

        let entity = NSEntityDescription.entityForName("Picture", inManagedObjectContext: context)!
            
        super.init(entity: entity, insertIntoManagedObjectContext: context)
            
        title = dictionary[Keys.Title] as! String
        id = dictionary[Keys.ID] as! String
        secret = dictionary[Keys.Secret] as! String
        server = dictionary[Keys.Server] as! String
        farm = dictionary[Keys.Farm] as! Int
        imagePath = "\(id)_\(secret)_m.jpg"
    }
    
    var photoComputed: UIImage? {
        get {
            return FlickrClient.Caches.imageCache.imageWithIdentifier(imagePath)
        }
        
        set {
            FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: imagePath)
        }
    }
    
    override func prepareForDeletion() {
        photoComputed = nil
    }
    
}
