//
//  StringExtension.swift
//  OpenTraceTogether

import Foundation

extension String {
    mutating func appendLine(_ other: String) {
        self.append("\(other)\n")
    }

    func appendLine(to fileURL: URL) throws {
        try (self + "\n").append(to: fileURL)
    }

    func append(to fileURL: URL) throws {
        let data = self.data(using: String.Encoding.utf8)!
        try data.append(to: fileURL)
    }

    func removeHTMLTag() -> String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: String.CompareOptions.regularExpression, range: nil)
     }
}
