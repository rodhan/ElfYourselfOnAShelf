//
//  FirstViewController.swift
//  Test10
//
//  Created by Rodhan Hickey on 13/12/2017.
//  Copyright © 2017 Rodhan Hickey. All rights reserved.
//

import UIKit
import AVKit

class FirstViewController: UIViewController, AVCapturePhotoCaptureDelegate {

    @IBOutlet weak var previewView: UIView!
    
    var captureSession: AVCaptureSession?
    var cameraOutput : AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var capturedImage: UIImage?
    
    func startCameraCapture() {
        let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        
        cameraOutput = AVCapturePhotoOutput()
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)
            captureSession?.addOutput(cameraOutput)
        } catch {
            print(error)
        }
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = previewView.layer.bounds
        previewView.layer.addSublayer(videoPreviewLayer!)
        
        captureSession?.startRunning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        startCameraCapture()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func capturePhotoAndMoveToNextScreen() {
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [
            kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
            kCVPixelBufferWidthKey as String: 320,
            kCVPixelBufferHeightKey as String: 320
        ]
        settings.previewPhotoFormat = previewFormat
        
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let error = error {
            print("error occure : \(error.localizedDescription)")
        }
        
        if  let sampleBuffer = photoSampleBuffer,
            let previewBuffer = previewPhotoSampleBuffer,
            let dataImage =  AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer:  sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            print(UIImage(data: dataImage)?.size as Any)
            
            let dataProvider = CGDataProvider(data: dataImage as CFData)
            let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: UIImageOrientation.right)
            
            capturedImage = image
            
            performSegue(withIdentifier: "showARView", sender: self)
        } else {
            print("Error capturing photo")
        }
    }
    
    func rotateImage(image: UIImage, radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: image.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        //Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContext(newSize);
        let context = UIGraphicsGetCurrentContext()!
        
        //Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        //Rotate around middle
        context.rotate(by: CGFloat(radians))
        
        image.draw(in: CGRect(x: -image.size.width/2, y: -image.size.height/2, width: image.size.width, height: image.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func cropImage(_ sourceImage: UIImage) -> UIImage {
        let width = 600
        let height = 600
        let x = 240
        let y = 450
        
        let rect = CGRect(x: x, y: y, width: width, height: height)
        
        var image = rotateImage(image: sourceImage, radians: Float(2 * CGFloat(Float.pi)))!
        
        let imgRef = image.cgImage?.cropping(to: rect)
        image = UIImage(cgImage: imgRef!, scale: image.scale, orientation: image.imageOrientation)
        
        return image
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! ViewController
        
        vc.faceImage = cropImage(capturedImage!)
    }
    
    @IBAction func showNextView(_ sender: Any) {
        capturePhotoAndMoveToNextScreen()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
