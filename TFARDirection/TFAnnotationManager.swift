//
//  TFAnnotationManager.swift
//  TFARDirection
//
//  Created by 薛文龙 on 2018/4/6.
//  Copyright © 2018年 com.delianac. All rights reserved.
//

import Foundation
import ARKit
import CoreLocation

class TFAnnotation{
    public var location: CLLocation
    public var calloutImage: UIImage?
    public var anchor: ARAnchor?
    public var index: Int?
    public var direction:CLLocationDirection?
    
    public init(location: CLLocation, calloutImage: UIImage?) {
        self.location = location
        self.calloutImage = calloutImage
    }
}

class TFAnnotationManager {
    
    private var sceneView:ARSCNView
    private var nodes:[SCNNode] = []
    
    init(sceneView: ARSCNView){
        self.sceneView = sceneView
    }
    
    func add(annotation:TFAnnotation){
        let node = createNode(annotation: annotation)
        self.sceneView.scene.rootNode.addChildNode(node)
        self.nodes.append(node)
    }
    
    func addAnnotations(_ annotations:[TFAnnotation]) {
        for annotation in annotations {
            self.add(annotation: annotation)
        }
    }
    
    func removeAll() -> Void {
        for node in self.nodes {
            node.removeFromParentNode()
        }
    }
    
    func createNode(annotation:TFAnnotation) -> SCNNode {
        let image = UIImage(named: "arrow")!
        
        let geometry = SCNPlane(width: 0.5, height: 0.5)
        geometry.firstMaterial?.diffuse.contents = image
        
        let node = SCNNode(geometry: geometry)
        let distance = 
        node.position = SCNVector3(x: 0, y: 0.1, z: 10)
        
        //Float(-Double.pi/2.0)
        node.transform = SCNMatrix4MakeRotation(Float(-Double.pi/2.0),1.0, 0.0, 0.0);
        //calloutNode.transform = SCNMatrix4Mult(calloutNode.transform, SCNMatrix4MakeRotation(Float(-Double.pi/2.0),0.0, 1.0, 0.0))
        return node
    }
}
