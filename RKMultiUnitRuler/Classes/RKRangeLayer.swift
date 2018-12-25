//
// Created by Farshid Ghods on 12/27/16.
// Copyright (c) 2016 Rekovery. All rights reserved.
//

import UIKit
import QuartzCore


public enum RKMarkerVerticalAlignment: Int {
    case bottom = 0, center, top
}


public class RKRange<T>: NSObject {
    open var location: T
    open var length: T

    public init(location: T, length: T) {
        self.location = location
        self.length = length
        super.init()
    }

    public override var description: String {
        return String("location : \(self.location) length: \(self.length)")
    }

    public override var debugDescription: String {
        return String("location : \(self.location) length: \(self.length)")
    }
}


public class RKRangeMarkerType: NSObject, NSCopying {
    open var name: String?
    open var scale: Float = 1
    open var image: UIImage?
    open var labelVisible: Bool = false
    open var size: CGSize = CGSize(width: 2.0, height: 10.0)
    open var color: UIColor = UIColor.white
    open var font: UIFont = kDefaultMarkerTypeFont

    public convenience init(color: UIColor, size: CGSize, scale: Float) {
        self.init()
        self.color = color
        self.size = size
        self.scale = scale
    }

    public override var description: String {
        return String("scale : \(self.scale) name: \(String(describing: self.name)) " +
                "color: \(self.color) font: \(self.font.description) size: \(self.size.debugDescription)")
    }

    class func minScale(types: Array<RKRangeMarkerType>?) -> Float {
        var minScale = Float.greatestFiniteMagnitude
        if let types = types {
            for markerType in types {
                minScale = fmin(markerType.scale, minScale)
            }
        }
        return minScale
    }

    class func largestScale(types: Array<RKRangeMarkerType>?) -> Float {

        var largestScale = Float.leastNormalMagnitude
        if let types = types {
            for markerType in types {
                largestScale = fmax(markerType.scale, largestScale)
            }
        }
        return largestScale
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = RKRangeMarkerType()
        copy.scale = self.scale
        copy.name = self.name
        copy.color = self.color
        copy.font = self.font
        copy.image = self.image
        copy.size = self.size
        copy.labelVisible = self.labelVisible
        return copy
    }
}

class RKRangeMarker: NSObject {
    var type: RKRangeMarkerType = RKRangeMarkerType()
    var value: Float = 0.0
    var alignment: RKMarkerVerticalAlignment = RKMarkerVerticalAlignment.top
    var text: String = ""
    var textAlignment: RKMarkerVerticalAlignment = RKMarkerVerticalAlignment.bottom
    var textFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = NumberFormatter.Style.decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }

    public override var description: String {
        return String("value: \(self.value)  text: \(self.text)")
    }

    public override var debugDescription: String {
        return String("type : \(self.type) value: \(self.value) " +
                "textAlignment \(self.textAlignment)" +
                "alignment: \(self.alignment) text: \(self.text) textAlignment: \(self.textAlignment)")
    }
}

class RKRangeLayer: CALayer {
    var direction: RKLayerDirection = .horizontal
    var markerTypes: Array<RKRangeMarkerType> = Array()
    var colorOverrides: Dictionary<RKRange<Float>, UIColor>?

    var range: RKRange<Float> = RKRange<Float>(location: 0, length: 0) {
        didSet {
            if range.length != 0 {
                self.setNeedsDisplay()
            }
        }
    }

    lazy var markers: Array<RKRangeMarker> = self.initializeMarkers()

    override var frame: CGRect {
        didSet {
            if (oldValue != self.frame) {
                self.markers = self.initializeMarkers()
                self.setNeedsDisplay()
            }
        }
    }

    override func display() {
        super.display()

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.drawLayer()
        CATransaction.commit()
    }

    func initializeMarkers() -> Array<RKRangeMarker> {
        var valueToMarkerMap: [Float: RKRangeMarker] = [:]
        if (self.frame.size.width > 0 && self.markerTypes.count > 0) {
            let rangeStart = fmin(self.range.location, self.range.location + self.range.length)
            let rangeEnd = fmax(self.range.location, self.range.location + self.range.length)
            let sortedMarkerTypes = self.markerTypes.sorted {
                $0.scale < $1.scale
            }
            for markerType in sortedMarkerTypes {
                var location = rangeStart
                while location <= rangeEnd {
                    let marker = RKRangeMarker()
                    marker.text = String(location)
                    marker.value = location
                    marker.type = markerType
                    valueToMarkerMap[location] = marker
                    location = location + markerType.scale
                }
            }
        }
        return valueToMarkerMap.values.sorted {
            $0.value < $1.value
        }
    }

    private func colorOverride(for location: Float) -> UIColor? {
        if let overrides = self.colorOverrides {
            for (range, color) in overrides {
                let rangeStart = fmin(range.location, range.location + range.length)
                let rangeEnd = fmax(range.location, range.location + range.length)
                if rangeStart <= location && location <= rangeEnd {
                    return color
                }
            }
        }
        return nil
    }

    /*
        Draw the markers
    */
    func drawLayer() {
        UIGraphicsBeginImageContextWithOptions(self.frame.size, false, UIScreen.main.scale);
        var position: Float = Float(kDefaultScrollViewSideOffset)
        var distanceBetweenLeastScaleMarkers: Float = 0.0
        switch self.direction {
        case .horizontal:
            distanceBetweenLeastScaleMarkers = Float(self.frame.width) / range.length
        case .vertical:
            distanceBetweenLeastScaleMarkers = Float(self.frame.height) / range.length
        }
        var previousMarker: RKRangeMarker?
        if let context = UIGraphicsGetCurrentContext() {
            for marker in self.markers {
                if let previousMarker = previousMarker {
                    position = position + (marker.value - previousMarker.value) * distanceBetweenLeastScaleMarkers
                }
                switch (self.direction) {
                case .horizontal:
                    self.drawMarkerInHorizontalDirection(marker, at: CGFloat(position), in: context)
                case .vertical:
                    self.drawMarkerInVerticalDirection(marker, at: CGFloat(position), in: context)
                }
                previousMarker = marker
            }
            if let imageToDraw = UIGraphicsGetImageFromCurrentImageContext() {
                UIGraphicsEndImageContext();
                imageToDraw.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
                contents = imageToDraw.cgImage
            }
        }
    }

    /*
        Draw one marker. If marker.labelVisible is true then draw its numerical
        representation.
        marker.type.size is used for drawing the "thin" line that represents each
        marker
    */
    func drawMarkerInHorizontalDirection(_ marker: RKRangeMarker, at pos: CGFloat, in context: CGContext) {
        let rangeEnd = fmax(self.range.location, self.range.location + self.range.length)
        let colorOverride = self.colorOverride(for: marker.value)
        let color = colorOverride ?? marker.type.color
        let textAttributes = [
            NSAttributedStringKey.font: marker.type.font,
            NSAttributedStringKey.foregroundColor: marker.type.color
        ] as [NSAttributedStringKey: Any]
        let textSize = NSString(string: marker.text).size(withAttributes: textAttributes)
        let xPos = pos - marker.type.size.width / 2
        var yPos: CGFloat = 0.0

        switch (marker.alignment) {
        case .bottom:
            yPos = (self.frame.size.height - marker.type.size.height) / 2.0
        case .center:
            yPos = self.frame.size.height - marker.type.size.height - textSize.height
        case .top:
            yPos = 0
        }

        let textXPos = pos - textSize.width / 2
        var textYPos: CGFloat = 0.0

        switch (marker.textAlignment) {
        case .bottom:
            textYPos = textSize.height + marker.type.size.height
        case .center:
            textYPos = textSize.height + (marker.type.size.height) / 2
        case .top:
            textYPos = 0
        }
        let markerRect = CGRect(x: xPos, y: yPos, width: marker.type.size.width, height: marker.type.size.height)
        let markerTextRect = CGRect(x: textXPos, y: textYPos, width: textSize.width, height: textSize.height)
        context.setFillColor(color.cgColor)
        context.fill(markerRect)
        if marker.value >= rangeEnd || marker.type.labelVisible {
            NSString(string: marker.text).draw(in: markerTextRect, withAttributes: textAttributes)
        }
    }

    func drawMarkerInVerticalDirection(_ marker: RKRangeMarker, at pos: CGFloat, in context: CGContext) {
        let rangeEnd = fmax(self.range.location, self.range.location + self.range.length)
        let colorOverride = self.colorOverride(for: marker.value)
        let color = colorOverride ?? marker.type.color
        let textAttributes = [
            NSAttributedStringKey.font.rawValue: marker.type.font,
            NSAttributedStringKey.foregroundColor: marker.type.color
            ] as! [NSAttributedStringKey: Any]
        let textSize = NSString(string: marker.text).size(withAttributes: textAttributes)

        let yPos = self.frame.height - pos - marker.type.size.width / 2
        var xPos: CGFloat = 0.0


        switch (marker.alignment) {
        case .bottom:
            xPos = (self.frame.size.width - marker.type.size.height - textSize.width) / 2.0
        case .center:
            xPos = self.frame.size.width - marker.type.size.height - textSize.width
        case .top:
            xPos = 0
        }

        let textYPos = self.frame.height - pos - textSize.width / 2
        var textXPos: CGFloat = 0.0

        switch (marker.textAlignment) {
        case .bottom:
            textXPos = textSize.width + marker.type.size.height
        case .center:
            textXPos = textSize.width + (marker.type.size.height) / 2
        case .top:
            textXPos = 0
        }
        let markerRect = CGRect(x: xPos,
                y: yPos,
                width: marker.type.size.height,
                height: marker.type.size.width)
        let markerTextRect = CGRect(x: textXPos, y: textYPos, width: textSize.width, height: textSize.height)
        context.setFillColor(color.cgColor)
        context.fill(markerRect)
        if marker.value >= rangeEnd || marker.type.labelVisible {
            NSString(string: marker.text).draw(in: markerTextRect, withAttributes: textAttributes)
        }
    }
}
