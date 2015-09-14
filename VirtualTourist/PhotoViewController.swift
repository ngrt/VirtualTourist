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
    
    var pictures = [Picture]()
    
    var pin: Pin!
    
    var noPictures = false
    
    
    var selectedIndexes = [NSIndexPath]()
    
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!

    
    
    @IBOutlet weak var pictureCollection: UICollectionView!
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    
    @IBOutlet weak var noPictureLabel: UILabel!
    
    //MARK: - Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pictureCollection.reloadData()
        
        fetchedResultsController.performFetch(nil)
        fetchedResultsController.delegate = self
        
        updateBottomButton()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        let coordinate = CLLocationCoordinate2DMake(self.pin.latitude, self.pin.longitude)
        
        zoom(coordinate)
        
        var annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        self.mapView.addAnnotation(annotation)
        
        if noPictures {
            pictureCollection.hidden = true
            noPictureLabel.hidden = false
            return
        }
        
        if pin.pictures.isEmpty {
            println("Pin is empty")
            FlickrClient.sharedInstance().getImageFromFlickr(pin.latitude, lon: pin.longitude, completionHandler: { (picturesUrlString, error) -> Void in
                if let error = error {
                    println(error)
                } else {
                    self.pictures = picturesUrlString!.map() { (url : String) -> Picture in
                        let picture = Picture(imageURL: url, context: self.sharedContext)
                        
                        picture.pin = self.pin
                        
                        return picture
                    }
                    
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.pictureCollection.reloadData()
                    }
                    
                    // Save the context
                    self.saveContext()
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
        FlickrClient.sharedInstance().getImageFromFlickr(pin.latitude, lon: pin.longitude, completionHandler: { (picturesUrlString, error) -> Void in
            if let error = error {
                println(error)
            } else {
                self.pictures = picturesUrlString!.map() { (url : String) -> Picture in
                    let picture = Picture(imageURL: url, context: self.sharedContext)
                    
                    picture.pin = self.pin
                    
                    return picture
                }
                
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.pictureCollection.reloadData()
                }
                
                // Save the context
                self.saveContext()
            }
            
        })

        
    }
    
    // Delete all images in photos array
    func deleteAllPictures() {
        for picture in self.pictures {
            self.sharedContext.deleteObject(picture)
        }
        self.pictures = [Picture]()
        var error:NSError? = nil
        
        self.sharedContext.save(&error)
        
        if let error = error {
            println("error saving context: \(error.localizedDescription)")
            self.alert("Error saving deletes")
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
        
        self.saveContext()
        
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
        self.bottomButton.enabled = false
        cell.activityView.hidesWhenStopped = true
        
        var finalImage: UIImage!
        
        let picture = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Picture
        
        if picture.photoComputed != nil {
            finalImage = picture.photoComputed
            cell.imageView!.image = finalImage
            self.bottomButton.enabled = true
        } else {
            cell.imageView!.image = UIImage(named: "defaultPicture")
            cell.activityView.startAnimating()
            
            
            
            dispatch_async(dispatch_get_main_queue()) {
                let imageURL = NSURL(string: picture.imageURL)
                let imageData = NSData(contentsOfURL: imageURL!)
                finalImage = UIImage(data: imageData!)
                //get image
                cell.activityView.stopAnimating()
                cell.imageView!.image = finalImage
                picture.photoComputed = finalImage
                self.bottomButton.enabled = true
            }
            

            
            // save in core data
            var error:NSError? = nil
            self.sharedContext.save(&error)
            
            if let error = error {
                println("error saving context: \(error.localizedDescription)")
                self.alert("Error saving image")
            }
        
        }
        
        
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
        
        
//        dispatch_async(dispatch_get_main_queue()) {
//            self.pictureCollection.reloadItemsAtIndexPaths([indexPath])
//        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoAlbumCollectionViewCell
        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = find(selectedIndexes, indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        
        // Then reconfigure the cell
        configureCell(cell, atIndexPath: indexPath)
        
        // And update the buttom button
        updateBottomButton()

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
            println("Move an item. We don't expect to see this in this app.")
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