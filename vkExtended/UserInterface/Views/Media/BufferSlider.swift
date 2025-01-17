//
//  BufferSlider.swift
//  vkExtended
//
//  Created by Ярослав Стрельников on 19.11.2020.
//

import Foundation

import UIKit

let padding:CGFloat = 0;
///Enum of vertical position
public enum VerticalPosition:Int{
    case top = 1
    case center = 2
    case bottom = 3
}

/// - Easily use
/// - Easily customize
/// - Drop-In replacement
/// - Supports **Objective-C** and **Swift**
/// - *@IBDesignable* class *BufferSlider*
/// - *@IBInspectable* property *bufferStartValue* (*Swift.Double*)
/// - 0.0 ~ 1.0
/// - *@IBInspectable* property *bufferEndValue* (*Swift.Double*)
/// - 0.1 ~ 1.0
/// - *@IBInspectable* property *borderColor* (*UIKit.UIColor*)
/// - *@IBInspectable* property *fillColor* (*UIKit.UIColor*)
/// - *@IBInspectable* property *borderWidth* (*Swift.Double*)
/// - *@IBInspectable* property *sliderHeight* (*Swift.Double*)
@IBDesignable open class BufferSlider: UISlider {
    ///0.0 ~ 1.0. @IBInspectable
    @IBInspectable open var bufferStartValue: Double = 0 {
        didSet{
            if bufferStartValue < 0.0 {
                bufferStartValue = 0
            }
            if bufferStartValue > bufferEndValue {
                bufferStartValue = bufferEndValue
            }
            self.setNeedsDisplay()
        }
    }
    ///0.0 ~ 1.0. @IBInspectable
    @IBInspectable open var bufferEndValue: Double = 0 {
        didSet{
            if bufferEndValue > 1.0 {
                bufferEndValue = 1
            }
            if bufferEndValue < bufferStartValue {
                bufferEndValue = bufferStartValue
            }
            self.setNeedsDisplay()
        }
    }
    
    ///0.0 ~ 1.0. @IBInspectable
    @IBInspectable open var newValue: Float = 0 {
        didSet{
            if newValue > 1.0 {
                newValue = 1
            }
            if value < newValue {
                value = newValue
            }
            self.setNeedsDisplay()
        }
    }
    
    ///baseColor property. @IBInspectable
    @IBInspectable open var baseColor: UIColor = UIColor.lightGray
    
    ///progressColor property. @IBInspectable
    @IBInspectable open var progressColor: UIColor? = nil
    
    ///bufferColor property. @IBInspectable
    @IBInspectable open var bufferColor: UIColor? = nil

    ///BorderWidth property. @IBInspectable
    @IBInspectable open var sliderBorderWidth: Double = 0.0 {
        didSet{
            if sliderBorderWidth < 0.1 {
                sliderBorderWidth = 0.0
            }
            self.setNeedsDisplay()
        }
    }
    
    ///Slider height property. @IBInspectable
    @IBInspectable open var sliderHeight: Double = 3 {
        didSet{
            if sliderHeight < 1 {
                sliderHeight = 1
            }
        }
    }
    ///Adaptor property. Stands for vertical position of slider. (Swift and Objective-C)
    /// - 1 -> Top
    /// - 2 -> Center
    /// - 3 -> Bottom
    @IBInspectable open var sliderPositionAdaptor: Int {
        get {
            return sliderPosition.rawValue
        }
        set{
            let r = abs(newValue) % 3
            switch r {
            case 1:
                sliderPosition = .top
            case 2:
                sliderPosition = .center
            case 0:
                sliderPosition = .bottom
            default:
                sliderPosition = .center
            }
        }
    }
    ///Vertical position of slider. (Swift only)
    open var sliderPosition: VerticalPosition = .center
    
    ///Draw round corner or not
    @IBInspectable open var roundedSlider: Bool = true
    
    ///Draw hollow or solid color
    @IBInspectable open var hollow: Bool = true
    
    ///Do not call this delegate mehtod directly. This is for hiding built-in slider drawing after iOS 7.0
    open override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var result = super.trackRect(forBounds: bounds)
        result.size.height = 0.01
        result.origin.y = 15
        return result
    }
    
    ///Custom Drawing. Subclass and and override to suit you needs.
    open override func draw(_ rect: CGRect) {
        baseColor.set()
        let rect = self.bounds.insetBy(dx: CGFloat(borderWidth) + padding, dy: CGFloat(borderWidth))
        let height = sliderHeight.cgFloat
        let radius = height / 2
        var sliderRect = CGRect(x: rect.origin.x, y: rect.origin.y + (rect.height / 2 - radius), width: rect.width, height: rect.width) //default center
        switch sliderPosition {
        case .top:
            sliderRect.origin.y = rect.origin.y
        case .bottom:
            sliderRect.origin.y = rect.origin.y + rect.height - sliderRect.height
        default:
            break
        }

        let path = UIBezierPath()
        if roundedSlider {
            path.addArc(withCenter: CGPoint(x: sliderRect.minX + radius, y: sliderRect.minY + radius), radius: radius, startAngle: CGFloat(Double.pi) / 2, endAngle: -CGFloat(Double.pi) / 2, clockwise: true)
            path.addLine(to: CGPoint(x: sliderRect.maxX - radius, y: sliderRect.minY))
            path.addArc(withCenter: CGPoint(x: sliderRect.maxX - radius, y: sliderRect.minY + radius), radius: radius, startAngle: -CGFloat(Double.pi) / 2, endAngle: CGFloat(Double.pi) / 2, clockwise: true)
            path.addLine(to: CGPoint(x: sliderRect.minX + radius, y: sliderRect.minY + height))
        } else {
            path.move(to: CGPoint(x: sliderRect.minX, y: sliderRect.minY + height))
            path.addLine(to: sliderRect.origin)
            path.addLine(to: CGPoint(x: sliderRect.maxX, y: sliderRect.minY))
            path.addLine(to: CGPoint(x: sliderRect.maxX, y: sliderRect.minY + height))
            path.addLine(to: CGPoint(x: sliderRect.minX, y: sliderRect.minY + height))
        }

        baseColor.setStroke()
        path.lineWidth = sliderBorderWidth.cgFloat
        path.stroke()
        if !hollow {
            path.fill()
        }
        path.addClip()
        
        var fillHeight = sliderRect.size.height - borderWidth
        if fillHeight < 0 {
            fillHeight = 0
        }
        
        let fillRectBuffer = CGRect(x: sliderRect.origin.x + sliderRect.size.width * CGFloat(bufferStartValue), y: sliderRect.origin.y + borderWidth / 2, width: sliderRect.size.width * (bufferEndValue - bufferStartValue).cgFloat, height: fillHeight)
        if let color = bufferColor {
            color.setFill()
        } else if let color = self.superview?.tintColor{
            color.setFill()
        } else {
            UIColor(red: 0.0, green: 122.0 / 255.0, blue: 1.0, alpha: 1.0).setFill()
        }
        
        UIBezierPath(rect: fillRectBuffer).fill()
        
        let fillRectProgress = CGRect(x: sliderRect.origin.x, y: sliderRect.origin.y + borderWidth / 2, width: sliderRect.size.width * newValue.cgFloat + 2, height: fillHeight)
        if let color = progressColor {
            color.setFill()
        }
        UIBezierPath(rect: fillRectProgress).fill()
    }
}
