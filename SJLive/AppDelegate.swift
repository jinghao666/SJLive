//
//  AppDelegate.swift
//  SJLive
//
//  Created by king on 16/8/14.
//  Copyright © 2016年 king. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

     var window: NSWindow!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        let vc = LiveViewController()
        vc.title = "录屏"
        window = NSWindow(contentViewController: vc)
        var frame = (NSScreen.mainScreen()?.visibleFrame)!
        frame.origin = NSMakePoint(frame.size.width * 0.5 - 500, frame.size.height * 0.5 - 400)
        frame.size = NSMakeSize(1000, 800)
        window.setFrame(frame, display: true)
        window.minSize = NSMakeSize(900, 600)
        window.makeKeyAndOrderFront(self)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

