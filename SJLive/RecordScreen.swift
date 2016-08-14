//
//  RecordScreen.swift
//  MacAVFoundation_VideoToolBox
//
//  Created by king on 16/8/13.
//  Copyright © 2016年 king. All rights reserved.
//

import Cocoa
import AVFoundation

protocol RecordScreenDelegate {
    
     func RecordScreenDidOutputSampleBuffer(sampleBuffer: CMSampleBuffer!)
}


struct WindowLevel {
    
   static let kShadyWindowLevel = Int(CGWindowLevelForKey(.DockWindowLevelKey) + 1000)
}

class RecordScreen: NSObject {

    var delegate: RecordScreenDelegate?
    /// 会话
    var captureSession: AVCaptureSession!
    /// 屏幕输入
    var captureScreenInput: AVCaptureScreenInput!
    /// 摄像头输入
    var cameraInput: AVCaptureDeviceInput!
    /// 音频输入
    var audioMicInput: AVCaptureDeviceInput!
    var display: CGDirectDisplayID!
    /// 视频输出
    var captureMovieFileOutput: AVCaptureMovieFileOutput!
    
    /// 视频连接
    var videoConnection:AVCaptureConnection!
    /// 音频连接
    var audioConnection:AVCaptureConnection!
    
    var shadeWindows: [AnyObject]! = [AnyObject]()
    var isRecordScreening: Bool = false
    var isScreenInput: Bool = true
    
    var isRunning: Bool {
        return captureSession.running
    }
    
    deinit {
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVCaptureSessionRuntimeErrorNotification, object: captureSession)
    }
    
}


extension RecordScreen : AVCaptureFileOutputDelegate {
    
    // MARK: 创建会话
    func createCaptureSession() -> Bool {
        
        captureSession = AVCaptureSession()
        if captureSession.canSetSessionPreset(AVCaptureSessionPreset1280x720) {
            captureSession.canSetSessionPreset(AVCaptureSessionPreset1280x720)
        }
        
        display = CGMainDisplayID()
        
        captureScreenInput = AVCaptureScreenInput(displayID: display)
        
        if captureSession.canAddInput(captureScreenInput) {
            captureSession.addInput(captureScreenInput)
            isScreenInput = true
        } else {
            return false
        }
        
        let mic = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        do {
            try audioMicInput = AVCaptureDeviceInput.init(device: mic)
            if captureSession.canAddInput(audioMicInput) {
                captureSession.addInput(audioMicInput)
            }
        } catch let error {
            print("音频设备获取失败: \(error)")
        }
        captureMovieFileOutput = AVCaptureMovieFileOutput()
        captureMovieFileOutput.delegate = self
        if captureSession.canAddOutput(captureMovieFileOutput) {
            captureSession.addOutput(captureMovieFileOutput)
        } else {
            return false
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(captureSessionRuntimeErrorDidOccur(_:)), name: AVCaptureSessionRuntimeErrorNotification, object: captureSession)
        
        return true
    }
    // MARK: - 创建添加预览层
    func createCaptureVideoPreView() -> AVCaptureVideoPreviewLayer {
        
        let preView = AVCaptureVideoPreviewLayer(session: captureSession)
        preView.videoGravity = AVLayerVideoGravityResizeAspectFill
        return preView
    }
    // MARK: - 设置获取最大帧速率
    func setMaxRrameRate(rate: Int32) {
        
        let frameDuration = CMTimeMake(1, rate)
        captureScreenInput.minFrameDuration = frameDuration
    }
    
    func getMaxFrameRate() -> Float64 {
        
        let interval = CMTimeGetSeconds(captureScreenInput.minFrameDuration)
        return interval > 0.0 ? 1.0 / interval : 0.0
    }
    // MARK: - setDisplayID
    func addDisplayInputToCaptureSession(newDisplay: CGDirectDisplayID, cropRect: NSRect)  {
        
        /// 开启事务
        captureSession.beginConfiguration()
        
        if newDisplay != display {
            
            captureSession.removeInput(captureScreenInput)
            let newScreeenInput = AVCaptureScreenInput(displayID: newDisplay)
            captureScreenInput = newScreeenInput
            
            if captureSession.canAddInput(captureScreenInput) {
                captureSession.addInput(captureScreenInput)
            }
            setMaxRrameRate(Int32(getMaxFrameRate()))
        }
        captureScreenInput.cropRect = cropRect
        captureSession.commitConfiguration()
    }

    // MARK: - 设置录制区域
    func setDisplayAndCropRect()  {
        
        for screen in NSScreen.screens()! {
            
            let frame = screen.frame
            let window = NSWindow(contentRect: frame, styleMask: NSBorderlessWindowMask, backing: .Buffered, defer: false)
            window.backgroundColor = NSColor.blackColor()
            window.alphaValue = 0.5
            window.level = WindowLevel.kShadyWindowLevel
            window.releasedWhenClosed = false
            
            let drawMouseBoxView = DrawMouseBoxView(frame: frame)
            drawMouseBoxView.delegate = self
            window.contentView = drawMouseBoxView
            window.makeKeyAndOrderFront(self)
            shadeWindows.append(window)
        }
        NSCursor.currentCursor().push()
    }
    
    func captureSessionRuntimeErrorDidOccur(note: NSNotification)  {
        
        let error = note.userInfo![AVCaptureSessionErrorKey]
        let alert = NSAlert()
        alert.alertStyle = .CriticalAlertStyle
        alert.messageText = (error?.localizedDescription)!
        
        let info = (error?.localizedRecoverySuggestion)!!
        alert.informativeText = info
        
        alert.beginSheetModalForWindow(NSApplication.sharedApplication().keyWindow!, completionHandler: nil)
    }
    
    ///
    func captureOutputShouldProvideSampleAccurateRecordingStart(captureOutput: AVCaptureOutput!) -> Bool {
        
        return false
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
        delegate?.RecordScreenDidOutputSampleBuffer(sampleBuffer)
        
    }
}

extension RecordScreen : AVCaptureFileOutputRecordingDelegate {
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        
        if error != nil {
            return
        }
        NSWorkspace.sharedWorkspace().openURL(outputFileURL)
    }
}

extension RecordScreen : DrawMouseBoxViewDelegate {
    
    func drawMouseBoxView(view: DrawMouseBoxView, didSelectRect rect: NSRect) {
        
        var globalRect = rect
        let windowRect = (view.window?.frame)!
        
        globalRect = NSOffsetRect(globalRect, windowRect.origin.x, windowRect.origin.y)
        globalRect.origin.y = CGFloat(CGDisplayPixelsHigh(CGMainDisplayID())) - globalRect.origin.y
        var displayID = display
        var matchingDisplayCount: UInt32 = 0
        
        /// 待解决
//        let error = CGGetDisplaysWithPoint(NSPointToCGPoint(globalRect.origin),
//                                           1,
//                                           &displayID,
//                                           &matchingDisplayCount)
//        print("error \(error.rawValue)")
//        print(matchingDisplayCount)
//        if error == .Success && matchingDisplayCount == 1 {
//            print("设置成功...")
//            print(displayID)
//            addDisplayInputToCaptureSession(displayID, cropRect: NSRectToCGRect(rect))
//            
//        }
        
        for window in NSApp.windows {
            
            if window.level == WindowLevel.kShadyWindowLevel {
                window.close()
            }
        }
        NSCursor.currentCursor().pop()
        shadeWindows.removeAll()
    }
}

extension RecordScreen {
    
    // MARK: - 切换视频输入源
    func switchVideoInputSource(device: AVCaptureDevice?)  {
        
        if isRunning {
            captureSession.stopRunning()
        }
        
        if isScreenInput {
            
            captureSession.removeInput(captureScreenInput)
        } else {
            if (cameraInput != nil) {
                captureSession.removeInput(cameraInput)
            }
        }
        
        if device == nil {
            
            /// 屏幕输入
            display = CGMainDisplayID()
            captureScreenInput = AVCaptureScreenInput(displayID: display)
            
            if captureSession.canAddInput(captureScreenInput) {
                captureSession.addInput(captureScreenInput)
                isScreenInput = true
                captureSession.startRunning()
            } else {
                print("添加屏幕输入失败...")
            }
        } else {
            
            do {
                
                try cameraInput = AVCaptureDeviceInput(device: device)
                if captureSession.canAddInput(cameraInput) {
                    captureSession.addInput(cameraInput)
                    isScreenInput = false
                    captureSession.startRunning()
                } else {
                    print("添加摄像头输入失败")
                }
            } catch let error {
                print(error)
            }
            
        }
        
    }
    // MARK: - 切换音频输入源
    func switchAudioInputSource(device: AVCaptureDevice?)  {
        
        if isRunning {
            captureSession.stopRunning()
        }
        
        if audioMicInput != nil {
            captureSession.removeInput(audioMicInput)
        }
        
        do {
            try audioMicInput = AVCaptureDeviceInput.init(device: device)
            if captureSession.canAddInput(audioMicInput) {
                captureSession.addInput(audioMicInput)
                captureSession.startRunning()
            } else {
                print("添加音频设备输入失败")
            }
        } catch let error {
            print("音频设备获取失败: \(error)")
        }
        
    }
    
    func startRunning()  {
        
        if isRunning {
            return
        }
        captureSession.startRunning()
    }
    
    func stopRunning() {
        
        if isRunning {
            captureSession.stopRunning()
        }
    }
    
    func startRecording()  {
        
        if isRecordScreening {
            return
        }
    NSLog("Minimum Frame Duration: %f, Crop Rect: %@, Scale Factor: %f, Capture Mouse Clicks: %@, Capture Mouse Cursor: %@, Remove Duplicate Frames: %@",
          CMTimeGetSeconds(captureScreenInput.minFrameDuration),
          NSStringFromRect(NSRectFromCGRect(captureScreenInput.cropRect)),
          captureScreenInput.scaleFactor,
          captureScreenInput.capturesMouseClicks ? "Yes" : "NO",
          captureScreenInput.capturesCursor ? "Yes" : "NO",
          captureScreenInput.removesDuplicateFrames ? "Yes" : "NO")
        
        isRecordScreening = true
        

        let path = (NSHomeDirectory() + "/Desktop/AVRecordScreen_XXXXX" as NSString).cStringUsingEncoding(NSUTF8StringEncoding)
        print("文件地址: \(String(CString: path, encoding: NSUTF8StringEncoding))")
        if let screenRecordingFileName: UnsafeMutablePointer<Int8> = strdup(path) {
            
            let fileDescriptor = mkstemp(screenRecordingFileName)
            if fileDescriptor != -1 {
                
                let fleNmaeStr = NSFileManager.defaultManager().stringWithFileSystemRepresentation(screenRecordingFileName, length: strlen(UnsafePointer.init(screenRecordingFileName)).hashValue) + ".mov"

                captureMovieFileOutput.startRecordingToOutputFileURL(NSURL(fileURLWithPath: fleNmaeStr), recordingDelegate: self)
            }
            
            remove(screenRecordingFileName)
            free(screenRecordingFileName)
        }

    }
    
    func stopRecording()  {
        
        if isRecordScreening {
            captureMovieFileOutput.stopRecording()
            isRecordScreening = false
        }
    }
}
