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
            if let arguments = call.arguments {
                let query = arguments as! String
                getContacts(query: query, result: result)
            } else {
                getContacts(query: nil, result: result)
            }
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    fileprivate func getContacts(query: String?, result: @escaping FlutterResult) {
        var contacts: NSArray = []
        
        if #available(iOS 9.0, *) {
            var keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactOrganizationNameKey, CNContactEmailAddressesKey] as [CNKeyDescriptor]
            let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
            
            guard (CNContactStore.authorizationStatus(for: .contacts) == .notDetermined || CNContactStore.authorizationStatus(for: .contacts) == .authorized) else {
                result(nil)
                return
            }
            
            DispatchQueue.global().sync {
                let store = CNContactStore()
                
                // fetch all contacts
                try? store.enumerateContacts(with: fetchRequest, usingBlock: { (contact, stop) in
                    let keys = [CNContactPhoneNumbersKey, CNContactImageDataAvailableKey, CNContactImageDataKey] as [CNKeyDescriptor]
                    keysToFetch.append(contentsOf: keys)
                    
                    if (contact.emailAddresses.isEmpty) {
                        return
                    }
                    
                    var emailAddresses = [String?: String]()
                    for email in contact.emailAddresses {
                        
                        // fetch just contacts which contains query
                        if let query = query {
                            if (!("\(contact.givenName.lowercased()) \(contact.familyName.lowercased())".contains(query) || contact.organizationName.lowercased().contains(query) || email.value.lowercased.contains(query))) {
                                return
                            }
                        }
                        
                        if let label = email.label {
                            let key = CNLabeledValue<NSString>.localizedString(forLabel: label)
                            emailAddresses[key] = String(email.value)
                        } else {
                            emailAddresses[nil] = String(email.value)
                        }
                    }
                    
                    var prePhoneNumbers = [String?: String]()
                    var imageDataBase64: String?
                    if let refetchedContact = try? store.unifiedContact(withIdentifier: contact.identifier, keysToFetch: keysToFetch) {
                        // assign phone numbers
                        for number in refetchedContact.phoneNumbers {
                            if let label = number.label {
                                let key = CNLabeledValue<NSString>.localizedString(forLabel: label)
                                prePhoneNumbers[key] = number.value.stringValue
                            } else {
                                prePhoneNumbers[nil] = number.value.stringValue
                            }
                        }
                        
                        // assign profile image
                        if (refetchedContact.imageDataAvailable) {
                            imageDataBase64 = refetchedContact.imageData!.base64EncodedString()
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
}
