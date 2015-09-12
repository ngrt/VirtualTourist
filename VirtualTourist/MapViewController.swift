//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Nawfal on 01/09/2015.
//  Copyright (c) 2015 Noufel Gouirhate. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var arrayOfPinsToPersist = [Pin]()
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: UIBarButtonItemStyle.Done, target: self, action: "editPins")
        
        var longPressRecogniser = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        
        longPressRecogniser.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressRecogniser)
        
        handleLongPress(longPressRecogniser)
        
        restoreMapRegion(false)
        
        arrayOfPinsToPersist = fetchAllPins()
        var annotations = [MKPointAnnotation]()
        
        for pin in arrayOfPinsToPersist {
            
            // The lat and long are used to create a CLLocationCoordinates2D instance.
            let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            
            // Here we create the annotation and set its coordiate, title, and subtitle properties
            var annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            annotations.append(annotation)
        }
        
        // When the array is complete, we add the annotations to the map.
        self.mapView.addAnnotations(annotations)
        
//        FlickrClient.sharedInstance().getImageFromFlickr(FlickrClient.sharedInstance().formatBbox(48.833222, latitude: 2.277398), completionHandler: { (picturesUrlString, error) -> Void in
//            var imagesToPass: [UIImage]?
//            
//            if let error = error {
//                println(error)
//            }
//            
//            imagesToPass = self.createArrayOfImages(picturesUrlString!)
//            self.appDelegate.images = imagesToPass
//        })

    }
    
    var filePath: String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    
    func saveMapRegion() {
        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)

    }
    

    func restoreMapRegion(animated: Bool) {
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
        
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        
            let savedRegion = MKCoordinateRegion(center: center, span: span)
        
            println("lat: \(latitude), lon: \(longitude), latD: \(latitudeDelta), lonD: \(longitudeDelta)")
        
            mapView.setRegion(savedRegion, animated: animated)
        }
    }



    //http://stackoverflow.com/questions/3959994/how-to-add-a-push-pin-to-a-mkmapviewios-when-touching
    func handleLongPress(gestureRecognizer : UIGestureRecognizer){
        if gestureRecognizer.state != .Began {
            return
        }
        
        let touchPoint = gestureRecognizer.locationInView(self.mapView)
        let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        let latitude = touchMapCoordinate.latitude as Double
        let longitude = touchMapCoordinate.longitude as Double
        
        let pinToBeAdded = Pin(latitude: touchMapCoordinate.latitude, longitude: touchMapCoordinate.longitude, context: self.sharedContext)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = touchMapCoordinate
        
        arrayOfPinsToPersist.append(pinToBeAdded)
        
        mapView.addAnnotation(annotation)
        
        var error: NSError? = nil
        self.sharedContext.save(&error)
        if let error = error {
            println("error saving context: \(error.localizedDescription)")
        }
    }
    
    func fetchAllPins() -> [Pin] {
        let error: NSErrorPointer = nil
        
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        // Execute the Fetch Request
        let results = sharedContext.executeFetchRequest(fetchRequest, error: error)
        
        // Check for Errors
        if error != nil {
            println("Error in fectchAllActors(): \(error)")
        }
        
        // Return the results, cast to an array of Person objects
        return results as! [Pin]
    }

    
    
    func editPins() {
        //1-afficher la view en rouge disant que tu peux supprimer des pins
        //2-faire monter la carte
        //3-supprimer les pins de Core Data
        println("editPins() touched")
    }
    
    lazy var sharedContext: NSManagedObjectContext =  {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }()

    func createArrayOfImages(arrayOfURLs : [String]) -> [UIImage] {
        var arrayOfImage = [UIImage]()
        for url in arrayOfURLs {
            let imageURL = NSURL(string: url)
            
            if let imageData = NSData(contentsOfURL : imageURL!) {
                let finalImage = UIImage(data: imageData)
                arrayOfImage.append(finalImage!)
            }
        }
        
        return arrayOfImage
    }


}

extension MapViewController : MKMapViewDelegate {
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    func mapView(mapView: MKMapView!, didDeselectAnnotationView view: MKAnnotationView!) {
        
        let coordinate = CLLocationCoordinate2DMake(view.annotation.coordinate.latitude, view.annotation.coordinate.longitude)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        
        self.appDelegate.pin = annotation
        
        FlickrClient.sharedInstance().getImageFromFlickr(FlickrClient.sharedInstance().formatBbox(self.appDelegate.pin!.coordinate.longitude, latitude: self.appDelegate.pin!.coordinate.latitude), completionHandler: { (picturesUrlString, error) -> Void in
            var imagesToPass: [UIImage]?
            
            if let error = error {
                println(error)
            }
            
            imagesToPass = self.createArrayOfImages(picturesUrlString!)
            self.appDelegate.images = imagesToPass
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let photoViewController = self.storyboard!.instantiateViewControllerWithIdentifier("photoViewController") as! PhotoViewController
                self.navigationController!.pushViewController(photoViewController, animated: true)
            })

        })

    }

}


