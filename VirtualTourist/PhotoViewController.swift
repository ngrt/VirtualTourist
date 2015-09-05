//
//  PhotoViewController.swift
//  
//
//  Created by Nawfal on 02/09/2015.
//
//

import UIKit
import MapKit

class PhotoViewController: UIViewController {

    var pin = MKPointAnnotation()

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let coordinate = CLLocationCoordinate2DMake(28.1461248, -82.75676799999999)
        
        zoom(coordinate)
        
        var annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        self.mapView.addAnnotation(annotation)
        
        Flickr.sharedInstance().getImageFromFlickr()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func requestSnapshotData(mapView: MKMapView, completion: (data: NSData!, error: NSError!) -> ()) {
        let options = MKMapSnapshotOptions()
        options.region = mapView.region
        options.size = mapView.frame.size
        options.scale = UIScreen.mainScreen().scale
        
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.startWithCompletionHandler() {
            snapshot, error in
            
            if error != nil {
                completion(data: nil, error: error)
                return
            }
            
            let image = snapshot.image
            let data = UIImagePNGRepresentation(image)
            completion(data: data, error: nil)
        }
    }
    
    func zoom(mapCoord : CLLocationCoordinate2D) {
        var mapCamera = MKMapCamera(lookingAtCenterCoordinate: mapCoord, fromEyeCoordinate: mapCoord, eyeAltitude: 1000)
        mapView.setCamera(mapCamera, animated: false)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
