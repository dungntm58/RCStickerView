//
//  Util+Extension.swift
//  Pods-RCStickerView_Example
//
//  Created by Robert Nguyen on 11/2/18.
//

import Foundation

extension CGRect {
    
    // CGRectGetCenter
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
    
    // CGRectScale
    func scale(w: CGFloat, h: CGFloat) -> CGRect {
        return CGRect(x: origin.x, y: origin.y, width: width * w, height: height * h)
    }
    
    mutating func scaled(w: CGFloat, h: CGFloat) {
        size.width = width * w
        size.height = height * h
    }
}

extension CGAffineTransform {
    
    // CGAffineTransformGetAngle
    var angle: CGFloat {
        return atan2(b, a)
    }
}

// CGPointGetDistance
func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
    let fx = point2.x - point1.x
    let fy = point2.y - point1.y
    return sqrt(fx * fx + fy * fy)
}

internal extension UIView {
    // Flip view horizontally
    func flipX() {
        transform = CGAffineTransform(scaleX: -transform.a, y: transform.d)
    }
    
    // Flip view vertically.
    func flipY() {
        transform = CGAffineTransform(scaleX: transform.a, y: -transform.d)
    }
}
