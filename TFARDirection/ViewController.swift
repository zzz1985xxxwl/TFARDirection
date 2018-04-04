//
//  ViewController.swift
//  TFARDirection
//
//  Created by 薛文龙 on 2018/4/4.
//  Copyright © 2018年 com.delianac. All rights reserved.
//

import UIKit
import ARKit
import MapKit
import MapboxARKit
import Turf


class ViewController: UIViewController {
    fileprivate lazy var locationManager:CLLocationManager = CLLocationManager()
    fileprivate var annotationManager:AnnotationManager?
    fileprivate var currentLocation:CLLocation?
    fileprivate var toLocation:CLLocation?
    fileprivate var toAnnotation:MKPointAnnotation?
    
    
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initLocationManager()
        self.initScene()
        self.initAnnotationManager()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        sceneView.session.pause()
    }
}

extension ViewController {
    func initScene(){
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin]
        sceneView.scene = SCNScene()
        startSession()
    }
    
    func startSession(){
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
    }
    
    @IBAction func buttonDidTapped(_ sender: Any) {
        self.resetSession()
    }
    
    func resetSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        sceneView.session.run(configuration,  options: .resetTracking)
        
    }
    
    func addAnnotations(polyline:MKPolyline){
        self.annotationManager?.originLocation = getUserLocation()
        self.annotationManager?.removeAllAnnotations()
        
        let turfPolyline = Polyline(polyline.coordinates)
        let metersPerNode: CLLocationDistance = 2
        var annotationsToAdd:[Annotation] = []
        
        // Walk the route line and add a small AR node and map view annotation every metersPerNode
        for i in stride(from: metersPerNode, to: turfPolyline.distance() - metersPerNode, by: metersPerNode) {
            // Use Turf to find the coordinate of each incremented distance along the polyline
            if let nextCoordinate = turfPolyline.coordinateFromStart(distance: i) {
                let interpolatedStepLocation = CLLocation(latitude: nextCoordinate.latitude, longitude: nextCoordinate.longitude)
                
                // Add an AR node
                let annotation = Annotation(location: interpolatedStepLocation, calloutImage: nil)
                annotationsToAdd.append(annotation)
            }
        }
        
        // Update the annotation manager with the latest AR annotations
        self.annotationManager?.addAnnotations(annotations: annotationsToAdd)
    }
}

extension ViewController:AnnotationManagerDelegate{
    func initAnnotationManager(){
        annotationManager = AnnotationManager(sceneView: sceneView)
        annotationManager!.delegate = self
        
    }
}

extension ViewController: CLLocationManagerDelegate,MKMapViewDelegate{
    
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let nowCurrentLocation = self.getUserLocation()
        if let currentLocation = self.currentLocation {
            var polyline = Polyline([currentLocation.coordinate,nowCurrentLocation.coordinate])
            if(self.mapView.overlays.count > 0 && polyline.distance() > 5) {
                self.direction(to: self.toLocation!)
            }
        }
        self.currentLocation = nowCurrentLocation
        self.label.text = "\(nowCurrentLocation.coordinate.latitude) , \(nowCurrentLocation.coordinate.longitude)"
        self.centerMapOnLocation(location: self.currentLocation!)
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
            self.addAnnotations(polyline: myRoute.polyline)
            self.mapView.add(myRoute.polyline)
        }
        
    }
}



