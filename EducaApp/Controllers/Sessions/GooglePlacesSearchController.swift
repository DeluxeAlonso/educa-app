//
//  GooglePlacesAutocomplete.swift
//  GooglePlacesAutocomplete
//
//  Created by Howard Wilson on 10/02/2015.
//  Copyright (c) 2015 Howard Wilson. All rights reserved.
//
//
//  Created by Dmitry Shmidt on 6/28/15.
//  Copyright (c) 2015 Dmitry Shmidt. All rights reserved.

import UIKit
import CoreLocation

public enum PlaceType: CustomStringConvertible {
  case All
  case Geocode
  case Address
  case Establishment
  case Regions
  case Cities
  
  public var description : String {
    switch self {
    case .All: return ""
    case .Geocode: return "geocode"
    case .Address: return "address"
    case .Establishment: return "establishment"
    case .Regions: return "(regions)"
    case .Cities: return "(cities)"
    }
  }
}

public typealias GooglePlaceSelectedClosure = (place: PlaceDetails) -> Void

public class Place: NSObject {
  public let id: String
  public let desc: String?
  public let name: String?
  public var apiKey: String?
  
  override public var description: String {
    get { return desc! }
  }
  
  
  public init(id: String, terms: [String]?) {
    self.id = id
    if let terms = terms{
      self.name = terms.first
      var tmpTerms = terms
      if terms.count > 0{
        tmpTerms.removeAtIndex(0)
        self.desc = tmpTerms.joinWithSeparator(",")
      }else{
        self.desc = ""
      }
    }else{
      self.name = ""
      self.desc = ""
    }
  }
  
  convenience public init(prediction: [String: AnyObject], apiKey: String?) {
    
    var terms = [String]()
    
    if let items = prediction["terms"] as? [[String: AnyObject]]{
      for item in items{
        
        if let value = item["value"] as? String{
          terms.append(value)
        }
        
      }
    }
    
    self.init(
      id: prediction["place_id"] as! String,
      terms: terms
    )
    
    self.apiKey = apiKey
  }
  
  public func getDetails(currentText:String, result: PlaceDetails -> ()) {
    GooglePlaceDetailsRequest(place: self).request(currentText, result: result)
  }
  
}

public class PlaceDetails: CustomStringConvertible {
  public let name: String
  public let formattedAddress: String
  public let formattedPhoneNo: String?
  public var currentText: String?
  public let coordinate: CLLocationCoordinate2D
  
  public var streetNumber           = ""
  public var route                  = ""
  public var locality               = ""
  public var subLocality            = ""
  public var administrativeArea     = ""
  public var administrativeAreaCode = ""
  public var subAdministrativeArea  = ""
  public var postalCode             = ""
  public var country                = ""
  public var ISOcountryCode         = ""
  public var state                  = ""
  
  let raw: [String: AnyObject]
  
  init(json: [String: AnyObject]) {
    func component(component: String, inArray array: [[String: AnyObject]], ofType: String) -> String{
      for item in array {
        let types = item["types"] as! [String]
        if let type = types.first{
          if type == component {
            if let value = item[ofType] as! String?{
              return value
            }
          }
        }
      }
      
      return ""
      
    }
    
    let result = json["result"] as! [String: AnyObject]
    
    name = result["name"] as! String
    formattedAddress = result["formatted_address"] as! String
    formattedPhoneNo = result["formatted_phone_number"] as? String
    
    let geometry = result["geometry"] as! [String: AnyObject]
    let location = geometry["location"] as! [String: AnyObject]
    let latitude = location["lat"] as! CLLocationDegrees
    let longitude = location["lng"] as! CLLocationDegrees
    coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    
    let addressComponents = result["address_components"] as! [[String: AnyObject]]
    
    streetNumber = component("street_number", inArray: addressComponents, ofType: "short_name")
    route = component("route", inArray: addressComponents, ofType: "short_name")
    subLocality = component("subLocality", inArray: addressComponents, ofType: "long_name")
    locality = component("locality", inArray: addressComponents, ofType: "long_name")
    postalCode = component("postal_code", inArray: addressComponents, ofType: "long_name")
    administrativeArea = component("administrative_area_level_1", inArray: addressComponents, ofType: "long_name")
    subAdministrativeArea = component("administrative_area_level_2", inArray: addressComponents, ofType: "long_name")
    country = component("country", inArray: addressComponents, ofType: "long_name")
    ISOcountryCode = component("country", inArray: addressComponents, ofType: "short_name")
    
    raw = json
}
  
  public var description: String {
    return "\nPlace: \(name).\nAddress: \(formattedAddress).\ncoordinate: (\(coordinate.latitude), \(coordinate.longitude))\nPhone No.: \(formattedPhoneNo)\n"
  }
  
}

// MARK: - GooglePlacesAutocomplete

public class GooglePlacesSearchController: UISearchController, UISearchBarDelegate {
  
  private var gpaViewController: GooglePlacesAutocompleteContainer!
  
  private var googleSearchBar: UISearchBar?
  
  private var currentText: String?
  
  convenience init(apiKey: String, placeType: PlaceType = .All, currentText:String, controller: SessionMapViewController,searchBar: UISearchBar? = nil, coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid, radius: CLLocationDistance = 0) {
    assert(!apiKey.isEmpty, "Provide your API key")
    let gpaViewController = GooglePlacesAutocompleteContainer(
      apiKey: apiKey,
      placeType: placeType,
      coordinate: coordinate,
      radius: radius,
      currentText:  currentText,
      delegate: controller
    )
    
    self.init(searchResultsController: gpaViewController)
    self.googleSearchBar = searchBar
    self.googleSearchBar?.delegate = self
    self.gpaViewController = gpaViewController
    self.currentText = currentText
    self.searchBar.barTintColor = UIColor.defaultTextColor()
    self.searchBar.text = currentText
    self.searchBar.delegate = self
    self.searchResultsUpdater = gpaViewController
    self.hidesNavigationBarDuringPresentation = false
    self.searchBar.placeholder = "Buscar Ubicación"
  }
  
  override public var searchBar: UISearchBar {
    get {
      return googleSearchBar ?? super.searchBar
    }
  }
  
  public func didSelectGooglePlace(completion : GooglePlaceSelectedClosure) {
    gpaViewController.closure = completion
  }

}

// MARK: - GooglePlacesAutocompleteContainer

public class GooglePlacesAutocompleteContainer: UITableViewController, UISearchResultsUpdating {
  
  var closure: GooglePlaceSelectedClosure?
  private var apiKey: String?
  private var places = [Place]()
  private var placeType: PlaceType = .All
  private var coordinate: CLLocationCoordinate2D = kCLLocationCoordinate2DInvalid
  private var radius: Double = 0.0
  private var currentText: String?
  private var delegate: SessionMapViewController?
  
  
  convenience init(apiKey: String, placeType: PlaceType = .All, coordinate: CLLocationCoordinate2D, radius: Double,currentText: String, delegate: SessionMapViewController) {
    self.init()
    self.apiKey = apiKey
    self.placeType = placeType
    self.coordinate = coordinate
    self.radius = radius
    self.currentText = currentText
    self.delegate = delegate
  }
  
  override public func viewDidLoad() {
    super.viewDidLoad()
    tableView.backgroundColor = UIColor.defaultBackgroundColor()
    tableView.registerClass(GooglePlaceTableViewCell.self, forCellReuseIdentifier: "Cell")
    tableView.estimatedRowHeight = 44.0
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.tableFooterView = UIView()
  }
  
  override public func viewWillDisappear(animated: Bool) {
    super.viewWillAppear(animated)
    delegate?.showLocationSearchBar()
  }
  
}

// MARK: - GooglePlacesAutocompleteContainer

extension GooglePlacesAutocompleteContainer {
  
  override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return places.count
  }
  
  override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! GooglePlaceTableViewCell
    
    let place = self.places[indexPath.row]
    
    // Configure the cell
    cell.nameLabel.text = place.name
    
    cell.addressLabel.text = place.description
    cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
    
    return cell
  }
  
  override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let place = places[indexPath.row]
    place.getDetails(self.currentText!){[unowned self] details in
      self.closure?(place: details)
    }
  }
  
}

// MARK: - GooglePlacesAutocompleteContainer (UISearchBarDelegate)

extension GooglePlacesAutocompleteContainer: UISearchBarDelegate {
  
  public func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
    if searchText.characters.count > 0 {
      self.places = []
    } else {
      getPlaces(searchText)
    }
  }
  
  private func escape(string: String) -> String {
    return (string as NSString).stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
  }
  /**
   Call the Google Places API and update the view with results.
   
   :param: searchString The search query
   */
  private func getPlaces(searchString: String) {
    var params = [
      "input": escape(searchString),
      "types": placeType.description,
      "key": apiKey ?? ""
    ]
    if CLLocationCoordinate2DIsValid(self.coordinate) {
      
      params["location"] = "\(coordinate.latitude),\(coordinate.longitude)"
      if radius > 0{
        params["radius"] = "\(radius)"
      }
    }
    
    GooglePlacesRequestHelpers.doRequest(
      "https://maps.googleapis.com/maps/api/place/autocomplete/json",
      params: params
      ) { json in
        if let predictions = json["predictions"] as? [[String: AnyObject]] {
          self.places = predictions.map { (prediction: [String: AnyObject]) -> Place in
            
            return Place(prediction: prediction, apiKey: self.apiKey)
          }
          
          self.tableView.reloadData()
        }
    }
  }
  
}

extension GooglePlacesAutocompleteContainer {
  
  public func updateSearchResultsForSearchController(searchController: UISearchController) {
    if let searchText = searchController.searchBar.text where searchText.characters.count > 0 {
      currentText = searchText
      getPlaces(searchText)
    }
    else {
      self.places = []
    }
  }
  
}

// MARK: - GooglePlaceDetailsRequest

class GooglePlaceDetailsRequest {
  let place: Place
  
  init(place: Place) {
    self.place = place
  }
  
  func request(currentText: String, result: PlaceDetails -> ()) {
    GooglePlacesRequestHelpers.doRequest(
      "https://maps.googleapis.com/maps/api/place/details/json",
      params: [
        "placeid": place.id,
        "key": place.apiKey ?? ""
      ]
      ) { json in
        let placeDetails = PlaceDetails(json: json as! [String: AnyObject])
        placeDetails.currentText = currentText
        result(placeDetails)
    }
  }
  
}

// MARK: - GooglePlacesRequestHelpers

class GooglePlacesRequestHelpers {

  private class func query(parameters: [String: AnyObject]) -> String {
    var components: [(String, String)] = []
    for key in Array(parameters.keys).sort() {
      let value: AnyObject! = parameters[key]
      components += [(key, "\(value)")]
    }
    
    return components.map{"\($0)=\($1)"}.joinWithSeparator("&")
  }
  
  private class func doRequest(urlString: String, params: [String: String], success: NSDictionary -> ()) {
    if let url = NSURL(string: "\(urlString)?\(query(params))"){
      
      let request = NSMutableURLRequest(
        URL:url
      )
      
      let session = NSURLSession.sharedSession()
      let task = session.dataTaskWithRequest(request) { data, response, error in
        self.handleResponse(data, response: response as? NSHTTPURLResponse, error: error, success: success)
      }
      
      task.resume()
    }
  }
  
  private class func handleResponse(data: NSData!, response: NSHTTPURLResponse!, error: NSError!, success: NSDictionary -> ()) {
    if let error = error {
      print("GooglePlaces Error: \(error.localizedDescription)")
      return
    }
    
    if response == nil {
      print("GooglePlaces Error: No response from API")
      return
    }
    
    if response.statusCode != 200 {
      print("GooglePlaces Error: Invalid status code \(response.statusCode) from API")
      return
    }
    
    let json: NSDictionary?
    do {
      json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary
    }
    catch {
      json = nil
      print("GooglePlaces Error")
      return
    }
    
    if let status = json?["status"] as? String {
      if status != "OK" {
        print("GooglePlaces API Error: \(status)")
        return
      }
    }
    
    // Perform table updates on UI thread
    dispatch_async(dispatch_get_main_queue(), {
      UIApplication.sharedApplication().networkActivityIndicatorVisible = false
      success(json!)
    })
  }

}

private class GooglePlaceTableViewCell: UITableViewCell {
  
  var nameLabel = UILabel()
  var addressLabel = UILabel()
  
  override init(style: UITableViewCellStyle, reuseIdentifier: String!) {
    super.init(style: .Default, reuseIdentifier: reuseIdentifier)
    
    self.selectionStyle = UITableViewCellSelectionStyle.Gray
    self.backgroundColor = UIColor.defaultBackgroundColor()
    
    nameLabel.translatesAutoresizingMaskIntoConstraints = false
    addressLabel.translatesAutoresizingMaskIntoConstraints = false
    
    nameLabel.textColor = UIColor.defaultTextColor()
    nameLabel.backgroundColor = UIColor.defaultBackgroundColor()
    nameLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
    
    addressLabel.textColor = UIColor.defaultSmallTextColor()
    addressLabel.backgroundColor = UIColor.defaultBackgroundColor()
    addressLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
    addressLabel.numberOfLines = 0
    
    contentView.addSubview(nameLabel)
    contentView.addSubview(addressLabel)
    
    let viewsDict = [
      "name" : nameLabel,
      "address" : addressLabel
    ]
    
    contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-[name]-[address]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDict))
    contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[name]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDict))
    contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[address]-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDict))
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
}
