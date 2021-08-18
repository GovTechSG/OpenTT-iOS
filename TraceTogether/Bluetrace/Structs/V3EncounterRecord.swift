//
//  V3EncounterRecord.swift
//  OpenTraceTogether

import Foundation

struct V3EncounterRecord: Encodable, Record {
    var msg: String?
    var role: String?
    var timestamp: Date?

    mutating func update(msg: String) {
        self.msg = msg
    }

    init(msg: String, role: String) {
        self.timestamp = Date()
        self.msg = msg
        self.role = role
    }

}
