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
    fileprivate var route:MKRoute?
    fileprivate var isDirectioning = false
    fileprivate var tfAnnotationManager:TFAnnotationManager?
    
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.label.text = ""
        UIApplication.shared.isIdleTimerDisabled = true
        widthConstraint.constant = 0
        self.view.layoutIfNeeded()
        self.initSwapPanel()
        self.initLocationManager()
        self.initScene()
        self.initAnnotationManager()
    }
    
    func  initSwapPanel() -> Void {
        let swipeRightGR = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.openPanel))
        let swipeLeftGR = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.closePanel))
        swipeRightGR.direction = UISwipeGestureRecognizerDirection.right
        swipeLeftGR.direction = UISwipeGestureRecognizerDirection.left
        
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(swipeRightGR)
        self.view.addGestureRecognizer(swipeLeftGR)
    }
    
    @objc func openPanel() -> Void {
        if widthConstraint.constant == 0 {
            widthConstraint.constant = 200
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @objc func closePanel() -> Void {
        if widthConstraint.constant > 0 {
            widthConstraint.constant = 0
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @IBAction func centerMap(_ sender: Any) {
        self.centerMapOnLocation(location: self.getUserLocation())
    }
    
    @IBAction func reRoute(_ sender: Any) {
        self.direction(to: self.toLocation!)
    }
    @IBAction func testTransform(_ sender: Any) {
        //let newX = self.sceneView.scene.rootNode.position.x+10
        //self.sceneView.scene.rootNode.position = SCNVector3(100,100,0)
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
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        startSession()
        testNode()
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
        self.annotationManager?.removeAllAnnotations()
        self.addAnnotations()
    }
    
    func calloutImage(location:CLLocation) -> UIImage? {
        let route = self.route!
        var distance = 100.0
        for step in route.steps {
            distance = self.distance(from: CLLocation(latitude:step.polyline.coordinates.first!.latitude, longitude:  step.polyline.coordinates.first!.longitude) ,to: location)
            if(distance<2&&step.instructions.contains("右转")){
                return UIImage(named: "turnright")
            }
            if(distance<2&&step.instructions.contains("左转")){
                return UIImage(named: "turnleft")
            }
            
        }
        return nil
    }
    
    func testNode() {
        
//        let indices: [Int32] = [0, 1]
//        let source = SCNGeometrySource(vertices: [SCNVector3(x: 0, y: 0.1, z: 0), SCNVector3(x: 0, y: 0.1, z: 20)])
//        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
//        let line = SCNGeometry(sources: [source], elements: [element])
//        line.firstMaterial?.diffuse.contents = UIColor.red
//        let lineNode = SCNNode(geometry: line)
//        lineNode.position = SCNVector3Zero
//        sceneView.scene.rootNode.addChildNode(lineNode)
        
        //let cube = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.01)
        

//        let image = UIImage(named: "arrow")!
//
//        let calloutGeometry = SCNPlane(width: 0.5, height: 0.5)
//        calloutGeometry.firstMaterial?.diffuse.contents = image
//
//        let calloutNode = SCNNode(geometry: calloutGeometry)
//
//        calloutNode.position = SCNVector3(x: 0, y: 0.1, z: 10)
//
//        //Float(-Double.pi/2.0)
//        calloutNode.transform = SCNMatrix4MakeRotation(Float(-Double.pi/2.0),1.0, 0.0, 0.0);
//        calloutNode.transform = SCNMatrix4Mult(calloutNode.transform, SCNMatrix4MakeRotation(Float(-Double.pi/2.0),0.0, 1.0, 0.0))
//        sceneView.scene.rootNode.addChildNode(calloutNode)
    
    }
    
    func addAnnotations(){
        guard (self.route?.polyline) != nil else {
            return
        }
        let polyline = self.route?.polyline
        self.annotationManager?.originLocation = getUserLocation()
        self.annotationManager?.removeAllAnnotations()
        //var userlocation = self.getUserLocation()
//        let turfPolyline = Polyline([CLLocationCoordinate2DMake(userlocation.coordinate.latitude,userlocation.coordinate.longitude),CLLocationCoordinate2DMake(self.toLocation!.coordinate.latitude, self.toLocation!.coordinate.longitude)])
        let turfPolyline = Polyline(polyline!.coordinates)
        let metersPerNode: CLLocationDistance = 3
        var annotationsToAdd:[TFAnnotation] = []
        var index = 0
        let stridePoints = stride(from: metersPerNode, to: turfPolyline.distance() - metersPerNode, by: metersPerNode)
        let cc:CLLocationDirection = turfPolyline.coordinates[0].direction(to: turfPolyline.coordinates[1])
        print(cc)
        // Walk the route line and add a small AR node and map view annotation every metersPerNode
        for i in stridePoints {
            // Use Turf to find the coordinate of each incremented distance along the polyline
            if let nextCoordinate = turfPolyline.coordinateFromStart(distance: i) {
                
                let interpolatedStepLocation = CLLocation(latitude: nextCoordinate.latitude, longitude: nextCoordinate.longitude)
                //if(self.distanceFromCurrent(to: interpolatedStepLocation) < 500){
                // Add an AR node
                let annotation = TFAnnotation(location: interpolatedStepLocation, calloutImage:calloutImage(location: interpolatedStepLocation) )
                annotation.index = index
                annotation.direction = cc
                annotationsToAdd.append(annotation)
                index = index + 1
                // }
            }
        }
        let annotation = TFAnnotation(location: CLLocation(latitude: polyline!.coordinates.last!.latitude, longitude: polyline!.coordinates.last!.longitude) , calloutImage:UIImage(named: "pin"))
        annotationsToAdd.append(annotation)
        
        // Update the annotation manager with the latest AR annotations
        //self.annotationManager?.addAnnotations(annotations: annotationsToAdd)
        self.tfAnnotationManager?.addAnnotations(annotationsToAdd)
        self.testNode()
        
    }
}

extension ViewController:AnnotationManagerDelegate{
    func initAnnotationManager(){
        annotationManager = AnnotationManager(sceneView: sceneView)
        annotationManager!.delegate = self
        tfAnnotationManager = TFAnnotationManager(sceneView:sceneView)
    }
    
    func node(for annotation: Annotation) -> SCNNode? {
        
        let image = UIImage(named: "arrow")!
        
        let calloutGeometry = SCNPlane(width: 1.0, height: 1.0)
        calloutGeometry.firstMaterial?.diffuse.contents = image
        
        let calloutNode = SCNNode(geometry: calloutGeometry)
       // calloutNode.position = SCNVector3(x: 0, y: 10, z: 10)
//Float(-Double.pi/2.0)
       calloutNode.transform = SCNMatrix4MakeRotation(Float(-Double.pi/2.0), 1.0, 0.0, 0.0);
       //let bearing = GLKMathDegreesToRadians(Float(self.annotationManager!.originLocation!.coordinate.direction(to: annotation.location.coordinate)))
//      calloutNode.transform = SCNMatrix4Mult(calloutNode.transform,SCNMatrix4MakeRotation(Float(-Double.pi/2.0), 1.0, 0.0, 0.0), SCNMatrix4MakeRotation(Float(-90), 0.0, 1.0, 0.0));
//        print(calloutNode.position)
        if let d = annotation.direction{

            //calloutNode.transform = SCNMatrix4Mult(calloutNode.transform, SCNMatrix4MakeRotation(Float((90.0-d).toRadians()),0.0, 1.0, 0.0))
        }
        
        
        //calloutNode.rotate(by: <#T##SCNQuaternion#>, aroundTarget: <#T##SCNVector3#>)
        
        return calloutNode

        
        
//        let color = UIColor(red: 0, green:1, blue: 0, alpha: 1)
//        let minAlpha:CGFloat = 0.3
//        let maxIndex = 10
//        var firstColor = color.withAlphaComponent(minAlpha)
//        if let index = annotation.index {
//            if index < maxIndex {
//                firstColor = color.withAlphaComponent(1.0 - (1.0 - minAlpha)/10.0 * CGFloat(index))
//            }
//        }
//        return createSphereNode(with: 0.5, firstColor: firstColor, secondColor: UIColor.green)
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
        //uilgr.minimumPressDuration = 2.0
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
    
    func distance(to:CLLocation) -> Double {
        if let currentLocation = self.currentLocation {
            let polyline = Polyline([currentLocation.coordinate,to.coordinate])
            return  polyline.distance()
        }
        return 10000.0
    }
    
    func distance(from:CLLocation,to:CLLocation) -> Double {
        let polyline = Polyline([from.coordinate,to.coordinate])
        return  polyline.distance()
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let nowCurrentLocation = self.getUserLocation()
        let d = distance(to:nowCurrentLocation)
        self.currentLocation = nowCurrentLocation
        if(self.mapView.overlays.count > 0 &&  d > 20) {
            
            self.direction(to: self.toLocation!)
            //self.label.text = "renew"
        }
        //self.label.text = "\(nowCurrentLocation.coordinate.latitude) , \(nowCurrentLocation.coordinate.longitude)"
        //self.centerMapOnLocation(location: self.currentLocation!)
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
        guard !self.isDirectioning else{
            return
        }
        self.isDirectioning = true
        self.mapView.removeOverlays(self.mapView.overlays)
        let request = MKDirectionsRequest()
        request.source = MKMapItem.forCurrentLocation()
        let locationPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2DMake(to.coordinate.latitude, to.coordinate.longitude), addressDictionary: nil)
        request.destination = MKMapItem(placemark: locationPlacemark)
        request.transportType = MKDirectionsTransportType.walking
        request.requestsAlternateRoutes = true
        let directions = MKDirections(request: request)
        directions.calculate { (response, error) in
            self.isDirectioning = false
            guard let response = response else {
                return;
            }
            let myRoute = response.routes[0]
            self.route = myRoute
            self.addAnnotations()
            
            self.mapView.add(myRoute.polyline)
        }
        
    }
}



