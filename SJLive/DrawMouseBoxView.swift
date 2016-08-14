//
//  DrawMouseBoxView.swift
//  SJLive
//
//  Created by king on 16/8/14.
//  Copyright © 2016年 king. All rights reserved.
//

import Cocoa

protocol DrawMouseBoxViewDelegate {
    
    func drawMouseBoxView(view: DrawMouseBoxView, didSelectRect rect: NSRect)

}

class DrawMouseBoxView: NSView {

    var delegate: DrawMouseBoxViewDelegate?
    
    private var mouseDownPoint: NSPoint = NSZeroPoint
    private var selectionRect: NSRect = NSZeroRect
    
    // MARK: - 重写相关
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func acceptsFirstMouse(theEvent: NSEvent?) -> Bool {
        
        return true
    }
    
    // 开始点击
    override func mouseDown(theEvent: NSEvent) {
        // 记录初始点
        mouseDownPoint = theEvent.locationInWindow
    }
    // 正在拖拽
    override func mouseDragged(theEvent: NSEvent) {
        
        let curPoint = theEvent.locationInWindow
        let previousSelectionRect = selectionRect
        
        selectionRect = NSMakeRect(min(mouseDownPoint.x, curPoint.x),
                                   min(mouseDownPoint.y, curPoint.y),
                                   max(mouseDownPoint.x, curPoint.x) - min(mouseDownPoint.x, curPoint.x),
                                   max(mouseDownPoint.y, curPoint.y) - min(mouseDownPoint.y, curPoint.y))
        
        setNeedsDisplayInRect(NSUnionRect(selectionRect, previousSelectionRect))
    }
    // 停止拖拽
    override func mouseUp(theEvent: NSEvent) {
        
        let mouseUpPoint = theEvent.locationInWindow
        let rect = NSMakeRect(min(mouseDownPoint.x, mouseUpPoint.x),
                              min(mouseDownPoint.y, mouseUpPoint.y),
                              max(mouseDownPoint.x, mouseUpPoint.x) - min(mouseDownPoint.x, mouseUpPoint.x),
                              max(mouseDownPoint.y, mouseUpPoint.y) - min(mouseDownPoint.y, mouseUpPoint.y))
        delegate?.drawMouseBoxView(self, didSelectRect: rect)
        
    }
    
    
    // MARK: - 绘制拖拽区域
    override func drawRect(dirtyRect: NSRect) {
        
        NSColor.blackColor().set()
        NSRectFill(dirtyRect)
        NSColor.whiteColor().set()
        NSFrameRect(selectionRect)
    }
}
