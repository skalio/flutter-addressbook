#import "AddressbookPlugin.h"
#import <addressbook/addressbook-Swift.h>

@implementation AddressbookPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAddressbookPlugin registerWithRegistrar:registrar];
}
@end
