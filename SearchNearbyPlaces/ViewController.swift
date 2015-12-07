//
//  ViewController.swift
//  SearchNearbyPlaces
//
//  Created by HYUBYN on 12/4/15.
//  Copyright © 2015 hyubyn. All rights reserved.
//

import UIKit
import GoogleMaps
import Alamofire
import ObjectMapper

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UITextFieldDelegate{

    var listResults = [GooglePlaceObject]()
    var locationManager: CLLocationManager!
    var radius: Float!
    var nextPage: String?
    @IBOutlet weak var tableResults: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var txtRadius: UITextField!
    @IBOutlet weak var btnUpdateRadius: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        initLocationManager()
        radius = (txtRadius.text! as NSString).floatValue
        searchBar.delegate = self
        txtRadius.delegate = self
    }

    // init locationmanager
    func initLocationManager(){
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        let position = locationManager.location?.coordinate
        NSLog("\(position)")
       // locationManager.delegate = self
    }
    
    // Handle Table view
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        let cell = UITableViewCell()
        let object: GooglePlaceObject = listResults[indexPath.row]
        cell.textLabel?.text = "\(indexPath.row + 1)." + object.serialize()
        cell.textLabel?.numberOfLines = 4;
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listResults.count
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 120.0
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if (indexPath.row == listResults.count - 1) {
            NSLog("...start fetching more items.");
            if self.nextPage != nil{
                NSLog(self.nextPage!)
                self.searchForNextPage()
            }
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let detailObject = listResults[indexPath.row]
        var url = "https://maps.googleapis.com/maps/api/place/details/json?reference=\(detailObject.reference_)&key=AIzaSyAwlYQGG1bHRo6YNj3xMyOMGmHg5E0cvNo"
        url = url.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        Alamofire.request(.GET, url)
            .responseJSON { response in
                if let JSON = response.result.value{
                    if let object: NSDictionary = JSON["result"] as? NSDictionary{
                        let objectForDisplay = Mapper<GooglePlaceObject>().map(object)
                        objectForDisplay?.calculateDistance((self.locationManager.location?.coordinate)!)
                        objectForDisplay?.photoReference_ = detailObject.photoReference_
                        let detailView = self.storyboard?.instantiateViewControllerWithIdentifier("detailView") as! DetailViewController
                        detailView.setDetailObject(objectForDisplay!)
                        self.navigationController?.pushViewController(detailView, animated: true)
                    }
                }
        }
        
    }
    
            
    // Handle textfield
    @IBAction func changeRadius(sender: AnyObject) {
        let newRadius = (txtRadius.text! as NSString).floatValue
        if 1 > newRadius || newRadius > 50000{
            let alert = UIAlertController(title: "Error", message: "Radius must be between 1 and 50000", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            txtRadius.text = "\(radius)"
        }
        else{
            radius = newRadius
            let alert = UIAlertController(title: "Success", message: "Radius has been updated to value \(newRadius)", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            NSLog("\(radius)")
        }
        txtRadius.resignFirstResponder()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        changeRadius(self)
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        var result = true
        let prospectiveText = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
        if textField == txtRadius{
        if string.characters.count > 0{
            let disallowedCharacterSet = NSCharacterSet(charactersInString: "0123456789.").invertedSet
            let replacementStringIsLegal = string.rangeOfCharacterFromSet(disallowedCharacterSet) == nil
            
            let resultingStringLengthIsLegal = prospectiveText.characters.count <= 9
            
            let scanner = NSScanner(string: prospectiveText)
            let resultingTextIsNumeric = scanner.scanDecimal(nil) && scanner.atEnd
            
            result = replacementStringIsLegal &&
                resultingStringLengthIsLegal &&
            resultingTextIsNumeric
            }
        }
        return result
    }
    
    // Handle Search
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if searchBar == self.searchBar{
            listResults.removeAll()
            let placeName = searchBar.text
            var url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location="
            if let locations =  locationManager.location{
                let location = "\(locations.coordinate.latitude),\(locations.coordinate.longitude)"
                url = url + location
            }
            url = url  + "&radius=\(radius)"
            url += "&name=\(placeName!)&key=AIzaSyAwlYQGG1bHRo6YNj3xMyOMGmHg5E0cvNo"
            url = url.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
            Alamofire.request(.GET, url)
                .responseJSON { response in
                    if let JSON = response.result.value ,let results: NSArray = JSON["results"] as? NSArray{
                            if results.count == 0 {
                                let alert = UIAlertController(title: "No Place Found", message: "No Place's Name matching that Name, try another Name", preferredStyle: UIAlertControllerStyle.Alert)
                                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                                self.presentViewController(alert, animated: true, completion: nil)
                                return
                            }
                            for object in results as! [NSDictionary]{
                                let newObject = Mapper<GooglePlaceObject>().map(object)
                                newObject?.calculateDistance((self.locationManager.location?.coordinate)!)
                                self.listResults.append(newObject!)
                            }
                       
                        dispatch_async(dispatch_get_main_queue(), {
                            self.tableResults.reloadData()
                        })
                        self.nextPage = JSON["next_page_token"] as? String
                    }
            }
        }
        searchBar.resignFirstResponder()
        
    }
    
    func searchForNextPage(){
        var nextPageToken : String?
        let location =  "\(locationManager.location!.coordinate.latitude), \(locationManager.location!.coordinate.longitude)"
        var url = "https://maps.googleapis.com/maps/api/place/search/json?location=" + location + "&radius=\(radius!)&name=\(searchBar.text!)&hasNextPage=true&nextPage()=true&sensor=false&key=AIzaSyAwlYQGG1bHRo6YNj3xMyOMGmHg5E0cvNo&pagetoken=\(nextPage!)"
        url = url.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        Alamofire.request(.GET, url)
            .responseJSON { response in
                if let JSON = response.result.value {
                    if let results: NSArray = JSON["results"] as? NSArray{
                        for object in results as! [NSDictionary]{
                            let newObject = Mapper<GooglePlaceObject>().map(object)
                            newObject?.calculateDistance(self.locationManager.location!.coordinate)
                            self.listResults.append(newObject!)
                        }
                    }
                    dispatch_async(dispatch_get_main_queue(), {
                        self.tableResults.reloadData()
                    })
                    nextPageToken = JSON["next_page_token"] as? String
                    if nextPageToken != nil{
                        self.nextPage = nextPageToken
                    }
                    else{
                        self.nextPage = nil
                    }
                }
        }
        
        
    }
}

