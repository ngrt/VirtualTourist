//
//  Flickr.swift
//  
//
//  Created by Nawfal on 03/09/2015.
//
//

import UIKit

let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search"
let API_KEY = "a31722c6b387e2068d964df76774a2e8"
let EXTRAS = "url_m"
let SAFE_SEARCH = "1"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"

class Flickr: NSObject {
    
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }

    
    func getImageFromFlickr() {
        println("getImageFromFlickr lancée")
        let parameters = [
            "method" : METHOD_NAME,
            "api_key" : API_KEY,
            "bbox" : formatBbox(),
            "safe_search" : SAFE_SEARCH,
            "extras" : EXTRAS,
            "format" : DATA_FORMAT,
            "nojsoncallback" : NO_JSON_CALLBACK,
            "per_page" : "21"
        ]
        
        let urlString = BASE_URL + Flickr.escapedParameters(parameters)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        println(urlString)
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, downloadError) -> Void in
            if let error = downloadError {
                println("Could not complete the request : \(error)")
            } else {
                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                if let photosDictionary = parsedResult["photos"] as? [String: AnyObject] {
                    if let totalPages = photosDictionary["pages"] as? Int {
                        let pageLimit = min(totalPages, 40)
                        let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                        self.getImageFromFlickrBySearchWithPage(parameters, pageNumber: randomPage)
                        
                    }
                }
            }
            
        })
        
        task.resume()
    }
    
    func getImageFromFlickrBySearchWithPage(parameters: [String: AnyObject], pageNumber: Int) {
        var photoURLArray =  [String]()
        
        var withPageDictionary = parameters
        withPageDictionary["page"] = pageNumber
        
        let urlString = BASE_URL + Flickr.escapedParameters(withPageDictionary)
        let url = NSURL(string: urlString)!
        println(urlString)
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, downloadError) -> Void in
            if let error = downloadError {
                println("Could not complete the request : \(error)")
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
                            println(photoURLArray)
                            println(photoURLArray.count)
                        }
                    }
                    
                }
            }
        })
        
        task.resume()
    }
    
    func formatBbox() -> String {
        
        return "0,0,0,0"
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
    
    class func sharedInstance() -> Flickr {
        
        struct Singleton {
            static var sharedInstance = Flickr()
        }
        
        return Singleton.sharedInstance
    }

}
