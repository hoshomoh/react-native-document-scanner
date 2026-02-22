#import "DocumentScanner.h"
#import <Foundation/Foundation.h>

@protocol DocumentScannerSwiftProtocol <NSObject>
- (void)scanDocuments:(NSDictionary *)options
              resolve:(RCTPromiseResolveBlock)resolve
               reject:(RCTPromiseRejectBlock)reject;
- (void)processDocuments:(NSDictionary *)options
                 resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject;
@end

@implementation DocumentScanner {
  id _impl;
}

- (instancetype)init {
  if (self = [super init]) {
    Class swiftClass = NSClassFromString(@"DocumentScannerManager");
    if (swiftClass) {
      _impl = [[swiftClass alloc] init];
    }
  }
  return self;
}

- (void)scanDocuments:(JS::NativeDocumentScanner::ScanOptions &)options
              resolve:(RCTPromiseResolveBlock)resolve
               reject:(RCTPromiseRejectBlock)reject {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  if (options.maxPageCount().has_value()) {
    dict[@"maxPageCount"] = @(options.maxPageCount().value());
  }
  if (options.quality().has_value()) {
    dict[@"quality"] = @(options.quality().value());
  }
  if (options.format()) {
    dict[@"format"] = options.format();
  }
  if (options.filter()) {
    dict[@"filter"] = options.filter();
  }
  if (options.includeBase64().has_value()) {
    dict[@"includeBase64"] = @(options.includeBase64().value());
  }
  if (options.includeText().has_value()) {
    dict[@"includeText"] = @(options.includeText().value());
  }
  if (options.textVersion().has_value()) {
    dict[@"textVersion"] = @(options.textVersion().value());
  }

  if (_impl) {
    [(id<DocumentScannerSwiftProtocol>)_impl scanDocuments:dict
                                                   resolve:resolve
                                                    reject:reject];
  } else {
    reject(@"impl_error", @"Swift implementation not found", nil);
  }
}

- (void)processDocuments:(JS::NativeDocumentScanner::ProcessOptions &)options
                 resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  /* Convert images array */
  NSMutableArray *images = [NSMutableArray new];
  for (NSString *img : options.images()) {
    [images addObject:img];
  }
  dict[@"images"] = images;

  if (options.quality().has_value()) {
    dict[@"quality"] = @(options.quality().value());
  }
  if (options.format()) {
    dict[@"format"] = options.format();
  }
  if (options.filter()) {
    dict[@"filter"] = options.filter();
  }
  if (options.includeBase64().has_value()) {
    dict[@"includeBase64"] = @(options.includeBase64().value());
  }
  if (options.includeText().has_value()) {
    dict[@"includeText"] = @(options.includeText().value());
  }
  if (options.textVersion().has_value()) {
    dict[@"textVersion"] = @(options.textVersion().value());
  }

  if (_impl) {
    [(id<DocumentScannerSwiftProtocol>)_impl processDocuments:dict
                                                      resolve:resolve
                                                       reject:reject];
  } else {
    reject(@"impl_error", @"Swift implementation not found", nil);
  }
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeDocumentScannerSpecJSI>(
      params);
}

+ (NSString *)moduleName {
  return @"DocumentScanner";
}

@end
