//
//  MapViewController.swift
//  TFARDirection
//
//  Created by 薛文龙 on 2018/4/4.
//  Copyright © 2018年 com.delianac. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, CLLocationManagerDelegate,MKMapViewDelegate{
    fileprivate lazy var locationManager:CLLocationManager = CLLocationManager()
    fileprivate var currentLocation:CLLocation?
    fileprivate var toLocation:CLLocation?
    fileprivate var toAnnotation:MKPointAnnotation?
    fileprivate var routePolyline:MKPolyline!
    
    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        initLocationManager()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initLocationManager() {
        if (CLLocationManager.locationServicesEnabled())
        {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
            self.mapView.showsUserLocation = true
            self.mapView.userTrackingMode = .followWithHeading;
            self.mapView.delegate = self
        }
        let uilgr = UILongPressGestureRecognizer(target: self, action: #selector(self.addAnnotationOnMap(_:)))
        uilgr.minimumPressDuration = 2.0
        self.view.addGestureRecognizer(uilgr)
    }
    
    @objc func addAnnotationOnMap(_ gestureRecognizer:UIGestureRecognizer){
        if gestureRecognizer.state == UIGestureRecognizerState.began {
            let touchPoint = gestureRecognizer.location(in: self.mapView)
            let newCoordinates = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            
            let location = CLLocation(latitude: newCoordinates.latitude, longitude: newCoordinates.longitude)
            
            CLGeocoder().reverseGeocodeLocation(location, completionHandler: {[weak self] (placemarks, error) -> Void in
                if error != nil {
                    print("Reverse geocoder failed with error" + (error?.localizedDescription)!)
                    return
                }
                annotation.title = "Unknown Place"
                if let toAnnotation = self?.toAnnotation {
                    self?.mapView.removeAnnotation(toAnnotation)
                }
                self?.toAnnotation = annotation
                self?.mapView.addAnnotation(annotation)
                
                self?.toLocation = location
                self?.direction(to: location)
            })
        }
    }
    
    func getUserLocation() -> CLLocation {
        return CLLocation(latitude: self.mapView.userLocation.coordinate.latitude, longitude: self.mapView.userLocation.coordinate.longitude)
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let regionRadius: CLLocationDistance = 300
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
                                                                  regionRadius, regionRadius)
        
        mapView.setRegion(coordinateRegion, animated: true)
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.fillColor = UIColor.black.withAlphaComponent(0.5)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 2
            return renderer
            
        } else if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.orange
            renderer.lineWidth = 3
            return renderer
        }
        
        return MKOverlayRenderer()
    }
    
    
    func direction(to:CLLocation){
        
        self.mapView.removeOverlays(self.mapView.overlays)
        let request = MKDirectionsRequest()
        request.source = MKMapItem.forCurrentLocation()
        let locationPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2DMake(to.coordinate.latitude, to.coordinate.longitude), addressDictionary: nil)
        request.destination = MKMapItem(placemark: locationPlacemark)
        request.transportType = MKDirectionsTransportType.any
        request.requestsAlternateRoutes = true
        let directions = MKDirections(request: request)
        directions.calculate { (response, error) in
            guard let response = response else {
                return;
            }
            let myRoute = response.routes[0]
            self.routePolyline = myRoute.polyline
            //self.addAnnotations()
            self.mapView.add(myRoute.polyline)
        }
        
    }
    
    
}
