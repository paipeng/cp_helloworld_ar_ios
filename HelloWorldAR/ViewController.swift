//
//  ViewController.swift
//  HelloWorldAR
//
//  Created by Pai Peng on 21.10.24.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var qrRequests = [VNRequest]()
    var detectedDataAnchor: ARAnchor?
    var processing = false
    var latestFrame: ARFrame?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        self.startQrCodeDetection()
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/watch1usdc.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func startQrCodeDetection() {
        // Create a Barcode Detection Request
        let request = VNDetectBarcodesRequest(completionHandler: self.requestHandler)
        // Set it to recognize QR code only
        request.symbologies = [.QR]
        self.qrRequests = [request]
    }
    
    func requestHandler(request: VNRequest, error: Error?) {
        // Get the first result out of the results, if there are any
        if let results = request.results, let result = results.first as? VNBarcodeObservation {
            guard let payload = result.payloadStringValue else {return}
            // Get the bounding box for the bar code and find the center
            var rect = result.boundingBox
            // Flip coordinates
            rect = rect.applying(CGAffineTransform(scaleX: 1, y: -1))
            rect = rect.applying(CGAffineTransform(translationX: 0, y: 1))
            // Get center
            let center = CGPoint(x: rect.midX, y: rect.midY)

            DispatchQueue.main.async {
                self.hitTestQrCode(center: center)
                self.processing = false
            }
        } else {
            self.processing = false
        }
    }

    func hitTestQrCode(center: CGPoint) {
        print("hitTestQrCode: \(center)")
        if let hitTestResults = self.latestFrame?.hitTest(center, types: [.featurePoint] ),
            let hitTestResult = hitTestResults.first {
            if let detectedDataAnchor = self.detectedDataAnchor,
                let node = self.sceneView.node(for: detectedDataAnchor) {
                let previousQrPosition = node.position
                node.transform = SCNMatrix4(hitTestResult.worldTransform)

            } else {
                // Create an anchor. The node will be created in delegate methods
                self.detectedDataAnchor = ARAnchor(transform: hitTestResult.worldTransform)
                self.sceneView.session.add(anchor: self.detectedDataAnchor!)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {

        // If this is our anchor, create a node
        if self.detectedDataAnchor?.identifier == anchor.identifier {
            let sphere = SCNSphere(radius: 1.0)
            sphere.firstMaterial?.diffuse.contents = UIColor.red
            let sphereNode = SCNNode(geometry: sphere)
            sphereNode.transform = SCNMatrix4(anchor.transform)
            return sphereNode
        }
        return nil
    }
}

extension ViewController : ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        print("session didUpdate:")
        self.latestFrame = frame
        /*
        let capturedImage: CVPixelBuffer = frame.capturedImage
        var image = UIImage(pixelBuffer: capturedImage)
        if image != nil {
            image = nil
        }
         */
        
        do {
            if self.processing {
              return
            }
            self.processing = true
            // Create a request handler using the captured image from the ARFrame
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage,
                                                            options: [:])
            // Process the request
            try imageRequestHandler.perform(self.qrRequests)
        } catch {

        }
    }
}
