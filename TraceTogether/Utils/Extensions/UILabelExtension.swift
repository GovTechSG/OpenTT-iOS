//
//  UILabelExtension.swift
//  OpenTraceTogether

import UIKit

extension UILabel {
    func semiBold(text: String) {
        guard let lblTxt = self.text,
            let range = lblTxt.range(of: text)  else { return }
        let nsRange = NSRange(range, in: lblTxt)
        let attrString = NSMutableAttributedString(string: lblTxt)
        attrString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: self.font.pointSize, weight: .bold), range: nsRange)
        self.attributedText = attrString
    }

    var isAttributed: Bool {
        guard let attributedText = attributedText else { return false }
        let range = NSRange(location: 0, length: attributedText.length)
        var allAttributes = [[NSAttributedString.Key: Any]]()
        attributedText.enumerateAttributes(in: range, options: []) { attributes, _, _ in
            allAttributes.append(attributes)
        }
        return !allAttributes.isEmpty
    }

    @IBInspectable var lineHeight: CGFloat {
        set (lineHeight) {
            setLineHeight(lineHeight: lineHeight)
        }

        get {
            return self.lineHeight
        }
    }

    func setLineHeight(lineHeight: CGFloat) {
        if isAttributed {
            let mutableAttributedText: NSMutableAttributedString = attributedText!.mutableCopy() as! NSMutableAttributedString
            let style = NSMutableParagraphStyle()
            style.lineSpacing = lineHeight
            style.alignment = textAlignment

            mutableAttributedText.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSRange(location: 0, length: mutableAttributedText.length))
            self.attributedText = mutableAttributedText

        } else {
            let text = self.text
            if let text = text {
                let attributeString = NSMutableAttributedString(string: text)
                let style = NSMutableParagraphStyle()

                style.lineSpacing = lineHeight
                style.alignment = textAlignment
                attributeString.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSRange(location: 0, length: text.count))
                self.attributedText = attributeString
            }
        }
    }

    func setText(string: String, boldStrings: [String]?) {
        let newAttrString = NSMutableAttributedString(string: string)

        boldStrings?.forEach({ (boldString) in
            let range = (string as NSString).range(of: boldString)
            let boldFont = UIFont.boldSystemFont(ofSize: font.pointSize)
            newAttrString.addAttributes([NSAttributedString.Key.font: boldFont], range: range)
        })

        self.attributedText = newAttrString
    }
}

extension NSMutableAttributedString {
    func attributedText(withString string: String, multiBoldDict: [String: String]) -> NSMutableAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.17

        let normalfont = UIFont.systemFont(ofSize: 16, weight: .regular)
        let boldfont = UIFont.systemFont(ofSize: 16, weight: .bold)
        let attributedString = NSMutableAttributedString(string: string,
                                                         attributes: [NSAttributedString.Key.font: normalfont, NSAttributedString.Key.kern: 0.25, NSAttributedString.Key.paragraphStyle: paragraphStyle])
        let boldFontAttribute: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: boldfont, NSAttributedString.Key.kern: 0.25, NSAttributedString.Key.paragraphStyle: paragraphStyle]

        for linkString in multiBoldDict {
             let range = (string as NSString).range(of: linkString.key)
             attributedString.addAttributes(boldFontAttribute, range: range)
         }
        return attributedString
    }

    func attributedText(withString string: String, boldString: String) -> NSMutableAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.17

        let normalfont = UIFont.systemFont(ofSize: 16, weight: .regular)
        let boldfont = UIFont.systemFont(ofSize: 16, weight: .bold)
        let attributedString = NSMutableAttributedString(string: string,
                                                         attributes: [NSAttributedString.Key.font: normalfont, NSAttributedString.Key.kern: 0.25, NSAttributedString.Key.paragraphStyle: paragraphStyle])

        let boldFontAttribute: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: boldfont, NSAttributedString.Key.kern: 0.25, NSAttributedString.Key.paragraphStyle: paragraphStyle]
        let range = (string as NSString).range(of: boldString)
        attributedString.addAttributes(boldFontAttribute, range: range)
        return attributedString
    }

    func attributedText(withString string: String, underlineString: String) -> NSMutableAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.17
        paragraphStyle.alignment = .center

        let normalfont = UIFont.systemFont(ofSize: 16, weight: .regular)
        let underlineFont = [NSAttributedString.Key.underlineStyle: 1] as [NSAttributedString.Key: Any]

        let attributedString = NSMutableAttributedString(string: string,
                                                         attributes: [NSAttributedString.Key.font: normalfont, NSAttributedString.Key.kern: 0.25, NSAttributedString.Key.paragraphStyle: paragraphStyle])
        let range = (string as NSString).range(of: underlineString)
        attributedString.addAttributes(underlineFont, range: range)
        return attributedString
    }

    func attributedText(withString string: String, boldString: String, underlineStrings: [String]) -> NSMutableAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.17

        let normalfont = UIFont.systemFont(ofSize: 16, weight: .regular)
        let boldfont = UIFont.systemFont(ofSize: 16, weight: .bold)
        let underlineFont = [NSAttributedString.Key.underlineStyle: 1] as [NSAttributedString.Key: Any]

        let attributedString = NSMutableAttributedString(string: string,
                                                         attributes: [NSAttributedString.Key.font: normalfont, NSAttributedString.Key.kern: 0.25, NSAttributedString.Key.paragraphStyle: paragraphStyle])
        let boldFontAttribute: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: boldfont, NSAttributedString.Key.kern: 0.25, NSAttributedString.Key.paragraphStyle: paragraphStyle]
        let range = (string as NSString).range(of: boldString)
        attributedString.addAttributes(boldFontAttribute, range: range)

        for underlineString in underlineStrings {
            let range = (string as NSString).range(of: underlineString)
            attributedString.addAttributes(underlineFont, range: range)
        }

        return attributedString
    }

    func trimmedAttributedString(set: CharacterSet) -> NSMutableAttributedString {
        let invertedSet = set.inverted
        var range = (string as NSString).rangeOfCharacter(from: invertedSet)
        let location = range.length > 0 ? range.location : 0
        range = (string as NSString).rangeOfCharacter(
                            from: invertedSet, options: .backwards)
        let length = (range.length > 0 ? NSMaxRange(range) : string.count) - location
        let attributedString = self.attributedSubstring(from: NSRange(location: location, length: length))
        return NSMutableAttributedString(attributedString: attributedString)
    }
}
