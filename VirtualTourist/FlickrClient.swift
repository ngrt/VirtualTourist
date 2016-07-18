//
//  Flickr.swift
//  
//
//  Created by Nawfal on 03/09/2015.
//
//

import UIKit



class FlickrClient: NSObject {
    
//    struct Parameters {
//        static let BASE_URL = "https://api.flickr.com/services/rest/"
//        static let METHOD_NAME = "flickr.photos.search"
//        static let API_KEY = "a31722c6b387e2068d964df76774a2e8"
//        static let EXTRAS = "url_m"
//        static let SAFE_SEARCH = "1"
//        static let DATA_FORMAT = "json"
//        static let NO_JSON_CALLBACK = "1"
//    }
    
    var apiKey = "a31722c6b387e2068d964df76774a2e8"
    
    var session: NSURLSession
    
    typealias CompletionHander = (result: AnyObject!, error: NSError?) -> Void
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    private func flickrSearchURLForPlaceID(lat: Double, lon: Double, page: Int) -> NSURL {
        let URLString = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&lat=\(lat)&lon=\(lon)&per_page=21&page=\(page)&format=json&nojsoncallback=1"
        return NSURL(string: URLString)!
    }
    
    func flickrGeoSearch(lat: Double, lon: Double, page: Int, completionHandler: CompletionHander) -> NSURLSessionDataTask {
        let url = flickrSearchURLForPlaceID(lat, lon: lon, page: page)
        let request = NSURLRequest(URL: url)
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let _ = downloadError {
                completionHandler(result: nil, error: downloadError)
            } else {
                FlickrClient.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        }
        task.resume()
        return task
    }
    
    func taskForImage(url: NSURL, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
        
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
                print("Error in taskForImageWithSize : \(error)")
                completionHandler(imageData: nil, error: error)
            } else {
                completionHandler(imageData: data, error: nil)
            }
        }
        
        task.resume()
        
        return task
    }
    
    // The URL for a flickrImage, using the data a photo entity saves.
    func flickrImageURL(picture: Picture) -> NSURL {
		
		//add "s" to http to correct security protocol error
		return NSURL(string: "https://farm\(picture.farm).staticflickr.com/\(picture.server)/\(picture.id)_\(picture.secret)_m.jpg")!
    }

    
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: CompletionHander) {
        var parsingError: NSError? = nil
        let parsedResult: AnyObject?
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
        }
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            completionHandler(result: parsedResult, error: nil)
        }
    }
    

    

    // MARK: - Shared Instance
    
    class func sharedInstance() -> FlickrClient {
        
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        
        return Singleton.sharedInstance
    }
    
    struct Caches {
        static let imageCache = ImageCache()
    }

}
