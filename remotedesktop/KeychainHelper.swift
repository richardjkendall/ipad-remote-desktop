//
//  KeychainHelper.swift
//  remotedesktop
//
//  Created by Kendall, Richard on 3/2/2024.
//
// Largely inspired by this https://stackoverflow.com/a/68232091
//

import Foundation

let service = "com.richardjameskendall.apple.remotedesktop.keychain-service"

class KeychainHelper {
    static let shared = KeychainHelper()
    
    enum KeychainError: LocalizedError {
        case itemNotFound
        case duplicateItem
        case unexpectedStatus(OSStatus)
    }
    
    func insertToken(_ token: Data, identifier: String, service: String = service) throws {
        let attributes = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: identifier,
            kSecValueData: token
        ] as CFDictionary

        let status = SecItemAdd(attributes, nil)
        guard status == errSecSuccess else {
            if status == errSecDuplicateItem {
                throw KeychainError.duplicateItem
            }
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    func getToken(identifier: String, service: String = service) throws -> String {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: identifier,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: true
        ] as CFDictionary

        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                // Technically could make the return optional and return nil here
                // depending on how you like this to be taken care of
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }
        // Lots of bang operators here, due to the nature of Keychain functionality.
        // You could work with more guards/if let or others.
        return String(data: result as! Data, encoding: .utf8)!
    }
    
    func updateToken(_ token: Data, identifier: String, service: String = service) throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: identifier
        ] as CFDictionary

        let attributes = [
            kSecValueData: token
        ] as CFDictionary

        let status = SecItemUpdate(query, attributes)
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func upsertToken(_ token: Data, identifier: String, service: String = service) throws {
        do {
            _ = try getToken(identifier: identifier, service: service)
            try updateToken(token, identifier: identifier, service: service)
        } catch KeychainError.itemNotFound {
            try insertToken(token, identifier: identifier, service: service)
        }
    }

    func deleteToken(identifier: String, service: String = service) throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: identifier
        ] as CFDictionary

        let status = SecItemDelete(query)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
}
