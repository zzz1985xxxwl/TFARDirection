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
    fileprivate var routePolyline:MKPolyline!
    
    
    
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
        self.addAnnotations()
    }
    
    func addAnnotations(){
        let polyline = self.routePolyline
        self.annotationManager?.originLocation = getUserLocation()
        self.annotationManager?.removeAllAnnotations()
        
        let turfPolyline = Polyline(polyline!.coordinates)
        let metersPerNode: CLLocationDistance = 2
        var annotationsToAdd:[Annotation] = []
        var totalShowCount = 20
        var index = 0
        // Walk the route line and add a small AR node and map view annotation every metersPerNode
        for i in stride(from: metersPerNode, to: turfPolyline.distance() - metersPerNode, by: metersPerNode) {
            // Use Turf to find the coordinate of each incremented distance along the polyline
            if let nextCoordinate = turfPolyline.coordinateFromStart(distance: i) {
                let interpolatedStepLocation = CLLocation(latitude: nextCoordinate.latitude, longitude: nextCoordinate.longitude)
                if(self.distanceFromCurrent(to: interpolatedStepLocation) < 500){
                    // Add an AR node
                    let annotation = Annotation(location: interpolatedStepLocation, calloutImage: nil)
                    annotation.index = index
                    if index < totalShowCount {
                        annotationsToAdd.append(annotation)
                    }
                    index = index + 1
                }
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
    
    func node(for annotation: Annotation) -> SCNNode? {
        let color = UIColor(red: 0, green:1, blue: 0, alpha: 1)
        let minAlpha:CGFloat = 0.3
        let maxIndex = 10
        var firstColor = color.withAlphaComponent(minAlpha)
        if let index = annotation.index {
            if index < maxIndex {
                firstColor = color.withAlphaComponent(1.0 - (1.0 - minAlpha)/10.0 * CGFloat(index))
            }
        }
        return createSphereNode(with: 0.5, firstColor: firstColor, secondColor: UIColor.green)
    }
    
    func createSphereNode(with radius: CGFloat, firstColor: UIColor, secondColor: UIColor) -> SCNNode {
        let geometry = SCNSphere(radius: radius)
        geometry.firstMaterial?.diffuse.contents = firstColor
        
        let sphereNode = SCNNode(geometry: geometry)
        return sphereNode
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
    
    func distanceFromCurrent(to:CLLocation) -> Double {
        if let currentLocation = self.currentLocation {
            let polyline = Polyline([currentLocation.coordinate,to.coordinate])
            return  polyline.distance()
        }
        return 10000.0
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let nowCurrentLocation = self.getUserLocation()
        if let currentLocation = self.currentLocation {
            var polyline = Polyline([currentLocation.coordinate,nowCurrentLocation.coordinate])
            if(self.mapView.overlays.count > 0 && distanceFromCurrent(to:nowCurrentLocation) > 10) {
                self.addAnnotations()
                self.label.text = "renew"
            }
        }
        self.currentLocation = nowCurrentLocation
        //self.label.text = "\(nowCurrentLocation.coordinate.latitude) , \(nowCurrentLocation.coordinate.longitude)"
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
            self.routePolyline = myRoute.polyline
            self.addAnnotations()
            self.mapView.add(myRoute.polyline)
        }
        
    }
}



