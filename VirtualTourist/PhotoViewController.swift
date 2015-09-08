//
//  PhotoViewController.swift
//  
//
//  Created by Nawfal on 02/09/2015.
//
//

import UIKit
import MapKit
import CoreData

class PhotoViewController: UIViewController, NSFetchedResultsControllerDelegate {

    var pin: Pin!
    
    var selectedIndexes = [NSIndexPath]()
    
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!

    @IBOutlet weak var pictureCollection: UICollectionView!
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchedResultsController.performFetch(nil)
        
        fetchedResultsController.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width,
        // with no space in between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let width = floor(self.pictureCollection.frame.size.width/3)
        layout.itemSize = CGSize(width: width, height: width)
        pictureCollection.collectionViewLayout = layout
    }

    
    override func viewWillAppear(animated: Bool) {
        
        let coordinate = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
        
        zoom(coordinate)
        
        var annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        self.mapView.addAnnotation(annotation)
        
        
        if pin.pictures.isEmpty {
            
            Flickr.sharedInstance().getImageFromFlickr(Flickr.sharedInstance().formatBbox(pin.longitude, latitude: pin.latitude), completionHandler: { (picturesUrlString, error) -> Void in
                if let error = error {
                    //afficher une alert view avec l'errur
                    println(error)
                } else {
                    var pictures = picturesUrlString!.map() { String -> Picture in
                        
                        let picture = Picture(imagePath: String, context: self.sharedContext)
                        picture.pin = self.pin
                        return picture
                    }
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.pictureCollection.reloadData()
                    }
                    
                    self.saveContext()
                }
            })
        }
    }
    
    // MARK: - Core Data Convenience
    
    lazy var sharedContext: NSManagedObjectContext =  {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
        }()
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Picture")
        
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()


    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func zoom(mapCoord : CLLocationCoordinate2D) {
        var mapCamera = MKMapCamera(lookingAtCenterCoordinate: mapCoord, fromEyeCoordinate: mapCoord, eyeAltitude: 1000)
        mapView.setCamera(mapCamera, animated: false)
    }



}
