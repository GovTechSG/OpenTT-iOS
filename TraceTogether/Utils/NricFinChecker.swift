//
//  NricFinChecker.swift
//  OpenTraceTogether

import Foundation

struct NricFinChecker {
    static func validNricFin(_ nricFinInput: String, profileType: ProfileType) -> Bool {
        //Add logic for front-end NRIC and FIN format validation
        return true
    }

    static func checkIdType(idType: String) -> ProfileType {
           var profileType = ProfileType.NRIC

           if idType == "finWP" {
               profileType = ProfileType.FINWorkPass
           } else if idType == "finDP" {
               profileType = ProfileType.FINDependentPass
           } else if idType == "finSTP" {
               profileType = ProfileType.FINStudentPass
           } else if idType == "finLTVP" {
               profileType = ProfileType.FINLongTermVisitorPass
           } else if idType == "passport" {
               profileType = ProfileType.Visitor
           } else if idType == "nric" {
               profileType = ProfileType.NRIC
           }
           return profileType
       }
}

struct PassportChecker {
    static func validPassport(_ passportNumber: String) -> Bool {
        let trimmedPassport = passportNumber.filter { !$0.isWhitespace }
        if trimmedPassport.isEmpty {
            return false
        }
        return trimmedPassport.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil
    }
}
