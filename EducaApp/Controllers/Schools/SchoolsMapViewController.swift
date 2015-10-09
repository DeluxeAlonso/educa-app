//
//  SchoolsMapViewController.swift
//  EducaApp
//
//  Created by Alonso on 10/8/15.
//  Copyright © 2015 Alonso. All rights reserved.
//

import UIKit
import UIKit

enum SchoolMarkerType {
  
  case SchoolPoint
  case VolunteerPoint
  
  func markerTitle() -> String {
    switch self {
    case .SchoolPoint:
      return "Colegio"
    default:
      return "Voluntario"
    }
  }
  
  func markerColor() -> UIColor {
    switch self {
    case .SchoolPoint:
      return UIColor.blueColor()
    default:
      return UIColor.redColor()
    }
  }
  
}

class SchoolsMapViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate{

  @IBOutlet weak var mapView: GMSMapView!
  @IBOutlet weak var mapInfoView: UIView!
  @IBOutlet weak var mapInfoLabel: UILabel!
  @IBOutlet weak var mapInfoViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var mapRouteButton: UIButton!
  
  let locationManager = CLLocationManager()
  
  var initialHeightConstant: CGFloat?
  
  var currentLocation: CLLocationCoordinate2D?
  var targetLocation: CLLocationCoordinate2D?
  
  var polyline: GMSPolyline?
  
  var currentMarker: CustomMapMarker?
  
  var isSaved = true
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupElements()
    getReunionPoints()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  // MARK: - Private
  
  private func setupElements() {
    setupLocation()
    setupNavigationBar()
    setupInfoView()
    setupAdditionalConstraints()
  }
  
  private func setupLocation() {
    mapView.delegate = self
    locationManager.delegate = self
    locationManager.requestWhenInUseAuthorization()
  }
  
  func setupNavigationBar() {
    UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: false)
    view.backgroundColor = UIColor.defaultBackgroundColor()
    navigationController?.navigationBar.barTintColor = UIColor.defaultTextColor()
    navigationController?.navigationBar.tintColor = UIColor.whiteColor()
    navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
  }
  
  private func setupInfoView() {
    mapInfoView.setShadowBorder()
    mapRouteButton.setShadowBorder()
  }
  
  private func setupAdditionalConstraints() {
    initialHeightConstant = mapInfoViewHeightConstraint.constant
    mapInfoViewHeightConstraint.constant = 0
  }
  
  private func getReunionPoints() {
    for i in 0..<Int((Constants.MockData.ReunionPoints.count)) {
      addMarkerWithTitle(SchoolMarkerType.SchoolPoint.markerTitle(), color: SchoolMarkerType.SchoolPoint.markerColor(), type: SchoolMarkerType.SchoolPoint.hashValue, coordinate: Constants.MockData.ReunionPoints[i])
      addMarkerWithTitle(SchoolMarkerType.VolunteerPoint.markerTitle(), color: SchoolMarkerType.VolunteerPoint.markerColor(), type: SchoolMarkerType.VolunteerPoint.hashValue, coordinate: Constants.MockData.VolunteerPoints[i])
    }
  }
  
  private func reverseGeocodeCoordinate(coordinate: CLLocationCoordinate2D) {
    clearMap()
    let geocoder = GMSGeocoder()
    targetLocation = coordinate
    geocoder.reverseGeocodeCoordinate(coordinate, completionHandler: { (response, error) in
      guard let address = response?.firstResult() else {
        return
      }
      let lines: [String] = address.lines as! [String]
      self.mapInfoLabel.text = lines.joinWithSeparator("\n")
    })
    UIView.animateWithDuration(0.25, animations: {
      self.view.layoutIfNeeded()
    })
  }
  
  private func addMarkerWithTitle(title: String, color: UIColor, type: Int, coordinate: CLLocationCoordinate2D) {
    let marker = CustomMapMarker(position: coordinate)
    currentMarker = marker
    marker.title = title
    marker.type = type
    marker.icon = CustomMapMarker.markerImageWithColor(color)
    marker.appearAnimation = kGMSMarkerAnimationPop
    marker.map = mapView
    mapView.selectedMarker = marker
  }
  
  private func showMapInfoView() {
    let viewHeight = initialHeightConstant
    view.layoutIfNeeded()
    mapInfoViewHeightConstraint.constant = initialHeightConstant!
    UIView.animateWithDuration(0.25, animations: {
      self.view.layoutIfNeeded()
      self.mapView.padding = UIEdgeInsets(top: self.topLayoutGuide.length, left: 0,
        bottom: viewHeight!, right: 0)
    })
  }
  
  private func hideMapInfoView() {
    view.layoutIfNeeded()
    mapInfoViewHeightConstraint.constant = 0
    UIView.animateWithDuration(0.25, animations: {
      self.view.layoutIfNeeded()
      self.mapView.padding = UIEdgeInsets(top: self.topLayoutGuide.length, left: 0,
        bottom: self.bottomLayoutGuide.length, right: 0)
    })
  }
  
  private func clearMap() {
    polyline?.map = nil
  }
  
  // MARK: - Actions
  
  @IBAction func drawRoute(sender: AnyObject) {
    let path = GMSMutablePath()
    path.addCoordinate(currentLocation!)
    path.addCoordinate(targetLocation!)
    polyline = GMSPolyline(path: path)
    polyline!.strokeWidth = 5.0
    polyline!.geodesic = true
    polyline?.map = mapView
  }
  
  @IBAction func dimissMapView(sender: AnyObject) {
    dismissViewControllerAnimated(true, completion: nil)
  }
  // MARK: - CLLocationManagerDelegate
  
  func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    guard status == .AuthorizedWhenInUse else {
      return
    }
    locationManager.startUpdatingLocation()
    mapView.myLocationEnabled = true
    mapView.settings.compassButton = true
    mapView.settings.myLocationButton = true
  }
  
  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.first as CLLocation? else {
      return
    }
    currentLocation = location.coordinate
    mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 11, bearing: 0, viewingAngle: 0)
    locationManager.stopUpdatingLocation()
  }
  
  // MARK: - GMSMapViewDelegate
  
  func mapView(mapView: GMSMapView!, didTapMarker marker: GMSMarker!) -> Bool {
    currentMarker = marker as? CustomMapMarker
    mapView.selectedMarker = marker
    let coordinate = marker.position
    showMapInfoView()
    reverseGeocodeCoordinate(coordinate)
    return true
  }
  
  func mapView(mapView: GMSMapView!, didTapAtCoordinate coordinate: CLLocationCoordinate2D) {
    clearMap()
    hideMapInfoView()
  }

}
