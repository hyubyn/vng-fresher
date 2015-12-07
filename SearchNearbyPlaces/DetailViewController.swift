//
//  DetailViewController.swift
//  SearchNearbyPlaces
//
//  Created by HYUBYN on 12/6/15.
//  Copyright © 2015 hyubyn. All rights reserved.
//

import UIKit
import Alamofire
import ObjectMapper

class DetailViewController: UIViewController {

    private var detailObject_: GooglePlaceObject!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameLabel.text = "Name: " + detailObject_.name_
        if let phoneNumber = detailObject_.phone_{
            phoneNumberLabel.text = "Phone: \(phoneNumber)"
        }
        else {
            phoneNumberLabel.text = "Phone: Updating"
        }
        
        distanceLabel.text = "Distance: \(detailObject_.distance_)Km"
        
        addressLabel.lineBreakMode = .ByWordWrapping
        addressLabel.numberOfLines = 0
        
        if let address = detailObject_.address_ {
            addressLabel.text = "Address: " + address
        }
        else {
            addressLabel.text = "Address: " + detailObject_.vicinity_
        }
        var url: String
        if let photo = detailObject_.photoReference_{
            url = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=\(photo)&key=AIzaSyAwlYQGG1bHRo6YNj3xMyOMGmHg5E0cvNo"
        }
        else{
            url = detailObject_.icon_
        }
        let stringUrl = NSURL(string: url)
        imageView.sd_setImageWithURL(stringUrl) { (image, error, type, stringUrl) -> Void in
            NSLog("\(error)")
        }
        
    }

    func setDetailObject(detailObject: GooglePlaceObject){
        detailObject_ = detailObject
    }

}
