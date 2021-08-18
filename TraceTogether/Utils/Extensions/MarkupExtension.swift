//
//  MarkupExtension.swift
//  OpenTraceTogether

import UIKit

/**
 This class is to help create `AttributedString` using a nice markup format. e.g. `"This is <b>bold</b>"`.
 You can add markup inside markup. e.g. `"This is <b>bold and <u>underline inside bold</u> </b>"`.
 You can add parameter inside markup. e.g. set font size 14 `"Normal size <fs:14>smaller size</fs>"`.
 Current limitation: Can't do markup inside markup for`b` and `i`. If needed, create another tag e.g. `bi` : `"<b>bold <bi>italic</bi></b>"`
 Supported tags :
 - `b` for `bold`
 - `i` for `italic`
 - `u` for `underline`
 - `c` for `color` e.g. `<c:#FFFFFF>white</c>`. Check `UIColor(hexString:)` for the color format
 - `a` for `link` e.g. `<a:google>go to google</a>`. Put your link in `Markup.links`.
 - `lh` for `line height` e.g. `<lh:21> line height 21 </lh>`.
 - `ls` for `line spacing` e.g. `<ls:4> add 4 more points for line spacing </ls>`.
 - `fs` for `font size` e.g. `<fs:14> This is 14 points text </fs>`.
 - `li` for `list`. Add indent for multi lines. Do nothing on single line.
 - `ca` for `center-align`.
 */
struct Markup {
    class Tag {
        var name = ""
        var value = ""
        var range = NSRange(location: 0, length: 0)
    }

    static let links = [
        "terms": "https://www.tracetogether.gov.sg/common/terms-of-use",
        "privacy": "https://www.tracetogether.gov.sg/common/privacystatement",
        "ica": "https://safetravel.ica.gov.sg"
    ]

    static func parse(markupString: String) -> (String, [Tag]) {
        var isTag = false
        var isRemoveTag = false
        var isValue = false
        var name = ""
        var value = ""

        var tags = [Tag]()
        var text = ""

        for c in markupString {
            switch c {
            case "<":
                isTag = true
            case ">":
                if (!isRemoveTag) {
                    let tag = Tag()
                    tag.name = name
                    tag.value = value
                    tag.range.location = text.unicodeScalars.count
                    tags.append(tag)
                } else {
                    let tag = tags.last(where: { $0.range.length == 0 })!
                    tag.range.length = text.unicodeScalars.count - tag.range.location
                }
                isTag = false
                isRemoveTag = false
                isValue = false
                name = ""
                value = ""
            case ":":
                if (isTag && !isValue) {
                    isValue = true
                } else {
                    fallthrough
                }
            case "/":
                if (isTag && !isValue) {
                    isRemoveTag = true
                } else {
                    fallthrough
                }
            default:
                if (isTag) {
                    if (isValue) {
                        value.append(c)
                    } else {
                        name.append(c)
                    }
                } else {
                    text.append(c)
                }
            }
        }
        return (text, tags)
    }

    /// Convert `markupString` to `attributedString` using specific `font`.
    static func getAttributedString(markupString: String?, font: UIFont) -> NSAttributedString {
        let (text, tags) = parse(markupString: markupString ?? "")

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = round(font.pointSize * 1.4)

        let attrString = NSMutableAttributedString(string: text, attributes: [.paragraphStyle: paragraphStyle])
        for tag in tags {
            switch tag.name {
            case "b":
                attrString.addAttribute(.font, value: UIFont(descriptor: font.fontDescriptor.withSymbolicTraits(.traitBold)!, size: 0), range: tag.range)
            case "i":
                attrString.addAttribute(.font, value: UIFont(descriptor: font.fontDescriptor.withSymbolicTraits(.traitItalic)!, size: 0), range: tag.range)
            case "u":
                attrString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: tag.range)
            case "c":
                attrString.addAttribute(.foregroundColor, value: UIColor(hexString: tag.value), range: tag.range)
            case "a":
                attrString.addAttributes([.link: links[tag.value]!, .foregroundColor: UIColor(hexString: "#2E7FED")], range: tag.range)
            case "lh": //line height
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.minimumLineHeight = CGFloat(Float(tag.value)!)
                attrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: tag.range)
            case "ls": //line spacing
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.minimumLineHeight = CGFloat(Float(tag.value)!)
                paragraphStyle.lineSpacing = CGFloat(Float(tag.value)!)
                attrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: tag.range)
            case "fs": //font size
                let size = CGFloat(Float(tag.value)!)
                attrString.addAttribute(.font, value: UIFont(descriptor: font.fontDescriptor, size: size), range: tag.range)
            case "li": //list
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 22, options: [:])]
                paragraphStyle.headIndent = 22
                paragraphStyle.paragraphSpacing = 16
                attrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: tag.range)
            case "ca": //center-align
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                attrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: tag.range)
            default:
                break
            }
        }
        return attrString
    }
}

extension UILabel {
    /// Set the current text in storyboard/xib as a markup string.
    @IBInspectable var isMarkupText: Bool {
        get { return false }
        set { newValue ? setAttributedText(markupString: text) : nil }
    }

    func setAttributedText(markupString: String?) {
        attributedText = Markup.getAttributedString(markupString: markupString, font: font)
    }
}

extension UIButton {
    /// Set the current text in storyboard/xib as a markup string.
    @IBInspectable var isMarkupText: Bool {
        get { return false }
        set { newValue ? setAttributedTitle(title(for: .normal), for: .normal) : nil }
    }

    open func setAttributedTitle(_ markupString: String?, for state: UIControl.State) {
        setAttributedTitle(Markup.getAttributedString(markupString: markupString, font: titleLabel!.font), for: state)
    }
}

extension UITextView {
    /// Set the current text in storyboard/xib as a markup string.
    @IBInspectable var isMarkupText: Bool {
        get { return false }
        set { newValue ? setAttributedText(markupString: text) : nil }
    }

    func setAttributedText(markupString: String?) {
        /// UITextView is so buggy compare to UIText and UIButton. Need to re-assign font and text color for the whole text.
        let attrString = Markup.getAttributedString(markupString: markupString, font: font!) as! NSMutableAttributedString
        let range = NSRange(location: 0, length: attrString.string.unicodeScalars.count)
        attrString.addAttributes([.font: font!, .foregroundColor: textColor!], range: range)
        attributedText = attrString
    }
}
