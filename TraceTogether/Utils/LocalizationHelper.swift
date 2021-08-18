//
//  LocalizationHelper.swift
//  OpenTraceTogether
import Foundation

struct LocalizationHelper {
    static func updateLocalizedAttributedString(localizedKey: String, localizedComment: String, _ attributedString: NSAttributedString) -> NSAttributedString? {
            let mutableAttributedText = attributedString.mutableCopy() as! NSMutableAttributedString
            let string = NSLocalizedString(localizedKey, comment: localizedComment)
            mutableAttributedText.mutableString.setString(string)

            return mutableAttributedText as NSAttributedString
    }

}
