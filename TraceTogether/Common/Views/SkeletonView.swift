//
//  SkeletonView.swift
//  OpenTraceTogether

import Foundation
import UIKit

class SkeletonView: UIView {
    var gradientColorOne: CGColor = UIColor(white: 0.89, alpha: 1.0).cgColor
    var gradientColorTwo: CGColor = UIColor(white: 0.94, alpha: 1.0).cgColor
    var gradientLayer: CAGradientLayer?

    func addGradientLayer() -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.bounds
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.colors = [gradientColorOne, gradientColorTwo, gradientColorOne]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        self.gradientLayer = gradientLayer
        self.layer.addSublayer(gradientLayer)
        return gradientLayer
    }

    func addAnimation() -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue = [1.0, 1.5, 2.0]
        animation.repeatCount = .infinity
        animation.duration = 0.9
        return animation
    }

    func startAnimating() {
        let gradientLayer = addGradientLayer()
        let animation = addAnimation()
        gradientLayer.add(animation, forKey: animation.keyPath)
    }

    func stopAnimating() {
        self.gradientLayer?.removeAllAnimations()
        self.gradientLayer?.removeFromSuperlayer()
        self.layer.removeAllAnimations()
    }
}
