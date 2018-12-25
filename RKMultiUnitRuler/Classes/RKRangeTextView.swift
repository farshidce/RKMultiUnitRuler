//
// Created by Farshid Ghods on 12/28/16.
// Copyright (c) 2016 Rekovery. All rights reserved.
//

import UIKit

/*
    string extension to facilitate conversion of string to double, int and float
*/
public extension String {
    var doubleValue: Double? {
        return NumberFormatter().number(from: self)?.doubleValue
    }
    var integerValue: Int? {
        return NumberFormatter().number(from: self)?.intValue
    }
    var floatValue: Float? {
        return NumberFormatter().number(from: self)?.floatValue
    }
}

class RKRangeTextView: UIControl, UITextFieldDelegate {

    var textField: UITextField = UITextField()
    var formatter: MeasurementFormatter?
    var unit: Dimension?

    public var currentValue: Float = 0 {
        didSet {
            if (!self.textField.isFirstResponder) {
                self.updateTextFieldText(value: currentValue)
            }
        }
    }


    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTextView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupTextView()
    }

    /*
        Internal method used for updating the TextField using the formatter if applicable
        If the textField is the first responder then it will also retain the cursor position
    */
    private func updateTextFieldText(value: Float) {
        var originalCursorPosition : UITextPosition? = nil
        if (self.textField.isFirstResponder) {
            if let selectedRange = textField.selectedTextRange {
                originalCursorPosition = textField.position(from: selectedRange.start, offset: 1)
            }
        }
        if let formatter = self.formatter, let unit = self.unit {
            let measurement = Measurement(value: Double(value), unit: unit)
            self.textField.text = formatter.string(from: measurement)
        } else {
            self.textField.text = String(format: "%.1f", value)
        }
        if let position = originalCursorPosition {
            self.textField.selectedTextRange = textField.textRange(
                    from: position, to: position)
        }
    }

    /*
        Creates a new UITextField and assigns the constraint programmatically
    */
    func setupTextView() {
        self.textField.removeFromSuperview()
        let textField = UITextField(frame: self.bounds)
        textField.textAlignment = NSTextAlignment.center
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.isUserInteractionEnabled = true
        textField.text = "0"
        textField.keyboardType = .decimalPad
        textField.delegate = self
        self.addSubview(textField)
        let views = ["textField": textField]
        var constraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-5-[textField]-5-|",
                options: NSLayoutFormatOptions.directionLeadingToTrailing,
                metrics: nil,
                views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-5-[textField]-5-|",
                options: NSLayoutFormatOptions.directionLeadingToTrailing,
                metrics: nil,
                views: views)
        self.addConstraints(constraints)
        self.textField = textField
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }

    /*
        Set the cursor to the beginning of the document
    */
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.beginningOfDocument)
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
    }

    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
    }

    /*
        If string is empty or "." then let the user continue updating the text
        If string can be parsed to Float then invoke the updateTextFieldText method to format the text
        else let the user continue modifying the text
    */
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty || string == "." {
            return true
        }
        let textFieldText = (textField.text ?? "") as NSString?
        let updatedString = textFieldText?.replacingCharacters(in: range, with: string)
        if let unit = self.unit {
            print("updatedString : \(String(describing: updatedString))")
            if let updatedStringAsFloat = updatedString?.replacingOccurrences(
                    of: unit.symbol, with: "").floatValue {
                currentValue = updatedStringAsFloat
                self.updateTextFieldText(value: currentValue)
                self.sendActions(for: UIControlEvents.valueChanged)
                return false
            }
            return true
        } else {
            if let updatedStringAsFloat = updatedString?.floatValue {
                currentValue = updatedStringAsFloat
                self.sendActions(for: UIControlEvents.valueChanged)
            }
            return true
        }
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }

    override func resignFirstResponder() -> Bool {
        if (self.textField.isFirstResponder) {
            self.textField.resignFirstResponder()
        }
        return super.resignFirstResponder()
    }


}
