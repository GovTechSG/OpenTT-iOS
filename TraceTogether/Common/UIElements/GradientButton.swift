//
//  GradientButton.swift
//  OpenTraceTogether

import UIKit

@IBDesignable
class GradientButton: UIButton {
    let gradientLayer = CAGradientLayer()

    @IBInspectable
    var topGradientColor: UIColor?

    @IBInspectable
    var bottomGradientColor: UIColor?

    @IBInspectable
    var startPoint: CGPoint = CGPoint(x: 0, y: 0)

    @IBInspectable
    var endPoint: CGPoint = CGPoint(x: 0, y: 1)

    @IBInspectable
    var startLocation: Float = 0.0

    @IBInspectable
    var endLocation: Float = 1.0

    private func setGradient(topGradientColor: UIColor?, bottomGradientColor: UIColor?) {
        if let topGradientColor = topGradientColor, let bottomGradientColor = bottomGradientColor {
            gradientLayer.frame = bounds
            gradientLayer.colors = [topGradientColor.cgColor, bottomGradientColor.cgColor]
            gradientLayer.borderColor = layer.borderColor
            gradientLayer.borderWidth = layer.borderWidth
            gradientLayer.cornerRadius = layer.cornerRadius
            gradientLayer.startPoint = startPoint
            gradientLayer.endPoint = endPoint
            gradientLayer.locations = [NSNumber(value: startLocation), NSNumber(value: endLocation)]
            layer.insertSublayer(gradientLayer, at: 0)
        } else {
            gradientLayer.removeFromSuperlayer()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        setGradient(topGradientColor: topGradientColor, bottomGradientColor: bottomGradientColor)
    }

}
