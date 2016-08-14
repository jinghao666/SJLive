//
//  CameraCapture.swift
//  OSXAVFoundationDemo
//
//  Created by king on 16/8/1.
//  Copyright © 2016年 king. All rights reserved.
//

import Cocoa
import AVFoundation
import OpenGL
import CoreImage

protocol CameraCaptureDelegate: NSObjectProtocol {
    
    func CameraVideoOutput(sampleBuffer: CVImageBuffer!)

}

class CameraCapture: NSObject {

    let cameraQueue: dispatch_queue_t! = dispatch_queue_create("com.king129", DISPATCH_QUEUE_SERIAL)
    var videoEncoder: VideoEncode = VideoEncode()
    
    var delegate: CameraCaptureDelegate?
    var captureSession: AVCaptureSession!
    var captureDevice: AVCaptureDevice!
    var captureDeviceInput: AVCaptureDeviceInput!
    var captureVideoDataOutput: AVCaptureVideoDataOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    func setup(fps: Int, sessionPreset: String?) -> AVCaptureVideoPreviewLayer? {
        
        captureSession = AVCaptureSession()
        if (sessionPreset != nil) {
            captureSession.sessionPreset = sessionPreset
        }
        captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        if captureDevice == nil {
            return nil
        }
        
        do {
            
           try captureDevice.lockForConfiguration()
        } catch let error {
            print(error)
        }
        
        captureDevice.unlockForConfiguration()
        do {
            captureDeviceInput =  try AVCaptureDeviceInput(device: captureDevice)
        } catch let error {
            print(error)
        }
        
        captureVideoDataOutput = AVCaptureVideoDataOutput()
        captureVideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : NSNumber.init(unsignedInt: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]

    
        captureVideoDataOutput.setSampleBufferDelegate(self, queue: cameraQueue)
        
        if captureSession.canAddInput(captureDeviceInput) {
            captureSession.addInput(captureDeviceInput)
        }
        if captureSession.canAddOutput(captureVideoDataOutput) {
            captureSession.addOutput(captureVideoDataOutput)
        }
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoPreviewLayer.connection.videoOrientation = .Portrait
        videoPreviewLayer.setAffineTransform(CGAffineTransformMakeScale(-1, 1))
        return videoPreviewLayer
    
    }
    
    func startRunning()  {
        captureSession.startRunning()
        videoEncoder.start()
    }
    func stopRunning() {
        captureSession.stopRunning()
        videoEncoder.endEncode()
    }
    func isRunning() -> Bool {
        return captureSession == nil ? false : captureSession.running
    }
}

extension CameraCapture : AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
        guard let image:CVImageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        delegate?.CameraVideoOutput(image)
//        videoEncoder.encodeImageBuffer(image, presentationTimeStamp: CMSampleBufferGetPresentationTimeStamp(sampleBuffer), presentationDuration: CMSampleBufferGetDuration(sampleBuffer))
        // print("get camera image data! Yeh!")
    }
    
}
