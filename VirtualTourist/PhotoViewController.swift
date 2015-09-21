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

class PhotoViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
    var imageCount = 0
    var pin: Pin!
    var pageToGet = 1
    
    var selectedIndexes = [NSIndexPath]()
    
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    @IBOutlet weak var pictureCollection: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    @IBOutlet weak var noPhotosLabel: UILabel!
    
    //MARK: - Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchedResultsController.performFetch(nil)
        fetchedResultsController.delegate = self
        
        updateBottomButton()
        
        setTheMap()
        
        bottomButton.enabled = false
        noPhotosLabel.hidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        
        if pin.pictures.isEmpty {
            FlickrClient.sharedInstance().flickrGeoSearch(pin.latitude, lon: pin.longitude, page: pageToGet, completionHandler: { (JSONResult, error) -> Void in
                if let error = error {
                    println("Error in flickGeoSearch \(error)")
                } else {
                    let photos = JSONResult!["photos"] as! NSDictionary
                    
                    if let pagesSearchable = photos["pages"] as? Int {
                        self.sharedContext.performBlock({ () -> Void in
                            self.pin.pages = pagesSearchable
                        })
                        
                    }
                    
                    let photosDictionary = photos["photo"] as! [[String : AnyObject]]
                    
                    if photosDictionary.count == 0 {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.noPhotosLabel.hidden = false
                            self.view.bringSubviewToFront(self.noPhotosLabel)
                            self.pictureCollection.hidden = true
                        }
                        return
                    }
                    
                    self.sharedContext.performBlock({ () -> Void in
                        var photo = photosDictionary.map() { (dictionary: [String : AnyObject]) -> Picture in
                            let photo = Picture(dictionary:dictionary, context : self.sharedContext)
                            
                            photo.pin = self.pin
                            
                            return photo
                        }
                    })
                    
        
                    dispatch_async(dispatch_get_main_queue()) {
                        CoreDataStackManager.sharedInstance().saveContext()
                    }
                }
            })
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width,
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        
        let width = floor(self.pictureCollection.frame.size.width/3) - 1
        layout.itemSize = CGSize(width: width, height: width)
        pictureCollection.collectionViewLayout = layout
    }
    
    //MARK: - IBAction
    
    @IBAction func bottomButtonClicked(sender: AnyObject) {
        if selectedIndexes.isEmpty {
            newCollection()
        } else {
            deleteSelectedPictures()
        }
    }
    
    //MARK - Helper Methods
    
    func newCollection() {
        deleteAllPictures()
        println("newCollection() clicked")
        var pagesCanGet = pin.pages as Int
        pageToGet = Int(arc4random_uniform(10)) + 1
        FlickrClient.sharedInstance().flickrGeoSearch(pin.latitude, lon: pin.longitude, page: pageToGet) { (JSONResult, error) -> Void in
            if let error = error {
                
            } else {
                let photos = JSONResult!["photos"] as! NSDictionary
                let photosDictionary = photos["photo"] as! [[String : AnyObject]]
                
                self.sharedContext.performBlock({ () -> Void in
                    var pictures = photosDictionary.map() { (dictionary: [String : AnyObject]) -> Picture in
                        let picture = Picture(dictionary: dictionary, context: self.sharedContext)
                        
                        picture.pin = self.pin
                        
                        return picture
                    }

                })
                
                dispatch_async(dispatch_get_main_queue()) {
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
        }
            
    }
    
    func setTheMap() {
        let coordinate = CLLocationCoordinate2DMake(self.pin.latitude, self.pin.longitude)
        
        zoom(coordinate)
        
        var annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        self.mapView.addAnnotation(annotation)

    }
    
    // Delete all images in photos array
    func deleteAllPictures() {
        for picture in fetchedResultsController.fetchedObjects as! [Picture] {
            picture.prepareForDeletion()
            self.sharedContext.deleteObject(picture)
        }
    }
    
    func deleteSelectedPictures() {
        println("deleteSelectedPictures() clicked")
        var picturesToDelete = [Picture]()
        
        for indexPath in selectedIndexes {
            picturesToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Picture)
        }
        
        for picture in picturesToDelete {
            picture.prepareForDeletion()
            sharedContext.deleteObject(picture)
        }
        
        selectedIndexes = [NSIndexPath]()
        
        dispatch_async(dispatch_get_main_queue()) {
            CoreDataStackManager.sharedInstance().saveContext()
        }
        
        updateBottomButton()
        
    }

    
    func updateBottomButton() {
        if selectedIndexes.count > 0 {
            bottomButton.title = "Remove Selected Pictures"
        } else {
            bottomButton.title = "New Collection"
        }
    }
    
    func alert(text:String) {
        let alertView = UIAlertView()
        alertView.message = text
        alertView.addButtonWithTitle("Ok")
        alertView.show()
    }
    
    func zoom(mapCoord : CLLocationCoordinate2D) {
        var mapCamera = MKMapCamera(lookingAtCenterCoordinate: mapCoord, fromEyeCoordinate: mapCoord, eyeAltitude: 1000)
        mapView.setCamera(mapCamera, animated: false)
    }
    
    func configureCell(cell: PhotoAlbumCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        var finalImage = UIImage()
        
        if imageCount > 0 && self.bottomButton.enabled == true {
            self.bottomButton.enabled = false
        }
        
        let picture = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Picture
        self.imageCount++
        cell.imageView!.image = nil
        
        if picture.photoComputed != nil {
            cell.activityView.stopAnimating()
            finalImage = picture.photoComputed!
            self.imageCount--
            if self.imageCount == 0 {
                self.bottomButton.enabled = true
            }
        } else {
            cell.activityView.startAnimating()
            let task = FlickrClient.sharedInstance().taskForImage(FlickrClient.sharedInstance().flickrImageURL(picture), completionHandler: { (imageData, error) -> Void in
                if let error = error {
                    println("Error in taskforImage() : \(error.localizedDescription)")
                }
                
                if let data = imageData {
                    let image = UIImage(data: data)
                    
                    picture.photoComputed = image
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.imageCount--
                        if self.imageCount == 0 {
                            self.bottomButton.enabled = true
                        }
                        cell.imageView.image = image
                        cell.activityView.stopAnimating()
                    })
                    
                }
            })
            cell.taskToCancelifCellIsReused = task
        }
        
        cell.imageView!.image = finalImage
        
        if let index = find(self.selectedIndexes, indexPath) {
            cell.imageView!.alpha = 0.5
        } else {
            cell.imageView!.alpha = 1.0
        }
    }
    
    //MARK: - Collection View Delegate
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoAlbumCollectionViewCell", forIndexPath: indexPath) as! PhotoAlbumCollectionViewCell
        self.configureCell(cell, atIndexPath: indexPath)

        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if imageCount == 0 {
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoAlbumCollectionViewCell
            
            // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
            if let index = find(selectedIndexes, indexPath) {
                selectedIndexes.removeAtIndex(index)
            } else {
                selectedIndexes.append(indexPath)
            }
            
            cell.activityView.hidden = true
            // Then reconfigure the cell
            configureCell(cell, atIndexPath: indexPath)
            
            
            // And update the buttom button
            updateBottomButton()
        }
       

    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        println("in controllerWillChangeContent")
    }

    //MARK: - NSFetchedResultsController Delegate
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            break
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        println("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        pictureCollection.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.pictureCollection.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.pictureCollection.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.pictureCollection.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }

    
    //MARK: - Core Data

    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Picture")
        
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
        
        }()

    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
        }()
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    


}