//
//  Flickr.swift
//  
//
//  Created by Nawfal on 03/09/2015.
//
//

import UIKit



class FlickrClient: NSObject {
    
    struct Parameters {
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        static let METHOD_NAME = "flickr.photos.search"
        static let API_KEY = "a31722c6b387e2068d964df76774a2e8"
        static let EXTRAS = "url_m"
        static let SAFE_SEARCH = "1"
        static let DATA_FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
    }
    
    
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    func getImageFromFlickr(lat : Double, lon : Double, completionHandler: (picturesUrlString: [String]?, error: NSError?) ->  Void) -> NSURLSessionTask {
        println("getImageFromFlickr lancée")
        let parameters = [
            "method" : Parameters.METHOD_NAME,
            "api_key" : Parameters.API_KEY,
            "lat" : String(stringInterpolationSegment: lat),
            "lon" : String(stringInterpolationSegment: lon),
            "safe_search" : Parameters.SAFE_SEARCH,
            "extras" : Parameters.EXTRAS,
            "format" : Parameters.DATA_FORMAT,
            "nojsoncallback" : Parameters.NO_JSON_CALLBACK,
            "per_page" : "21"
        ]
        
        let urlString = Parameters.BASE_URL + FlickrClient.escapedParameters(parameters)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, downloadError) -> Void in
            if let error = downloadError {
                println("Could not complete the request : \(error)")
                completionHandler(picturesUrlString: nil, error: error)
            } else {
                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                if let photosDictionary = parsedResult["photos"] as? [String: AnyObject] {
                    if let totalPages = photosDictionary["pages"] as? Int {
                        let pageLimit = min(totalPages, 40)
                        let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                            self.getImageFromFlickrBySearchWithPage(parameters, pageNumber: randomPage, completionHandler: { (arrayOfphotoString, error) -> Void in
                            completionHandler(picturesUrlString: arrayOfphotoString!, error: nil)
                                println("Array of Flickr photos \(arrayOfphotoString!)")
                        })
                    }
                    
                }
            }
            
        })
        
        task.resume()
        
        return task
    }
    
    func getImageFromFlickrBySearchWithPage(parameters: [String: AnyObject], pageNumber: Int, completionHandler: (arrayOfphotoString: [String]?, error: NSError?) ->  Void) -> NSURLSessionTask {
        var photoURLArray =  [String]()
        
        var withPageDictionary = parameters
        withPageDictionary["page"] = pageNumber
        
        let urlString = Parameters.BASE_URL + FlickrClient.escapedParameters(withPageDictionary)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, downloadError) -> Void in
            if let error = downloadError {
                println("Could not complete the request : \(error)")
                completionHandler(arrayOfphotoString: nil, error: error)
            } else {
                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                if let photosDictionary = parsedResult["photos"] as? [String: AnyObject] {
                    var totalPhotosVal = 0
                    if let totalPhotos = photosDictionary["total"] as? String {
                        totalPhotosVal = (totalPhotos as NSString).integerValue
                    }
                    
                    if totalPhotosVal > 0 {
                        if let photoArray = photosDictionary["photo"] as? [[String:AnyObject]] {
                            for photo in photoArray {
                                if let photoURL = photo["url_m"] as? String {
                                    photoURLArray.append(photoURL)
                                }
                            }
                            completionHandler(arrayOfphotoString: photoURLArray, error: nil)
                        }
                    }
                    
                }
            }
        })
        
        task.resume()
        
        return task
    }
   
    
    // URL Encoding a dictionary into a parameter string
    
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            // Make sure that it is a string value
            let stringValue = "\(value)"
            
            // Escape it
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            // Append it
            
            urlVars += [key + "=" + "\(escapedValue!)"]
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
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
