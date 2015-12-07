//
//  GooglePlaceObject.swift
//  SearchNearbyPlaces
//
//  Created by HYUBYN on 12/4/15.
//  Copyright © 2015 hyubyn. All rights reserved.
//

import ObjectMapper
import GoogleMaps
class GooglePlaceObject: Mappable {

    var lat_: Double!
    var lng_: Double!
    var icon_: String!
    var id_: String!
    var name_: String!
    var placeId_: String!
    var reference_: String!
    var vicinity_: String!
    var distance_: Double!
    var phone_: String?
    var address_: String?
    var photoReference_: String?
    var photos_: NSArray?
    required init?(_ map: Map) {
        
    }
    
    func mapping(map: Map) {
        lat_ <- map["geometry.location.lat"]
        lng_ <- map["geometry.location.lng"]
        icon_ <- map["icon"]
        id_   <- map["id"]
        name_ <- map["name"]
        placeId_ <- map["place_id"]
        reference_ <- map["reference"]
        vicinity_ <- map["vicinity"]
        phone_ <- map["international_phone_number"]
        address_ <- map["formatted_address"]
        photos_ <- map["photos"]
        if let photo: NSDictionary = photos_?[0] as? NSDictionary{
            photoReference_ = photo.objectForKey("photo_reference") as? String
        }
    }
    
    
    func calculateDistance(userCoordinate: CLLocationCoordinate2D) -> Double{
        let point = CLLocation(latitude: lat_, longitude: lng_)
        
        let user = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
        
        distance_ =  user.distanceFromLocation(point) * 0.000621371192 * 1.609
        distance_ = round(distance_ * 1000) / 1000
        return distance_!
    }
    
    func serialize() -> String{
        let result = "\(name_)\n\(vicinity_)\n\(distance_)km"
        return result
    }
}
