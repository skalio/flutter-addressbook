import Flutter
import UIKit
import Contacts

public class SwiftAddressbookPlugin: NSObject, FlutterPlugin {
    
    // Constants - Method Names
    fileprivate let GETCONTACTS_METHOD = "getContacts"
    
    // Functions
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "addressbook", binaryMessenger: registrar.messenger())
        let instance = SwiftAddressbookPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if (call.method == GETCONTACTS_METHOD) {
            if let arguments = call.arguments as? [String: Any] {
                getContacts(query: arguments["query"] as? String, onlyWithEmail: arguments["onlyWithEmail"] as? Bool, profileImage: arguments["profileImage"] as? Bool, result: result)
            } else {
                getContacts(query: nil, onlyWithEmail: nil, profileImage: nil, result: result)
            }
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    fileprivate func getContacts(query: String?, onlyWithEmail: Bool?, profileImage: Bool?, result: @escaping FlutterResult) {
        if #available(iOS 9.0, *) {
            var contacts: NSArray = []
            
            let store = CNContactStore()
            store.requestAccess(for: .contacts) { isGranted, err in
                if !isGranted || err != nil {
                    result(nil)
                    return
                }
                
                guard (CNContactStore.authorizationStatus(for: .contacts) == .notDetermined || CNContactStore.authorizationStatus(for: .contacts) == .authorized) else {
                    result(nil)
                    return
                }
                
                var keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactOrganizationNameKey, CNContactEmailAddressesKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
                let returnProfileImage = profileImage == nil ? true : profileImage!
                
                if (returnProfileImage) {
                    keysToFetch.append(contentsOf: [CNContactThumbnailImageDataKey] as [CNKeyDescriptor])
                }
                
                let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
                DispatchQueue.global().sync {
                    
                    // fetch all contacts
                    try? store.enumerateContacts(with: fetchRequest, usingBlock: { (contact, stop) in
                        // fetch just contacts which contains query
                        if let query = query {
                            let matched = self.filter(query: query, contact: contact)
                            if (!matched) {
                                return
                            }
                        }
                        
                        if let onlyWithEmail = onlyWithEmail {
                            if (onlyWithEmail) {
                                if (contact.emailAddresses.isEmpty) {
                                    return
                                }
                            }
                        }
                        
                        var preEmailAddresses = [String?: String]()
                        for email in contact.emailAddresses {
                            var type = "";
                            if let label = email.label {
                                type = CNLabeledValue<NSString>.localizedString(forLabel: label)
                            }
                            var key = type
                            var counter = 0
                            while (preEmailAddresses[key] != nil) {
                                key = type + "_" + String(counter)
                                counter += 1
                            }
                            preEmailAddresses[key] = String(email.value)
                        }
                        
                        var prePhoneNumbers = [String?: String]()
                        for number in contact.phoneNumbers {
                            var type = "";
                            if let label = number.label {
                                type = CNLabeledValue<NSString>.localizedString(forLabel: label)
                            }
                            var key = type
                            var counter = 0
                            while (prePhoneNumbers[key] != nil) {
                                key = type + "_" + String(counter)
                                counter += 1
                            }
                            prePhoneNumbers[key] = number.value.stringValue
                        }
                        
                        
                        var imageDataBase64: String?
                        if (returnProfileImage) {
                            if let refetchedContact = try? store.unifiedContact(withIdentifier: contact.identifier, keysToFetch: keysToFetch) {
                                imageDataBase64 = refetchedContact.thumbnailImageData?.base64EncodedString()
                            }
                        }
                        
                        let givenName: String? = contact.givenName.isEmpty ? nil : contact.givenName
                        let familyName: String? = contact.familyName.isEmpty ? nil : contact.familyName
                        let organization: String? = contact.organizationName.isEmpty ? nil : contact.organizationName
                        let emailAddresses: [String?: String]? = preEmailAddresses.isEmpty ? nil : preEmailAddresses
                        let phoneNumbers: [String?: String]? = prePhoneNumbers.isEmpty ? nil : prePhoneNumbers
                        
                        let contactMap: NSDictionary = ["givenName": givenName as Any, "familyName": familyName as Any, "organization": organization as Any, "emailAddresses": emailAddresses as Any, "phoneNumbers": phoneNumbers as Any, "profileImage": imageDataBase64 as Any]
                        
                        contacts = contacts.adding(contactMap) as NSArray
                    })
                }
                
                result(contacts)
            }
        } else {
            result(nil)
        }
    }
    
    // filter in fullname, organizationname and email with query
    @available(iOS 9.0, *)
    fileprivate func filter(query: String, contact: CNContact) -> Bool {
        let query = query.lowercased()
        let fullname = (contact.givenName + " " + contact.familyName).lowercased()
        let organizationName = contact.organizationName.lowercased()
        
        if(!contact.emailAddresses.isEmpty) {
            for emailAddress in contact.emailAddresses {
                let email = emailAddress.value.lowercased
                if (fullname.contains(query) || organizationName.contains(query) || email.contains(query)) {
                    return true
                }
            }
            return false
        } else {
            return fullname.contains(query) || organizationName.contains(query)
        }
    }
}
