//
// Created by Farshid Ghods on 12/27/16.
//

import UIKit
import QuartzCore

class RKRangeScrollView: UIControl, UIScrollViewDelegate {

    open var sideOffset: CGFloat = kDefaultScrollViewSideOffset
    open var direction: RKLayerDirection = .horizontal
    open var colorOverrides: Dictionary<RKRange<Float>, UIColor>?
    open var range: RKRange<Float> = RKRange<Float>(location: 0, length: 0) {
        didSet {
            setupScrollView()
            currentValue = ceilf((range.location + range.length) / 2.0)
        }
    }
    var markerTypes: Array<RKRangeMarkerType>? {
        didSet {
            setupScrollView()
        }
    }

    var automaticallyUpdatingScroll: Bool = false
    public var currentValue: Float = 0
    var scrollView: UIScrollView = UIScrollView()
    var rangeLayer: RKRangeLayer = RKRangeLayer()


    override init(frame: CGRect) {
        super.init(frame: frame)
        setupScrollView()

    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupScrollView()
    }

    func setupScrollView() {
        if let _ = self.markerTypes {
            self.subviews.forEach({ $0.removeFromSuperview() })
            self.scrollView = UIScrollView(frame: self.bounds)
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            scrollView.delegate = self
            scrollView.bounces = false
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.showsVerticalScrollIndicator = false
            self.setupRangeLayer()
            self.addSubview(scrollView)
        }
    }


    func setupRangeLayer() {
        if let markerTypes = self.markerTypes {
            self.rangeLayer = RKRangeLayer()
            self.rangeLayer.range = self.range
            self.rangeLayer.markerTypes = markerTypes
            self.scrollView.layer.addSublayer(rangeLayer)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupScrollView()
    }


    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (!automaticallyUpdatingScroll) {
            let oldValue = currentValue
            let minScale = RKRangeMarkerType.minScale(types: self.markerTypes)
            let rawValue = self.valueForContentOffset(contentOffset: self.scrollView.contentOffset)
            self.currentValue = Float(lroundf(rawValue / minScale)) * minScale
            if (oldValue != currentValue) {
                self.sendActions(for: UIControl.Event.valueChanged)
            }
        }
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {

    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        var value = self.valueForContentOffset(contentOffset: targetContentOffset.pointee)
        let minScale = RKRangeMarkerType.minScale(types: self.markerTypes)
        value = Float(lroundf(value / minScale)) * minScale
        switch self.direction {
        case .horizontal:
            targetContentOffset.pointee.x = self.contentOffsetForValue(value: value).x
        case .vertical:
            targetContentOffset.pointee.y = self.contentOffsetForValue(value: value).y
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
    }

    /*
        trigger "valueChanged" once deceleration is completed.
    */
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if (!automaticallyUpdatingScroll) {
            let oldValue = self.valueForContentOffset(contentOffset: self.scrollView.contentOffset)
            let minScale = RKRangeMarkerType.minScale(types: self.markerTypes)
            self.currentValue = Float(lroundf(oldValue / minScale)) * minScale
            self.sendActions(for: UIControl.Event.valueChanged)
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    }

    func viewForZooming(`in` scrollView: UIScrollView) -> UIView? {
        return nil
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return false
    }

    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
    }

    func contentOffsetForValue(value: Float) -> CGPoint {
        let rangeStart = fmin(self.range.location, self.range.location + self.range.length)
        switch self.direction {
        case .horizontal:
            let contentOffset: CGFloat = CGFloat(value - rangeStart) * self.offsetCoefficient() - scrollView.contentInset.left
            return CGPoint(x: contentOffset, y: scrollView.contentOffset.y)
        case .vertical:
            let contentOffset: CGFloat = self.rangeLayer.frame.height - CGFloat(value - rangeStart) * self.offsetCoefficient() -
                    scrollView.contentInset.top - 2*self.sideOffset
            return CGPoint(x: scrollView.contentOffset.x, y: contentOffset)
        }
    }

    func scrollToCurrentValueOffset() {
        UIView.animate(withDuration: 0.2,
                animations: {
                    self.automaticallyUpdatingScroll = true
                    self.scrollView.setContentOffset(self.contentOffsetForValue(value: self.currentValue), animated: false)
                },
                completion: { completed in
                    self.automaticallyUpdatingScroll = false
                })
    }

    func valueForContentOffset(contentOffset: CGPoint) -> Float {
        let rangeStart = fmin(self.range.location, self.range.location + self.range.length)
        switch self.direction {
        case .horizontal:
            let value = Float(rangeStart) + Float(contentOffset.x + self.scrollView.contentInset.left) / Float(self.offsetCoefficient())
            return value
        case .vertical:
            let value = Float(rangeStart) + Float(self.rangeLayer.frame.height -
                    (contentOffset.y + 2*self.sideOffset + self.scrollView.contentInset.top)) / Float(self.offsetCoefficient())
            return value
        }
    }

    func offsetCoefficient() -> CGFloat {
        switch self.direction {
        case .horizontal:
            return self.self.rangeLayer.frame.width / CGFloat(abs(range.length))
        case .vertical:
            return self.self.rangeLayer.frame.height / CGFloat(abs(range.length))
        }
    }

    /*
        Use self.sideOffset as the margin for the left and right.
        Use the RangeLayer width as the content width and retain scrollView height

    */
    override func layoutSubviews() {
        super.layoutSubviews()
        self.rangeLayer.direction = self.direction
        self.rangeLayer.colorOverrides = colorOverrides
        switch (self.direction) {
        case .horizontal:
            let sideInset = self.scrollView.frame.width / 2.0
            self.scrollView.contentInset = UIEdgeInsets.init(
                    top: 0, left: sideInset - self.sideOffset, bottom: 0, right: sideInset - self.sideOffset)
        case .vertical:
            let sideInset = self.scrollView.frame.height / 2.0
            self.scrollView.contentInset = UIEdgeInsets.init(
                    top: sideInset - self.sideOffset, left: 0, bottom: sideInset - self.sideOffset, right: 0)
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.rangeLayer.frame = self.frameForRangeLayer()
        CATransaction.commit()
        switch (self.direction) {
        case .horizontal:
            self.scrollView.contentSize = CGSize(width: self.rangeLayer.frame.width, height: self.frame.size.height)
        case .vertical:
            self.scrollView.contentSize = CGSize(width: self.frame.width, height: self.rangeLayer.frame.size.height)
        }
        self.scrollView.contentOffset = self.contentOffsetForValue(value: self.currentValue)
    }

    func frameForRangeLayer() -> CGRect {
        let maxScale = RKRangeMarkerType.largestScale(types: self.markerTypes)
        let scaleFitsInScreen = range.length < 5 * maxScale ? 1 : 5 * maxScale
        switch (self.direction) {
        case .horizontal:
            let widthPerScale = Float(self.bounds.size.width) / scaleFitsInScreen
            let width = min(widthPerScale * self.range.length, kRangeLayerMaximumWidth)
            return CGRect(x: 0.0, y: 0.0, width: Double(width), height: Double(self.frame.height))
        case .vertical:
            let heightPerScale = Float(self.bounds.size.height) / scaleFitsInScreen
            let height = min(heightPerScale * self.range.length, kRangeLayerMaximumHeight)
            return CGRect(x: 0.0, y: 0.0, width: Double(self.frame.width), height: Double(height))
        }
    }
}
