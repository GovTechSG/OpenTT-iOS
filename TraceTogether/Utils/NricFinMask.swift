//
//  NricFinMask.swift
//  OpenTraceTogether

import Foundation

struct NricFinMask {
    static func maskUserId(_ userIdValue: String) -> String {
        let idLength = userIdValue.count
        if idLength <= 0 {
            return userIdValue
        }
        let start = userIdValue.index(userIdValue.startIndex, offsetBy: 1)
        var end: String.Index
        var dotCount: Int

        if idLength <= 5 {
            end = userIdValue.index(userIdValue.endIndex, offsetBy: 0)
            dotCount = idLength - 1

        } else {
            end = userIdValue.index(userIdValue.endIndex, offsetBy: -4)
            dotCount = 4
        }

        let range = start..<end
        let secureString = userIdValue.replacingCharacters(in: range, with: String(repeating: "•", count: dotCount))

        //If there's a functional flaw in the logic to maskUserId, we might end up storing actual credentials in the UserDefaults.
        //solution: Compare the masked string and actual NRIC, and store only when mismatch
        if secureString == userIdValue {
            print("NRIC security error")
            LogMessage.create(type: .Error, title: #function, details: "NRIC security error")
            return ""
        }
        return secureString
    }

    static func getAccessibilityLabel(_ userIdValue: String) -> String {
        var label = ""
        var gotFirstDot = false
        for c in userIdValue {
            if (c == "•") {
                if (!gotFirstDot) {
                    label.append("\(NSLocalizedString("HiddenCharacters", comment: "Hidden Characters")). ")
                    gotFirstDot = true
                }
            } else {
                label.append("\(c). ")
            }
        }
        return label
    }
}
