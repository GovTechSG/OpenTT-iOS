//
//  UIViewController+Extension.swift
//  OpenTraceTogether

import Foundation
import UIKit

extension UIViewController {
    // Calling this function will add a tap gesture to the view. On tap, the keyboard will be dismissed
    func dismissKeyboardOnTap() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(OTPViewController.dismissKeyboard))
               view.addGestureRecognizer(tap)
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    func makeBulletedAttributedString(stringList: [String],
                                      font: UIFont,
                                      bullet: String = "\u{2022}",
                                      indentation: CGFloat = 12,
                                      lineSpacing: CGFloat = 2,
                                      paragraphSpacing: CGFloat = 5,
                                      textColor: UIColor = UIColor.white,
                                      bulletColor: UIColor = UIColor.white) -> NSAttributedString {

        let termsOfUseUrl = "https://www.safeentry-qr.gov.sg/termsofuse"
        let textAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: textColor]
        let bulletAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: bulletColor]

        let paragraphStyle = NSMutableParagraphStyle()
        let nonOptions = [NSTextTab.OptionKey: Any]()
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: .left, location: indentation, options: nonOptions)]
        paragraphStyle.defaultTabInterval = indentation
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.paragraphSpacing = paragraphSpacing
        paragraphStyle.headIndent = indentation

        let bulletAttribtedList = NSMutableAttributedString()
        for (index, string) in stringList.enumerated() {
            print(index)
            let formattedString = "\(bullet)\t\(string)\n"
            let attributedString = NSMutableAttributedString(string: formattedString)

            //Check last string in array, Highlight Terms string and make it a hyperlink
            if index == stringList.endIndex-1 {
                if let languageCode = Locale.current.languageCode {
                    switch languageCode {
                    case "en":
                        attributedString.addAttribute(.link, value: termsOfUseUrl, range: NSRange(location: 18, length: 6))
                        break
                    case "ta":
                        attributedString.addAttribute(.link, value: termsOfUseUrl, range: NSRange(location: 10, length: 8))
                        break
                    case "bn":
                        attributedString.addAttribute(.link, value: termsOfUseUrl, range: NSRange(location: 92, length: 9))
                        break
                    case "ms":
                        attributedString.addAttribute(.link, value: termsOfUseUrl, range: NSRange(location: 21, length: 5))
                        break
                    case "zh":
                        attributedString.addAttribute(.link, value: termsOfUseUrl, range: NSRange(location: 7, length: 2))
                        break
                    case "th":
                        attributedString.addAttribute(.link, value: termsOfUseUrl, range: NSRange(location: 11, length: 18))
                        break
                    case "my":
                        attributedString.addAttribute(.link, value: termsOfUseUrl, range: NSRange(location: 78, length: 16))
                        break
                    case "hi":
                        attributedString.addAttribute(.link, value: termsOfUseUrl, range: NSRange(location: 5, length: 6))
                        break
                    default:
                        print("No other language")
                    }
                }
            }

            attributedString.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle], range: NSRange(location: 0, length: attributedString.length))
            attributedString.addAttributes(textAttributes, range: NSRange(location: 0, length: attributedString.length))

            let string = NSString(string: formattedString)
            let rangeForBullet = string.range(of: bullet)
            attributedString.addAttributes(bulletAttributes, range: rangeForBullet)
            bulletAttribtedList.append(attributedString)
        }
        return bulletAttribtedList.trimmedAttributedString(set: CharacterSet.whitespacesAndNewlines)
    }
}

extension UIViewController {
    func showAlertWithMessage(_ title: String, message: String, completion: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: completion))
        self.present(alert, animated: true)
        //self.present(alert, animated: true)
    }
}
