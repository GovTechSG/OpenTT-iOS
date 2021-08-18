//
//  UploadFileData.swift
//  OpenTraceTogether

import Foundation

struct DeviceInfo: Codable {
    var os: String
    var model: String
}

struct UploadFileData: Encodable {
    var token: String
    var device: DeviceInfo
    var records: [Encounter]
    var btLiteRecords: [LiteEncounter]
    var btV3Records: [V3Encounter]
    var ttId: String
}
