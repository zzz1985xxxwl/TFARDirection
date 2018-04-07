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
import MapboxARKit

class TFAnnotationManager {
    
    private var sceneView:ARSCNView
    private var nodes:[SCNNode] = []
    var tfRootNode:SCNNode = SCNNode()
    var originLocation:CLLocation?
    
    init(sceneView: ARSCNView){
        self.sceneView = sceneView
        self.sceneView.scene.rootNode.addChildNode(tfRootNode)
    }
    
    func add(annotation:Annotation){
        let node = createNode(annotation: annotation)
        self.tfRootNode.addChildNode(node)
        self.nodes.append(node)
    }
    
    func addAnnotations(_ annotations:[Annotation]) {
        let total = annotations.count
        for (index,annotation) in annotations.enumerated() {
            if(index < total-1){
                let firstCoord = annotations[index].location.coordinate
                let secondCoord = annotations[index + 1].location.coordinate
                annotation.direction = firstCoord.direction(to: secondCoord)
            }else{
                annotation.direction = annotations[index-1].direction
            }
            self.add(annotation: annotation)
        }
    }
    
    func removeAll() -> Void {
        for node in self.nodes {
            node.removeFromParentNode()
        }
        self.nodes = []
    }
    
    func createNode(annotation:Annotation) -> SCNNode {
//        let image = UIImage(named: "arrow")!
//
//        let geometry = SCNPlane(width: 1.0, height: 1.0)
//        geometry.firstMaterial?.diffuse.contents = image
//
//        let node = SCNNode(geometry: geometry)
        
        
       // let color = UIColor(red: 1, green:0, blue: 0, alpha: 1)
        
       // let node = createSphereNode(with: 0.5, firstColor: color, secondColor: UIColor.green)
    
        
        
        let arrowScene = SCNScene(named: "art.scnassets/arrow.scn")
        var node = arrowScene!.rootNode
        let geometry = node.geometry
        geometry?.firstMaterial?.diffuse.contents = UIColor.red
        let distance = Float(annotation.location.distance(from: originLocation!))
        let bearing = GLKMathDegreesToRadians(Float(originLocation!.coordinate.direction(to: annotation.location.coordinate)))
        if let radians = annotation.direction?.toRadians(){
             node.transform = SCNMatrix4MakeRotation(Float(Double.pi/2.0-radians),0.0, 1.0, 0.0);
        }
        if annotation.isLast {
            node = createSphereNode(with: 0.3, firstColor:  UIColor.red, secondColor: UIColor.red)
            
        }
        node.position = SCNVector3(x: distance*sin(bearing), y: 0.0, z: -distance*cos(bearing))
        
        if let calloutImage = annotation.calloutImage {
            let calloutNode = createCalloutNode(with: calloutImage, node: node)
            node.addChildNode(calloutNode)
        }
        
        //Float(-Double.pi/2.0)
        //node.transform = SCNMatrix4MakeRotation(Float(-Double.pi/2.0),1.0, 0.0, 0.0);
        //calloutNode.transform = SCNMatrix4Mult(calloutNode.transform, SCNMatrix4MakeRotation(Float(-Double.pi/2.0),0.0, 1.0, 0.0))
        return node
    }
    
    
    
    func createSphereNode(with radius: CGFloat, firstColor: UIColor, secondColor: UIColor) -> SCNNode {
        let geometry = SCNSphere(radius: radius)
        geometry.firstMaterial?.diffuse.contents = firstColor
        
        let sphereNode = SCNNode(geometry: geometry)
        return sphereNode
    }
    
    func change(degree:Double) -> Void {
        self.tfRootNode.transform = SCNMatrix4Mult(tfRootNode.transform, SCNMatrix4MakeRotation(Float(degree.toRadians()),0.0, 1.0, 0.0));
    }
    
    func reset() -> Void {
        self.tfRootNode.transform = SCNMatrix4MakeRotation(0.0,0.0, 1.0, 0.0)
    }
    
    func createCalloutNode(with image: UIImage, node: SCNNode) -> SCNNode {
        
        var width: CGFloat = 0.0
        var height: CGFloat = 0.0
        
        if image.size.width >= image.size.height {
            width = image.size.width / image.size.height
            height = 2.0
        } else {
            width = 2.0
            height = image.size.height / image.size.width
        }
        
        let calloutGeometry = SCNPlane(width: 3, height: 3)
        calloutGeometry.firstMaterial?.diffuse.contents = image
        
        
        let calloutNode = SCNNode(geometry: calloutGeometry)
        calloutNode.position = SCNVector3(x: 0, y: 2.0, z: 0)
//        var nodePosition = node.position
//        let (min, max) = node.boundingBox
//        let nodeHeight = max.y - min.y
//        nodePosition.y = nodeHeight + 0.5
//
//        calloutNode.position = nodePosition
//
        let constraint = SCNBillboardConstraint()
        constraint.freeAxes = [.Y]
        calloutNode.constraints = [constraint]
        
        return calloutNode
    }
}
