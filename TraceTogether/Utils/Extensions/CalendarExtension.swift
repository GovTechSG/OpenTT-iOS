//
//  CalendarExtension.swift
//  OpenTraceTogether

import Foundation

extension Calendar {
    static var appCalendar: Calendar {
        return Calendar(identifier: .gregorian)
    }
}
