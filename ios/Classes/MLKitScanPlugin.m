#import "MLKitScanPlugin.h"
#if __has_include(<mlkit_scan_plugin/mlkit_scan_plugin-Swift.h>)
#import <mlkit_scan_plugin/mlkit_scan_plugin-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "mlkit_scan_plugin-Swift.h"
#endif

@implementation MLKitScanPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftMLKitScanPlugin registerWithRegistrar:registrar];
}
@end
