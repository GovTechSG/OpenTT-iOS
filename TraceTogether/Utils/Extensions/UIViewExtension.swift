//
//  UIViewExtension.swift
//  OpenTraceTogether

import UIKit
import QuartzCore

extension UIView {

    @IBInspectable
    var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }

    @IBInspectable
    var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    @IBInspectable
    var borderColor: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.borderColor = color.cgColor
            } else {
                layer.borderColor = nil
            }
        }
    }

    @IBInspectable
    var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
        }
    }

    @IBInspectable
    var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
        }
    }

    @IBInspectable
    var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
        }
    }

    @IBInspectable
    var shadowColor: UIColor? {
        get {
            if let color = layer.shadowColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.shadowColor = color.cgColor
            } else {
                layer.shadowColor = nil
            }
        }
    }

}

//Have made a separate extension for new methods
extension UIView {

    var isVisible: Bool {
        get {
            return !self.isHidden
        }
        set {
            self.isHidden = !newValue
        }
    }
    func fadeTransition(_ duration: CFTimeInterval) {
           let animation = CATransition()
           animation.timingFunction = CAMediaTimingFunction(name:
               CAMediaTimingFunctionName.easeInEaseOut)
           animation.type = CATransitionType.fade
           animation.duration = duration
           layer.add(animation, forKey: CATransitionType.fade.rawValue)
    }
    func shadow(height: Double) {
        if height != 0 {
            self.layer.masksToBounds = false
            self.layer.shadowRadius = 1
            self.layer.shadowOpacity = 0.25
            self.layer.shadowColor = UIColor.black.cgColor
            self.layer.shadowOffset = CGSize(width: 0, height: height)
        }
    }

     func removeShadow() {
         self.layer.shadowOffset = CGSize(width: 0, height: 0)
         self.layer.shadowColor = UIColor.clear.cgColor
         self.layer.cornerRadius = 0.0
         self.layer.shadowRadius = 0.0
         self.layer.shadowOpacity = 0.0
     }

    func setBottomCurve() {
           let offset = CGFloat(700)
           let bounds = self.bounds

        let rectBounds = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: bounds.size.width, height: bounds.size.height / 2)
           let rectPath = UIBezierPath(rect: rectBounds)
           let ovalBounds = CGRect(x: bounds.origin.x - offset / 2, y: bounds.origin.y, width: bounds.size.width + offset, height: bounds.size.height)

           let ovalPath = UIBezierPath(ovalIn: ovalBounds)
       rectPath.append(ovalPath)

           let maskLayer = CAShapeLayer()
           maskLayer.frame = bounds
           maskLayer.path = rectPath.cgPath
           self.layer.mask = maskLayer
       }

    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
         let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
         let mask = CAShapeLayer()
         mask.path = path.cgPath
         self.layer.mask = mask
    }

}
