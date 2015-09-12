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

class PhotoViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var images: [UIImage]?
    
    var pin: MKPointAnnotation?
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    
    @IBOutlet weak var pictureCollection: UICollectionView!
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pictureCollection.reloadData()
    }
    
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
    
    override func viewWillAppear(animated: Bool) {
        
        let coordinate = CLLocationCoordinate2DMake(self.appDelegate.pin!.coordinate.latitude, self.appDelegate.pin!.coordinate.longitude)
        
        zoom(coordinate)
        
        var annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        self.mapView.addAnnotation(annotation)
    }
    
    @IBAction func newCollection(sender: AnyObject) {
        FlickrClient.sharedInstance().getImageFromFlickr(FlickrClient.sharedInstance().formatBbox(self.appDelegate.pin!.coordinate.longitude, latitude: self.appDelegate.pin!.coordinate.latitude), completionHandler: { (picturesUrlString, error) -> Void in
            var imagesToPass: [UIImage]?
            
            if let error = error {
                println(error)
            }
            
            imagesToPass = self.createArrayOfImages(picturesUrlString!)
            self.appDelegate.images = imagesToPass
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.pictureCollection.reloadData()
            })
            
        })
        
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

    func zoom(mapCoord : CLLocationCoordinate2D) {
        var mapCamera = MKMapCamera(lookingAtCenterCoordinate: mapCoord, fromEyeCoordinate: mapCoord, eyeAltitude: 1000)
        mapView.setCamera(mapCamera, animated: false)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return appDelegate.images!.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("pictureCell", forIndexPath: indexPath) as! PhotoAlbumCollectionViewCell
        let image = appDelegate.images![indexPath.item]
        cell.imageView.image = image
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        println("ouch")
    }

    lazy var fetchedREsultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Picture")
        
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin!)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
        
        }()

    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
        }()


}
