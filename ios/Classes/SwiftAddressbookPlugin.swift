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
        var contacts: NSArray = []
        
        if #available(iOS 9.0, *) {
            
            guard (CNContactStore.authorizationStatus(for: .contacts) == .notDetermined || CNContactStore.authorizationStatus(for: .contacts) == .authorized) else {
                result(nil)
                return
            }
            
            var keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactOrganizationNameKey, CNContactEmailAddressesKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
            let returnProfileImage = profileImage == nil ? true : profileImage!
            
            if (returnProfileImage) {
                keysToFetch.append(contentsOf: [CNContactImageDataAvailableKey, CNContactImageDataKey] as [CNKeyDescriptor])
            }
            
            let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
            DispatchQueue.global().sync {
                let store = CNContactStore()
                
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
                    
                    var emailAddresses = [String?: String]()
                    for email in contact.emailAddresses {
                        if let label = email.label {
                            let key = CNLabeledValue<NSString>.localizedString(forLabel: label)
                            emailAddresses[key] = String(email.value)
                        } else {
                            emailAddresses[nil] = String(email.value)
                        }
                    }
                    
                    var prePhoneNumbers = [String?: String]()
                    for number in contact.phoneNumbers {
                        if let label = number.label {
                            let key = CNLabeledValue<NSString>.localizedString(forLabel: label)
                            prePhoneNumbers[key] = number.value.stringValue
                        } else {
                            prePhoneNumbers[nil] = number.value.stringValue
                        }
                    }
                        
                    
                    var imageDataBase64: String?
                    if (returnProfileImage) {
                        if let refetchedContact = try? store.unifiedContact(withIdentifier: contact.identifier, keysToFetch: keysToFetch) {
                            if (refetchedContact.imageDataAvailable) {
                                imageDataBase64 = refetchedContact.imageData!.base64EncodedString()
                            }
                        }
                    }
                    
                    let givenName: String? = contact.givenName.isEmpty ? nil : contact.givenName
                    let familyName: String? = contact.familyName.isEmpty ? nil : contact.familyName
                    let organization: String? = contact.organizationName.isEmpty ? nil : contact.organizationName
                    let phoneNumbers: [String?: String]? = prePhoneNumbers.isEmpty ? nil : prePhoneNumbers
                    
                    let contactMap: NSDictionary = ["givenName": givenName, "familyName": familyName, "organization": organization, "emailAddresses": emailAddresses, "phoneNumbers": phoneNumbers, "profileImage": imageDataBase64]
                    
                    contacts = contacts.adding(contactMap) as NSArray
                })
            }
        }
        result(contacts)
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
