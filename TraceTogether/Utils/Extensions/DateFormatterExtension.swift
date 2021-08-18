//
//  DateFormatterExtension.swift
//  OpenTraceTogether

import Foundation

extension DateFormatter {
    static func appDateFormatter(format: String) -> DateFormatter {
        let df = DateFormatter()
        df.dateFormat = format
        df.calendar = Calendar.appCalendar
        df.locale = Locale.appLocale
        df.timeZone = TimeZone.current
        return df
    }

    /// Convert a string from one date format to another without hassle. e.g. input `30-12-2020` output `30-DEC-2020`
    static func convert(_ string: String, from dateFormat1: String, to dateFormat2: String) -> String {
        let date = DateFormatter.appDateFormatter(format: dateFormat1).date(from: string)
        return date == nil ? "" : DateFormatter.appDateFormatter(format: dateFormat2).string(from: date!)
    }
}
