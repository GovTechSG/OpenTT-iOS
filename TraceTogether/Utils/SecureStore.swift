//
//  SecureStore.swift
//  OpenTraceTogether

import Foundation
import LocalAuthentication

struct KeychainConfiguration {
     static let serviceName = "nricService"
     static let accessGroup: String? = nil
     static let account: String = "id"
     static let familyMembers: String = "familyMembers"
 }

public struct SecureStore {

    /// The username and password that we want to store or read.
    struct Credentials {
        var username: String
        var password: String
    }

    /// Keychain errors we might encounter.
    struct KeychainError: Error {
        var status: OSStatus

        var localizedDescription: String {
            //            return status as Int32
            if #available(iOS 11.3, *) {
                return SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error."
            } else {
                return "KeychainError: \(self)"
            }
        }
    }

    // MARK: - Keychain Access

    /// Add credentials to the device.
    static func addOrUpdateCredentials(_ credentials: Credentials, service: String) throws {
        // Use the username as the account, and get the password as data.
        let account = credentials.username
        let password = credentials.password.data(using: String.Encoding.utf8)!

        // Build the query for use in the add operation.
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: account,
                                    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
                                    kSecValueData as String: password]

        var status = SecItemCopyMatching(query as CFDictionary, nil)

        switch status {
        case errSecSuccess:
            var attributesToUpdate: [String: Any] = [:]
            attributesToUpdate[String(kSecValueData)] = password
            status = SecItemUpdate(query as CFDictionary,
                                   attributesToUpdate as CFDictionary)
            if status != errSecSuccess {
                let keychainError = KeychainError(status: status)
                LogMessage.create(type: .Error, title: #function, details: keychainError.localizedDescription)
                throw keychainError
            }
        case errSecItemNotFound:
            status = SecItemAdd(query as CFDictionary, nil)
            if status != errSecSuccess {
                let keychainError = KeychainError(status: status)
                LogMessage.create(type: .Error, title: #function, details: keychainError.localizedDescription)
                throw keychainError
            }
        default:
            let keychainError = KeychainError(status: status)
            LogMessage.create(type: .Error, title: #function, details: keychainError.localizedDescription)
            throw keychainError
        }
    }

    static func deleteCredentials(service: String, account: String) throws {
        // Build the query for use in the add operation.
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: account,
                                    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked]

        var status = SecItemCopyMatching(query as CFDictionary, nil)

        switch status {
        case errSecSuccess:
            status = SecItemDelete(query as CFDictionary)
            if status != errSecSuccess {
                throw KeychainError(status: status)
            }
        case errSecItemNotFound:
            status = SecItemAdd(query as CFDictionary, nil)
            if status != errSecSuccess {
                throw KeychainError(status: status)
            }
        default:
            throw KeychainError(status: status)
        }
    }

    /// Reads the stored credentials for the given service.
    static func readCredentials(service: String, accountName: String) throws -> Credentials {

        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: accountName,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecUseAuthenticationUI as String: kSecUseAuthenticationUISkip,
                                    kSecReturnAttributes as String: true,
                                    kSecReturnData as String: true]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { throw KeychainError(status: status) }

        guard let existingItem = item as? [String: Any],
            let passwordData = existingItem[kSecValueData as String] as? Data,
            let password = String(data: passwordData, encoding: String.Encoding.utf8),
            let account = existingItem[kSecAttrAccount as String] as? String
            else {
            let keychainError = KeychainError(status: errSecInternalError)
            LogMessage.create(type: .Error, title: #function, details: keychainError.localizedDescription)
            throw keychainError
        }

        return Credentials(username: account, password: password)
    }
}

extension SecureStore {
    
    static func getUnmaskedIDs(maskedIDs: [String]) throws -> [String] {
        let maskedGroupIDs = maskedIDs.map { (id) -> String in
            let lastFour = String(id.suffix(4))
            return lastFour
        }
        let allFamilyMembers = try getAllFamilyMembers()
        var unmaskedGroupIDs: [String] = []
        maskedGroupIDs.forEach {
            if let unmaskedID = getUnmaskedIDForID(maskedID: $0) {
                unmaskedGroupIDs.append(unmaskedID)
            } else {
                LogMessage.create(type: .Error, title: #function, details: "getUnmaskedIDForID failed. getAllFamilyMembers.count = \(allFamilyMembers.count) maskedID = \($0)", collectable: true)
            }
        }
        
        func getUnmaskedIDForID(maskedID: String) -> String? {
            for member in allFamilyMembers {
                let memberLast4 = String(member.familyMemberNRIC!.suffix(4))
                if (memberLast4 == maskedID) {
                    return member.familyMemberNRIC
                }
            }
            return nil
        }
        return unmaskedGroupIDs
    }
    
    static func deleteAndAddFamilyMembers(members: [FamilyMemberRef]) throws {
        try deleteAllFamilyMembers()
        try saveFamilyMembers(members: members)
    }
    
    static func addFamilyMember(familyMember: FamilyMemberRef) throws {
        var members = try getAllFamilyMembers()
        members.append(familyMember)
        try saveFamilyMembers(members: members)
    }
    
    static func removeFamilyMember(familyMember: FamilyMemberRef) throws {
        var members = try getAllFamilyMembers()
        members = members.filter { $0.familyMemberNRIC != familyMember.familyMemberNRIC }
        try saveFamilyMembers(members: members)
    }
    
    static func containsMember(nricString: String) -> Bool {
        do {
            let allMembers = try getAllFamilyMembers()
            return allMembers.contains { $0.familyMemberNRIC == nricString }
        } catch {
            return false
        }
    }
    
    static func getAllFamilyMembers() throws -> [FamilyMemberRef] {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: KeychainConfiguration.serviceName,
                                    kSecAttrAccount as String: KeychainConfiguration.familyMembers,
                                    kSecReturnData as String: true]
        
        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if #available(iOS 11.3, *) {
            LogMessage.create(type: .Info, title: #function, details: SecCopyErrorMessageString(status, nil) as String? ?? "Unknown or No error.", collectable: true)
        }
        switch status {
        case errSecSuccess:
            guard let encodedMembers = item as? Data,
                  let decodedData = try? JSONDecoder().decode([FamilyMemberRef].self, from: encodedMembers) else {
                let keychainError = KeychainError(status: errSecInternalError)
                LogMessage.create(type: .Error, title: #function, details: keychainError.localizedDescription)
                throw keychainError
            }
            return decodedData
        case errSecItemNotFound:
            return []
        default:
            let keychainError = KeychainError(status: status)
            LogMessage.create(type: .Error, title: #function, details: keychainError.localizedDescription)
            throw keychainError
        }
    }
    
    private static func saveFamilyMembers(members: [FamilyMemberRef]) throws {
        let membersEncoded = try JSONEncoder().encode(members)
        
        // Instantiate a new default keychain query
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: KeychainConfiguration.serviceName,
                                    kSecAttrAccount as String: KeychainConfiguration.familyMembers,
                                    kSecValueData as String: membersEncoded]
        
        // Add the new keychain item
        let status = SecItemAdd(query as CFDictionary, nil)
        if #available(iOS 11.3, *) {
            LogMessage.create(type: .Info, title: #function, details: SecCopyErrorMessageString(status, nil) as String? ?? "Unknown or No error.", collectable: true)
        }
        switch status {
        case errSecDuplicateItem:
            //Update existing item
            var attributesToUpdate: [String: Any] = [:]
            attributesToUpdate[String(kSecValueData)] = membersEncoded
            let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            if #available(iOS 11.3, *) {
                LogMessage.create(type: .Info, title: #function, details: SecCopyErrorMessageString(status, nil) as String? ?? "Unknown or No error.", collectable: true)
            }
            if status != errSecSuccess {
                let keychainError = KeychainError(status: status)
                LogMessage.create(type: .Error, title: #function, details: keychainError.localizedDescription)
                throw keychainError
            }
        case errSecSuccess:
            return
        default:
            let keychainError = KeychainError(status: status)
            LogMessage.create(type: .Error, title: #function, details: keychainError.localizedDescription)
            throw keychainError
        }
    }
    
    static func deleteAllFamilyMembers() throws {
        // Build the query for use in the add operation.
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: KeychainConfiguration.serviceName,
                                    kSecAttrAccount as String: KeychainConfiguration.familyMembers]
        var status = SecItemCopyMatching(query as CFDictionary, nil)
        
        switch status {
        case errSecSuccess:
            status = SecItemDelete(query as CFDictionary)
            if status != errSecSuccess {
                throw KeychainError(status: status)
            }
        case errSecItemNotFound:
            return
        default:
            throw KeychainError(status: status)
        }
    }
}
