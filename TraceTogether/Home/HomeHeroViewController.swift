//
//  HomeHeroViewController.swift
//  OpenTraceTogether

import UIKit
import Lottie

class HomeHeroViewController: UIViewController {
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var heroAnimationView: AnimationView!
    @IBOutlet var heroMoon: UIImageView!
    @IBOutlet weak var buildLabel: UILabel!

    //TODO: Copyright credits
    // https://medium.com/@mr_d_todd/linear-gradients-%C3%A0-la-css-in-swift-3-1-5d29b5de5ae0
    let heroGradient: CAGradientLayer  = CAGradientLayer()

    enum TimeOfDay {
        case Sunrise
        case Day
        case Sunset
        case Night
    }

    let gradientForTime: [TimeOfDay: [CGColor]] = [
        .Sunrise: [
            UIColor(red: 225.0/255.0, green: 236.0/255.0, blue: 253.0/255.0, alpha: 1).cgColor,
            UIColor(red: 255.0/255.0, green: 216.0/255.0, blue: 216.0/255.0, alpha: 1).cgColor,
            UIColor(red: 254.0/255.0, green: 226.0/255.0, blue: 153.0/255.0, alpha: 1).cgColor,
            UIColor(red: 255.0/255.0, green: 242.0/255.0, blue: 218.0/255.0, alpha: 1).cgColor
        ],
        .Day: [
            UIColor(red: 181.0/255.0, green: 225.0/255.0, blue: 255.0/255.0, alpha: 1).cgColor,
            UIColor(red: 207.0/255.0, green: 232.0/255.0, blue: 244.0/255.0, alpha: 1).cgColor,
            UIColor(red: 231.0/255.0, green: 238.0/255.0, blue: 233.0/255.0, alpha: 1).cgColor,
            UIColor(red: 255.0/255.0, green: 244.0/255.0, blue: 223.0/255.0, alpha: 1).cgColor
        ],
        .Sunset: [
            UIColor(hexString: "FFE577").cgColor,
            UIColor(hexString: "FECD5E").cgColor,
            UIColor(hexString: "FED487").cgColor,
            UIColor(hexString: "FFF4DF").cgColor
        ],
        .Night: [
            UIColor(hexString: "144869").cgColor,
            UIColor(hexString: "225A7E").cgColor,
            UIColor(hexString: "316D93").cgColor,
            UIColor(hexString: "3C7CA4").cgColor
        ]
    ]

    let moonDisplayForTime: [TimeOfDay: Bool] = [
        .Sunrise: false,
        .Day: false,
        .Sunset: false,
        .Night: true
    ]

    var timeOfDay: TimeOfDay? {
        willSet {
            guard let value = newValue else {
                return
            }
            heroGradient.colors = gradientForTime[value]
            heroMoon.isHidden = !moonDisplayForTime[value]!

            guard let oldValue = timeOfDay else {
                return
            }

            let animation: CABasicAnimation = CABasicAnimation(keyPath: "colors")
            animation.fromValue = gradientForTime[oldValue]
            animation.toValue = gradientForTime[value]
            animation.duration = 3
            animation.isRemovedOnCompletion = true
            animation.fillMode = CAMediaTimingFillMode.forwards
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
            heroGradient.add(animation, forKey: "animateGradientColorChange")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        heroAnimationView.loopMode = .loop
        heroAnimationView.play()

        heroGradient.startPoint = CGPoint(x: 0.5, y: 0.5)
        heroGradient.endPoint = CGPoint(x: 0.5, y: 1)
        backgroundView.layer.insertSublayer(heroGradient, at: 0)

        #if TEST
        buildLabel.isHidden = false
        buildLabel.text = "🚧🔨👩‍💻TEST👨‍💻🔧🚧"
        #elseif INTERNALRELEASE
        buildLabel.isHidden = false
        buildLabel.text = "🚧🔨👩‍💻INTERNAL👨‍💻🔧🚧"
        #elseif DEBUG
        buildLabel.isHidden = false
        buildLabel.text = "🚧🔨👩‍💻DEBUG👨‍💻🔧🚧"
        #endif
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadView()
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        heroGradient.frame = backgroundView.bounds
    }

    func reloadView() {
        var newTimeOfDay: TimeOfDay
        let hour = Calendar.appCalendar.component(.hour, from: Date())
        switch hour {
        case 5...8:
            newTimeOfDay = .Sunrise
        case 9...16:
            newTimeOfDay = .Day
        case 17...19:
            newTimeOfDay = .Sunset
        case 20...23, 0...4:
            newTimeOfDay = .Night
        default:
            newTimeOfDay = .Day
        }
        timeOfDay = newTimeOfDay
    }

    func stop() {
        heroAnimationView.stop()
        reloadView()
    }

    func play() {
        heroAnimationView.play()
        reloadView()
    }
}
