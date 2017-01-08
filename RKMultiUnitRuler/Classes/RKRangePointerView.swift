//
// Created by Farshid Ghods on 1/6/17.
// Copyright (c) 2017 Rekovery. All rights reserved.
//


import UIKit
import QuartzCore


public enum RKRangePointerShape: Int {
    case triangle = 0, square
}


public class RKRangePointerView: UIView {

    var shape: RKRangePointerShape = .triangle
    var sideOffset = kDefaultPointerLayerSideOffset
    var fillColor: UIColor = UIColor.white
    var lineColor: UIColor = UIColor.white
    var direction: RKLayerDirection = .horizontal
    var radius: CGFloat = 6.0


    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentMode = .redraw
    }


    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.contentMode = .redraw
    }


    override public func draw(_ rect: CGRect) {
        let center = CGPoint(x: self.bounds.size.width / 2.0, y: self.bounds.size.height / 2.0)
        //
        //
        //            A ------ B
        //              \    /
        //               \  /
        //                \/
        //                 C
        let alpha = self.radius * 3 / sqrt(3)
        let pointA: CGPoint?
        let pointB: CGPoint?
        let pointC: CGPoint?
        switch self.direction {
        case .horizontal:
            pointA = CGPoint(x: center.x - 1 / 2 * alpha, y: self.sideOffset)
            pointB = CGPoint(x: center.x + 1 / 2 * alpha, y: self.sideOffset)
            pointC = CGPoint(x: center.x, y: self.bounds.height - self.sideOffset)
        case .vertical:
            pointA = CGPoint(x: self.sideOffset, y: center.y - 1 / 2 * alpha)
            pointB = CGPoint(x: self.sideOffset, y: center.y + 1 / 2 * alpha)
            pointC = CGPoint(x: self.bounds.width - self.sideOffset, y: center.y)
        }
        if let ctx = UIGraphicsGetCurrentContext(), let a = pointA, let b = pointB, let c = pointC {
            ctx.beginPath()
            ctx.move(to: c)
            ctx.addLine(to: b)
            ctx.addLine(to: a)
            ctx.addLine(to: c)
            ctx.setFillColor(self.fillColor.cgColor)
            ctx.setStrokeColor(self.lineColor.cgColor)
            ctx.setLineWidth(0.5)
            ctx.drawPath(using: .fillStroke)
        }
    }
}
