# RKMultiUnitRuler
[![CI Status](https://travis-ci.org/farshidce/RKMultiUnitRuler.svg?style=flat)](https://travis-ci.org/farshidce/RKMultiUnitRuler)
[![Version](https://img.shields.io/cocoapods/v/RKMultiUnitRuler.svg?style=flat)](http://cocoapods.org/pods/RKMultiUnitRuler)
[![License](https://img.shields.io/cocoapods/l/RKMultiUnitRuler.svg?style=flat)](http://cocoapods.org/pods/RKMultiUnitRuler)
[![Platform](https://img.shields.io/cocoapods/p/RKMultiUnitRuler.svg?style=flat)](http://cocoapods.org/pods/RKMultiUnitRuler)

## RKMultiUnitRuler - Customizable Ruler Control for iOS

A cocoa pod that simplies process of setting and reading values for different units. This control let the user
specify multiple units ( e.g Kilograms and Pound) and specify markers for each unit and then let the user
modify the value via scrolling or updating the textfield.

![Demo image](https://s3.amazonaws.com/farshid.ghods.github/rkmultiunitruler-1.gif)


## Requirements
* iOS 10 or higher

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

RKMultiUnitRuler is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```
pod "RKMultiUnitRuler"
```
and run pod install in terminal.
Usage

## RKMultiUnitRuler

### Compatibility

iOS 10+

xCode 8.0+

Swift 3.0

####You can use storyboard to create a control element.


 
### Features
- Extremely simple and easy to use
- Customizable interface
- Compatible with iOS 10.0 NSUnit Framework
- Supports multiple units
- Customize marker colors based on type or their value
- Customize the width, length and number of markers of the ruler
- Customize the unit formatter


## How to use


```swift
class ViewController: UIViewController, RKMultiUnitRulerDataSource, RKMultiUnitRulerDelegate {

}
```

 Set the ruler direction to horizontal

```swift
ruler.direction = .horizontal
```

```swift
ruler.direction = .vertical
```
![Vertical Ruler](https://s3.amazonaws.com/farshid.ghods.github/ruler-vertical-1.jpg)

Specify how many units the ruler will display

```swift
    var numberOfSegments: Int {
        get {
            return 2.0
        }
    }
```

Define multiple units (Pounds and Kilograms).
In the example below we are creating two markers for Kilogram unit at 0.1 and 1.0 scale but we are creating one marker for Pounds.
For instance if the range is between 10-12 the "Kgs" ruler will have markers for 10.0,10.1,10.2...11.0,11.1...12.0
and the "lbs" ruler will display markers at 3.0, 4.0,...,26.0.


```swift
    func unitForSegmentAtIndex(index: Int) -> RKSegmentUnit {
        return segments[index]
    
    let formatter = MeasurementFormatter()
    formatter.unitStyle = .medium
    formatter.unitOptions = .providedUnit
    let kgSegment = RKSegmentUnit(name: "Kilograms", unit: UnitMass.kilograms, formatter: formatter)
    kgSegment.markerTypes = [
        RKRangeMarkerType(color: UIColor.white, size: CGSize(width: 1.0, height: 35.0), scale: 0.1),
        RKRangeMarkerType(color: UIColor.white, size: CGSize(width: 1.0, height: 50.0), scale: 1.0)]
    let lbsSegment = RKSegmentUnit(name: "Pounds", unit: UnitMass.pounds, formatter: formatter)
    lbsSegment.markerTypes = [
            RKRangeMarkerType(color: UIColor.white, size: CGSize(width: 1.0, height: 35.0), scale: 1.0)]
    kgSegment.markerTypes.last?.labelVisible = true
    lbsSegment.markerTypes.last?.labelVisible = true
    return [lbsSegment, kgSegment]
}


```

The ruler will display markers between 30.0 and 130. kgs. rangeForUnit function needs
to be implemented for returning the range for the given unit. Please note that
ceilf method is used in order to round the float numbers to the closest int.

```swift

var rangeStart = Measurement(value: 30.0, unit: UnitMass.kilograms)
var rangeLength = Measurement(value: Double(130), unit: UnitMass.kilograms)

func rangeForUnit(_ unit: Dimension) -> RKRange<Float> {
   let locationConverted = rangeStart.converted(to: unit as! UnitMass)
   let lengthConverted = rangeLength.converted(to: unit as! UnitMass)
   return RKRange<Float>(location: ceilf(Float(locationConverted.value)),
                         length: ceilf(Float(lengthConverted.value)))
}
    
```


Customize the style and font used for markers and the scroll views

```swift
let style: RKSegmentUnitControlStyle = RKSegmentUnitControlStyle()
style.scrollViewBackgroundColor = UIColor.blue
style.textFieldBackgroundColor = UIColor.red
style.textFieldBackgroundColor = UIColor.clear
style.textFieldTextColor = UIColor.white
return style
```

In order to apply multiple colors to the ruler for each unit you can set the colorOverrides property as shown below

```swift
style.colorOverrides = [
        RKRange<Float>(location: range.location, length: 0.1 * (range.length)): UIColor.red,
        RKRange<Float>(location: range.location + 0.4 * (range.length), length: 0.2 * (range.length)): UIColor.green]
        
```

![Multi-color Markers](https://s3.amazonaws.com/farshid.ghods.github/ruler-color-1.jpg)


Implement RKMultiUnitRulerDataSource protocol in order to customize units, range and the style used for drawing the markers
```swift
    func unitForSegmentAtIndex(index: Int) -> RKSegmentUnit

    func rangeForUnit(_ unit: Dimension) -> RKRange<Float>

    var numberOfSegments: Int { get set }

    func styleForUnit(_ unit: Dimension) -> RKSegmentUnitControlStyle
```

To get the latest value that the user has picked, implement RKMultiUnitRulerDelegate.

```swift
    func valueChanged(measurement: NSMeasurement) {
        print("value changed to \(measurement.doubleValue)")
    }
```


## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.


## Support

If you have any other questions regarding the use of this library, please contact us for support at info@cleveroad.com (email subject: "CRRulerControl. Support request.") 

## Author

[Farshid Ghods](farshid.ghods@gmail.com)

## License

The MIT License (MIT)

Copyright (c) 2016 Cleveroad Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
