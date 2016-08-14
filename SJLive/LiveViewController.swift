//
//  LiveViewController.swift
//  SJLive
//
//  Created by king on 16/8/14.
//  Copyright © 2016年 king. All rights reserved.
//

import Cocoa
import SnapKit
import AVFoundation

class LiveViewController: NSViewController {

    lazy var stopBtn: NSButton = {
        let btn = NSButton()
        btn.bezelStyle = .RoundedBezelStyle
        btn.title = "停止采集"
        return btn
    }()
    
    lazy var recordRectBtn: NSButton = {
        
        let btn = NSButton()
        btn.bezelStyle = .RoundedBezelStyle
        btn.title = "设置录制范围"
        return btn
    }()
    
    lazy var startRecordBtn: NSButton = {
        
        let btn = NSButton()
        btn.bezelStyle = .RoundedBezelStyle
        btn.title = "开始录屏"
        return btn
    }()
    
    lazy var stopRecordBtn: NSButton = {
        
        let btn = NSButton()
        btn.bezelStyle = .RoundedBezelStyle
        btn.title = "停止录屏"
        return btn
    }()
    
    lazy var audioPopUpButton:NSPopUpButton = {
        let button:NSPopUpButton = NSPopUpButton()
        button.action = #selector(LiveViewController.selectAudio(_:))
        let audios:[AnyObject]! = AVCaptureDevice.devicesWithMediaType(AVMediaTypeAudio)
        for audio in audios {
            if let audio:AVCaptureDevice = audio as? AVCaptureDevice {
                button.addItemWithTitle(audio.localizedName)
            }
        }
        return button
    }()
    
    lazy var cameraPopUpButton:NSPopUpButton = {
        let button:NSPopUpButton = NSPopUpButton()
        button.action = #selector(LiveViewController.selectCamera(_:))
        let cameras:[AnyObject]! = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        button.addItemWithTitle("屏幕录制")
        for camera in cameras {
            if let camera:AVCaptureDevice = camera as? AVCaptureDevice {
                button.addItemWithTitle(camera.localizedName)
            }
        }
        return button
    }()
    
    var VideoPreView: AVCaptureVideoPreviewLayer!
    lazy var recordScreen: RecordScreen = {
        
        let re = RecordScreen()
        return re
    }()
    
    lazy var paleyView: NSView = {
       
        let v = NSView()
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor.blackColor().CGColor
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        // 添加子控件
        view.addSubview(stopBtn)
        view.addSubview(recordRectBtn)
        view.addSubview(startRecordBtn)
        view.addSubview(stopRecordBtn)
        view.addSubview(audioPopUpButton)
        view.addSubview(cameraPopUpButton)
        view.addSubview(paleyView)
        
        // 添加约束
        stopBtn.snp_makeConstraints { (make) in
            make.size.equalTo(NSSize(width: 100, height: 30))
            make.left.equalTo(view).offset(30)
            make.bottom.equalTo(view.snp_bottom).offset(-20)
        }
        
        recordRectBtn.snp_makeConstraints { (make) in
            
            make.size.equalTo(stopBtn.snp_size)
            make.left.equalTo(stopBtn.snp_right).offset(30)
            make.bottom.equalTo(stopBtn.snp_bottom)
        }
        
        startRecordBtn.snp_makeConstraints { (make) in
            make.size.equalTo(stopBtn.snp_size)
            make.left.equalTo(recordRectBtn.snp_right).offset(30)
            make.bottom.equalTo(recordRectBtn.snp_bottom)
        }
        
        stopRecordBtn.snp_makeConstraints { (make) in
            make.size.equalTo(stopBtn.snp_size)
            make.left.equalTo(startRecordBtn.snp_right).offset(30)
            make.bottom.equalTo(startRecordBtn.snp_bottom)
        }
        
        audioPopUpButton.snp_makeConstraints { (make) in
            make.size.equalTo(NSMakeSize(150, 30))
            make.left.equalTo(stopRecordBtn.snp_right).offset(30)
            make.bottom.equalTo(stopRecordBtn.snp_bottom)
        }
        
        cameraPopUpButton.snp_makeConstraints { (make) in
            make.size.equalTo(NSMakeSize(150, 30))
            make.left.equalTo(audioPopUpButton.snp_right).offset(30)
            make.bottom.equalTo(audioPopUpButton.snp_bottom)
        }
        
        paleyView.snp_makeConstraints { (make) in
            make.left.top.right.equalTo(view)
            make.bottom.equalTo(stopBtn.snp_top).offset(-10)
        }

        // 添加事件
        stopBtn.target = self
        stopBtn.action = #selector(LiveViewController.stopBtnClick)
        
        recordRectBtn.target = recordScreen
        recordRectBtn.action = #selector(recordScreen.setDisplayAndCropRect)
        
        startRecordBtn.target = recordScreen
        startRecordBtn.action = #selector(recordScreen.startRecording)
        
        stopRecordBtn.target = recordScreen
        stopRecordBtn.action = #selector(recordScreen.stopRecording)
        
        
        createRecordScreen()
    }
    override func viewDidAppear() {
        super.viewDidAppear()
        VideoPreView.frame = NSRect(origin: CGPointMake(0, 0), size: paleyView.bounds.size)
    }
    
    
    override func viewDidLayout() {
        super.viewDidLayout()
        VideoPreView.frame = NSRect(origin: CGPointMake(0, 0), size: paleyView.bounds.size)
        print(paleyView.bounds.size)
    }
    func stopBtnClick() {
        if stopBtn.title == "开始采集" {
            recordScreen.startRunning()
            stopBtn.title = "停止采集"
        } else {
            recordScreen.stopRunning()
            recordScreen.stopRecording()
            stopBtn.title = "开始采集"
        
        }
    }

    func createRecordScreen()  {

        if recordScreen.createCaptureSession() {
            VideoPreView = recordScreen.createCaptureVideoPreView()
            paleyView.layer?.addSublayer(VideoPreView)
            recordScreen.startRunning()
        }
    }
    
    func selectAudio(sender:AnyObject) {
       if let device:AVCaptureDevice? = deviceWithLocalizedName(
            audioPopUpButton.itemTitles[audioPopUpButton.indexOfSelectedItem],
            mediaType: AVMediaTypeAudio
        ) {
        
         recordScreen.switchAudioInputSource(device)
        }
    }
    
    func selectCamera(sender:AnyObject) {
        if let device:AVCaptureDevice? = deviceWithLocalizedName(
            cameraPopUpButton.itemTitles[cameraPopUpButton.indexOfSelectedItem],
            mediaType: AVMediaTypeVideo
            ) {
            recordScreen.switchVideoInputSource(device)
        } else {
            recordScreen.switchVideoInputSource(nil)
        }
    }
}

extension LiveViewController : RecordScreenDelegate {
    
    func RecordScreenDidOutputSampleBuffer(sampleBuffer: CMSampleBuffer!) {
        
        if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            
//            imageFromSamplePlanerPixelBuffer(imageBuffer)
        }
    }
}

extension LiveViewController {
    
    func imageFromSamplePlanerPixelBuffer(imageBuffer: CVImageBuffer!) {
    
        CVPixelBufferLockBaseAddress(imageBuffer, 0)
        
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0)
        
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceGray()
        
        let context = CGBitmapContextCreate(baseAddress,
                                            width,
                                            height,
                                            8,
                                            bytesPerRow,
                                            colorSpace,
                                            0)
        let imageRef = CGBitmapContextCreateImage(context)
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0)
    
        if let imageRef = imageRef  {
            
            //.....
            
            
        }

    }
}

func deviceWithLocalizedName(localizedName:String, mediaType:String) -> AVCaptureDevice? {
    for device in AVCaptureDevice.devices() {
        guard let device:AVCaptureDevice = device as? AVCaptureDevice else {
            continue
        }
        if (device.hasMediaType(mediaType) && device.localizedName == localizedName) {
            return device
        }
    }
    return nil
}
