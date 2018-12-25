//
//  Created by Farshid Ghods on 12/27/16.
//

import UIKit


/*

public class RKSegmentUnitFormatter {
    open var unit : Dimension?
    open var markerTypes: Array<RKRangeMarkerType> = Array()
    open func string(from measurement: Measurement<Unit>) -> String {
    }
}
*/


public enum RKLayerDirection: Int {
    case vertical = 0, horizontal
}


public class RKSegmentUnit: NSObject, NSCopying {
    public var unit: Dimension?
    public var name: String = String()
    public var image: UIImage?
    public var markerTypes: Array<RKRangeMarkerType> = Array()


    public var formatter: MeasurementFormatter? {
        didSet {
            if let formatter = self.formatter {
                if formatter.numberFormatter.numberStyle == .decimal {
                    let numberFormatter: NumberFormatter = NumberFormatter()
                    numberFormatter.paddingPosition = .afterSuffix
                    numberFormatter.maximumFractionDigits = 2
                    formatter.numberFormatter = numberFormatter
                }
            }
        }
    }

    public convenience init(name: String, unit: Dimension, formatter: MeasurementFormatter) {
        self.init()
        self.name = name
        self.unit = unit
        self.formatter = formatter
    }


    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = RKSegmentUnit()
        copy.image = self.image
        copy.name = self.name
        copy.markerTypes = self.markerTypes
        copy.formatter = self.formatter
        return copy
    }
}

public class RKSegmentUnitControlStyle: NSObject {
    public var textFieldBackgroundColor: UIColor = UIColor.clear
    public var textFieldFont: UIFont = kDefaultTextFieldFont
    public var textFieldTextColor: UIColor = UIColor.white
    public var scrollViewBackgroundColor: UIColor = UIColor.clear
    public var colorOverrides: Dictionary<RKRange<Float>, UIColor>?
}


public protocol RKMultiUnitRulerDataSource {

    func unitForSegmentAtIndex(index: Int) -> RKSegmentUnit

    func rangeForUnit(_ unit: Dimension) -> RKRange<Float>

    var numberOfSegments: Int { get set }

    func styleForUnit(_ unit: Dimension) -> RKSegmentUnitControlStyle

}


public protocol RKMultiUnitRulerDelegate {
    func valueChanged(measurement: NSMeasurement)
}


public class RKMultiUnitRuler: UIView {
    public var dataSource: RKMultiUnitRulerDataSource? {
        didSet {
            setupViews()
        }
    }
    public var delegate: RKMultiUnitRulerDelegate?
    public var measurement: NSMeasurement?
    private var segmentControl: UISegmentedControl = UISegmentedControl()
    private var segmentedViews: Array<UIView>?
    private var pointerViews: Array<RKRangePointerView>?
    private var scrollViews: Array<RKRangeScrollView>?
    private var textViews: Array<RKRangeTextView>?
    public var direction: RKLayerDirection = .horizontal

    public required override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }

    private func setupDefaultValues() {

    }

    open func refresh() {
        setupViews()
    }

    private func setupViews() {
        if let _ = self.dataSource {
            self.subviews.forEach({ $0.removeFromSuperview() })
            let segmentControl = setupSegmentControl()
            let (segmentedViews, scrollViews, textViews, pointerViews) = setupSegmentViews()
            self.segmentedViews = segmentedViews
            self.scrollViews = scrollViews
            self.textViews = textViews
            self.pointerViews = pointerViews
            var constraints = Array<NSLayoutConstraint>()
            switch (self.direction) {
            case .horizontal:
                constraints += NSLayoutConstraint.constraints(
                        withVisualFormat: "H:|-5-[segmentControl]-5-|",
                        options: NSLayoutFormatOptions.directionLeadingToTrailing,
                        metrics: nil,
                        views: ["segmentControl": self.segmentControl])
                for segmentView in segmentedViews {
                    constraints += NSLayoutConstraint.constraints(
                            withVisualFormat: "H:|-5-[segmentView]-5-|",
                            options: NSLayoutFormatOptions.directionLeadingToTrailing,
                            metrics: nil,
                            views: ["segmentView": segmentView])
                    constraints += NSLayoutConstraint.constraints(
                            withVisualFormat: "V:|-5-[segmentControl]-5-[segmentView]-5-|",
                            options: NSLayoutFormatOptions.directionLeadingToTrailing,
                            metrics: nil,
                            views: ["segmentView": segmentView, "segmentControl": segmentControl])
                }
            case .vertical:
                constraints += NSLayoutConstraint.constraints(
                        withVisualFormat: "H:|-5-[segmentControl]-5-|",
                        options: NSLayoutFormatOptions.directionLeadingToTrailing,
                        metrics: nil,
                        views: ["segmentControl": self.segmentControl])
                for segmentView in segmentedViews {
                    constraints += NSLayoutConstraint.constraints(
                            withVisualFormat: "H:|-5-[segmentView]-5-|",
                            options: NSLayoutFormatOptions.directionLeadingToTrailing,
                            metrics: nil,
                            views: ["segmentView": segmentView])
                    constraints += NSLayoutConstraint.constraints(
                            withVisualFormat: "V:|-5-[segmentControl]-5-[segmentView]-5-|",
                            options: NSLayoutFormatOptions.directionLeadingToTrailing,
                            metrics: nil,
                            views: ["segmentView": segmentView, "segmentControl": segmentControl])
                }

            }
            segmentControl.addTarget(self,
                    action: #selector(RKMultiUnitRuler.segmentSelectionChanged(_:)),
                    for: UIControlEvents.valueChanged)
            self.addConstraints(constraints)
            self.segmentSelectionChanged(self.segmentControl)
        }
    }

    private func setupSegmentControl() -> UISegmentedControl {
        if let dataSource = self.dataSource {
            self.segmentControl = UISegmentedControl()
            self.segmentControl.translatesAutoresizingMaskIntoConstraints = false
            for index in 0 ... dataSource.numberOfSegments - 1 {
                self.segmentControl.insertSegment(withTitle: dataSource.unitForSegmentAtIndex(
                        index: index).name,
                        at: index, animated: true)
            }

            if (dataSource.numberOfSegments > 0) {
                self.segmentControl.selectedSegmentIndex = 0
                if let unit = dataSource.unitForSegmentAtIndex(index: 0).unit {
                    let style = dataSource.styleForUnit(unit)
                    self.segmentControl.tintColor = UIColor.yellow
                    self.segmentControl.setTitleTextAttributes(
                        [NSAttributedString.Key.foregroundColor: style.textFieldTextColor,
                         NSAttributedString.Key.font: kDefaultSegmentControlTitleFont], for: .normal)
                }
            }
            self.addSubview(self.segmentControl)
            if let tintColor = self.tintColor {
                self.segmentControl.tintColor = tintColor
            }
        }
        return self.segmentControl
    }

    @objc func segmentSelectionChanged(_ sender: UISegmentedControl) {
        if let segmentedViews = self.segmentedViews {
            for i in 0 ... segmentedViews.count - 1 {
                if i == segmentControl.selectedSegmentIndex {
                    segmentedViews[i].isHidden = false
                } else {
                    segmentedViews[i].isHidden = true
                }
                let _ = self.textViews?[i].resignFirstResponder()
            }
        }
        if let dataSource = self.dataSource, let scrollViews = self.scrollViews {
            let segmentUnit = dataSource.unitForSegmentAtIndex(index: segmentControl.selectedSegmentIndex)
            if let measurement = self.measurement, let unit = segmentUnit.unit {
                var value = Float(measurement.converting(to: unit).value)
                let minScale = RKRangeMarkerType.minScale(types: segmentUnit.markerTypes)
                value = Float(lroundf(value / minScale)) * minScale
                self.textViews?[segmentControl.selectedSegmentIndex].currentValue = value
                scrollViews[segmentControl.selectedSegmentIndex].currentValue = value
                scrollViews[segmentControl.selectedSegmentIndex].scrollToCurrentValueOffset()
                let style = dataSource.styleForUnit(unit)
                self.segmentControl.setTitleTextAttributes(
                    [NSAttributedString.Key.foregroundColor: style.textFieldTextColor,
                     NSAttributedString.Key.font: kDefaultSegmentControlTitleFont], for: .normal)
            }
        }
    }

    @objc func scrollViewCurrentValueChanged(_ sender: RKRangeScrollView) {
        if let dataSource = self.dataSource {
            let activeSegmentUnit = dataSource.unitForSegmentAtIndex(
                    index: segmentControl.selectedSegmentIndex)
            if let unit = activeSegmentUnit.unit,
               let scrollViewOfSelectedSegment = self.scrollViews?[segmentControl.selectedSegmentIndex] {
                self.measurement = NSMeasurement(doubleValue: Double(scrollViewOfSelectedSegment.currentValue),
                        unit: unit)
                self.delegate?.valueChanged(measurement: self.measurement!)
                updateTextFields()
            }
        }
    }

    @objc func textViewValueChanged(_ sender: RKRangeTextView) {
        if let dataSource = self.dataSource {
            let activeSegmentUnit = dataSource.unitForSegmentAtIndex(
                    index: segmentControl.selectedSegmentIndex)
            if let textViews = self.textViews, let unit = activeSegmentUnit.unit {
                self.measurement = NSMeasurement(doubleValue: Double(textViews[segmentControl.selectedSegmentIndex].currentValue),
                        unit: unit)
                self.delegate?.valueChanged(measurement: self.measurement!)
            }
            self.updateScrollViews()
        }
    }

    func updateScrollViews() {
        if let dataSource = self.dataSource {
            if let scrollViews = self.scrollViews {
                for index in 0 ... scrollViews.count - 1 {
                    let segmentUnit = dataSource.unitForSegmentAtIndex(index: index)
                    if let measurement = self.measurement, let unit = segmentUnit.unit {
                        let value = Float(measurement.converting(to: unit).value)
                        scrollViews[index].currentValue = value
                    }
                    if index == segmentControl.selectedSegmentIndex {
                        scrollViews[index].scrollToCurrentValueOffset()
                    }
                }
            }
        }
    }

    func updateTextFields() {
        if let dataSource = self.dataSource {
            if let scrollViews = self.scrollViews {
                for index in 0 ... scrollViews.count - 1 {
                    let segmentUnit = dataSource.unitForSegmentAtIndex(index: index)
                    if let measurement = self.measurement, let unit = segmentUnit.unit {
                        var value = Float(measurement.converting(to: unit).value)
                        let minScale = RKRangeMarkerType.minScale(types: segmentUnit.markerTypes)
                        value = Float(lroundf(value / minScale)) * minScale
                        if index != segmentControl.selectedSegmentIndex {
                            self.textViews?[index].currentValue = value
                        } else {
                            DispatchQueue.main.async {
                                let _ = self.textViews?[index].resignFirstResponder()
                                self.textViews?[index].currentValue = value
                            }
                        }
                    }
                }
            }
        }
    }


    private func setupSegmentViews() -> (Array<UIView>, Array<RKRangeScrollView>, Array<RKRangeTextView>, Array<RKRangePointerView>) {
        var segmentViews: [UIView] = []
        var pointerViews: [RKRangePointerView] = []
        var scrollViews: [RKRangeScrollView] = []
        var textViews: [RKRangeTextView] = []
        if let dataSource = self.dataSource {
            var names = Array<String>()
            for index in 0 ... dataSource.numberOfSegments - 1 {
                let segmentView: UIView = UIView(frame: CGRect.zero)
                segmentView.translatesAutoresizingMaskIntoConstraints = false
                let segmentUnit = dataSource.unitForSegmentAtIndex(index: index)
                if let unit = segmentUnit.unit {
                    let style = dataSource.styleForUnit(unit)
                    let range = dataSource.rangeForUnit(unit)
                    names.append(segmentUnit.name)
                    let pointerView = self.setupPointerView(inSegmentView: segmentView,
                            unit: segmentUnit,
                            segmentStyle: style)
                    let scrollView = self.setupSegmentScrollView(inSegmentView: segmentView,
                            unit: segmentUnit, segmentStyle: style,
                            range: range)
                    let textView = self.setupSegmentBottomView(inSegmentView: segmentView,
                            unit: segmentUnit, style: style)
                    let underlineView = self.setupSegmentLineUnderBottomView(inSegmentView: segmentView)
                    let segmentSubViews = ["scrollView": scrollView,
                                           "textView": textView,
                                           "underlineView": underlineView,
                                           "pointerView": pointerView]
                    var constraints = Array<NSLayoutConstraint>()
                    switch (self.direction) {
                    case .vertical:
                        constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-5-[scrollView]-5-|",
                                options: NSLayoutFormatOptions.directionLeadingToTrailing,
                                metrics: nil,
                                views: segmentSubViews)
                        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-5-[pointerView(10)]-0-[scrollView]-5-[textView]-5-|",
                                options: NSLayoutFormatOptions.directionLeadingToTrailing,
                                metrics: nil,
                                views: segmentSubViews)
                        constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-5-[pointerView]-5-|",
                                options: NSLayoutFormatOptions.directionLeadingToTrailing,
                                metrics: nil,
                                views: segmentSubViews)
                        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-5-[pointerView(10)]-0-[scrollView]-5-[underlineView]-5-|",
                                options: NSLayoutFormatOptions.directionLeadingToTrailing,
                                metrics: nil,
                                views: segmentSubViews)
                        constraints += NSLayoutConstraint.constraints(
                                withVisualFormat: "V:|-10-[textView(25)]-1-[underlineView(2)]",
                                options: NSLayoutFormatOptions.alignAllCenterX,
                                metrics: nil,
                                views: segmentSubViews)
                    case .horizontal:
                        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-5-[scrollView]-5-|",
                                options: NSLayoutFormatOptions.directionLeadingToTrailing,
                                metrics: nil,
                                views: segmentSubViews)
                        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-5-[textView]-5-|",
                                options: NSLayoutFormatOptions.directionLeadingToTrailing,
                                metrics: nil,
                                views: segmentSubViews)
                        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-5-[pointerView]-5-|",
                                options: NSLayoutFormatOptions.directionLeadingToTrailing,
                                metrics: nil,
                                views: segmentSubViews)
                        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-5-[underlineView]-5-|",
                                options: NSLayoutFormatOptions.directionLeadingToTrailing,
                                metrics: nil,
                                views: segmentSubViews)
                        constraints += NSLayoutConstraint.constraints(
                                withVisualFormat: "V:|-5-[pointerView(10)]-0-[scrollView]-5-[textView(25)]-1-[underlineView(2)]-5-|",
                                options: NSLayoutFormatOptions.directionLeadingToTrailing,
                                metrics: nil,
                                views: segmentSubViews)
                    }
                    self.backgroundColor = style.scrollViewBackgroundColor
                    segmentView.addConstraints(constraints)
                    segmentView.backgroundColor = style.scrollViewBackgroundColor
                    segmentViews.append(segmentView)
                    scrollViews.append(scrollView)
                    textViews.append(textView)
                    pointerViews.append(pointerView)
                    self.addSubview(segmentView)
                }
            }
        }
        return (segmentViews, scrollViews, textViews, pointerViews)
    }

    private func setupPointerView(inSegmentView parent: UIView,
                                  unit segmentUnit: RKSegmentUnit,
                                  segmentStyle style: RKSegmentUnitControlStyle) -> RKRangePointerView {
        let pointerView = RKRangePointerView(frame: self.bounds)
        pointerView.translatesAutoresizingMaskIntoConstraints = false
        pointerView.direction = self.direction
        pointerView.backgroundColor = style.scrollViewBackgroundColor
        parent.addSubview(pointerView)
        return pointerView
    }

    private func setupSegmentScrollView(inSegmentView parent: UIView,
                                        unit segmentUnit: RKSegmentUnit,
                                        segmentStyle style: RKSegmentUnitControlStyle,
                                        range floatRange: RKRange<Float>) -> RKRangeScrollView {
        let scrollView = RKRangeScrollView(frame: self.bounds)
        scrollView.markerTypes = segmentUnit.markerTypes
        scrollView.backgroundColor = style.scrollViewBackgroundColor
        scrollView.range = floatRange
        scrollView.colorOverrides = style.colorOverrides
        scrollView.direction = self.direction
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addTarget(self,
                action: #selector(RKMultiUnitRuler.scrollViewCurrentValueChanged(_:)),
                for: .valueChanged)
        parent.addSubview(scrollView)
        return scrollView
    }

    private func setupSegmentBottomView(inSegmentView parent: UIView,
                                        unit segmentUnit: RKSegmentUnit,
                                        style: RKSegmentUnitControlStyle) -> RKRangeTextView {
        let textView = RKRangeTextView(frame: self.bounds)
        textView.backgroundColor = style.textFieldBackgroundColor
        textView.textField.backgroundColor = style.textFieldBackgroundColor
        textView.textField.textColor = style.textFieldTextColor
        textView.unit = segmentUnit.unit
        textView.formatter = segmentUnit.formatter
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.addTarget(self,
                action: #selector(RKMultiUnitRuler.textViewValueChanged(_:)),
                for: .valueChanged)
        parent.addSubview(textView)
        return textView
    }


    private func setupSegmentLineUnderBottomView(inSegmentView parent: UIView) -> UIView {
        let view = UIView(frame: self.bounds)
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(view)
        return view
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        if let segmentedViews = self.segmentedViews {
            for segmentView in segmentedViews {
                segmentView.layoutSubviews()
            }
        }
        updateScrollViews()
        updateTextFields()
    }
}
