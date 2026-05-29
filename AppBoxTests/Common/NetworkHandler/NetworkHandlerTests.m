//
//  NetworkHandlerTests.m
//  AppBoxTests
//
//  Created by AppBox on 29/05/26.
//  Copyright © 2026 Developer Insider. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NetworkHandler.h"

@interface NetworkHandler (Testing)
+ (NSMutableURLRequest *)jsonRequestWithURL:(NSString *)urlString parameters:(id)parameters requestType:(RequestType)requestType;
+ (NSString *)queryStringFromDictionary:(NSDictionary *)dictionary;
+ (NSError *)errorWithCode:(NSInteger)code message:(NSString *)message;
@end

@interface NetworkHandlerTests : XCTestCase
@end

@implementation NetworkHandlerTests

#pragma mark - queryStringFromDictionary Tests

- (void)testQueryString_WithSingleParameter {
    NSDictionary *params = @{@"key": @"value"};
    NSString *result = [NetworkHandler queryStringFromDictionary:params];
    XCTAssertEqualObjects(result, @"key=value");
}

- (void)testQueryString_WithMultipleParameters {
    NSDictionary *params = @{@"a": @"1", @"b": @"2"};
    NSString *result = [NetworkHandler queryStringFromDictionary:params];
    XCTAssertTrue([result containsString:@"a=1"]);
    XCTAssertTrue([result containsString:@"b=2"]);
    XCTAssertTrue([result containsString:@"&"]);
}

- (void)testQueryString_EncodesSpecialCharacters {
    NSDictionary *params = @{@"query": @"hello world"};
    NSString *result = [NetworkHandler queryStringFromDictionary:params];
    XCTAssertFalse([result containsString:@" "]);
    XCTAssertTrue([result containsString:@"query="]);
}

- (void)testQueryString_EncodesAmpersandInValue {
    NSDictionary *params = @{@"text": @"a&b"};
    NSString *result = [NetworkHandler queryStringFromDictionary:params];
    XCTAssertFalse([result containsString:@"a&b"]);
    XCTAssertTrue([result containsString:@"text="]);
}

- (void)testQueryString_WithEmptyDictionary {
    NSDictionary *params = @{};
    NSString *result = [NetworkHandler queryStringFromDictionary:params];
    XCTAssertEqualObjects(result, @"");
}

- (void)testQueryString_WithNumericValue {
    NSDictionary *params = @{@"count": @42};
    NSString *result = [NetworkHandler queryStringFromDictionary:params];
    XCTAssertEqualObjects(result, @"count=42");
}

#pragma mark - jsonRequestWithURL Tests

- (void)testJsonRequest_POST_SetsHTTPMethodToPOST {
    NSMutableURLRequest *request = [NetworkHandler jsonRequestWithURL:@"https://example.com/api" parameters:nil requestType:RequestPOST];
    XCTAssertEqualObjects(request.HTTPMethod, @"POST");
}

- (void)testJsonRequest_GET_SetsHTTPMethodToGET {
    NSMutableURLRequest *request = [NetworkHandler jsonRequestWithURL:@"https://example.com/api" parameters:nil requestType:RequestGET];
    XCTAssertEqualObjects(request.HTTPMethod, @"GET");
}

- (void)testJsonRequest_SetsAcceptHeader {
    NSMutableURLRequest *request = [NetworkHandler jsonRequestWithURL:@"https://example.com/api" parameters:nil requestType:RequestGET];
    XCTAssertEqualObjects([request valueForHTTPHeaderField:@"Accept"], @"application/json");
}

- (void)testJsonRequest_POST_WithParameters_SetsContentType {
    NSDictionary *params = @{@"key": @"value"};
    NSMutableURLRequest *request = [NetworkHandler jsonRequestWithURL:@"https://example.com/api" parameters:params requestType:RequestPOST];
    XCTAssertEqualObjects([request valueForHTTPHeaderField:@"Content-Type"], @"application/json");
}

- (void)testJsonRequest_POST_WithParameters_SetsHTTPBody {
    NSDictionary *params = @{@"name": @"AppBox"};
    NSMutableURLRequest *request = [NetworkHandler jsonRequestWithURL:@"https://example.com/api" parameters:params requestType:RequestPOST];
    XCTAssertNotNil(request.HTTPBody);
    NSDictionary *decoded = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:nil];
    XCTAssertEqualObjects(decoded[@"name"], @"AppBox");
}

- (void)testJsonRequest_GET_WithParameters_AppendsQueryString {
    NSDictionary *params = @{@"page": @"1"};
    NSMutableURLRequest *request = [NetworkHandler jsonRequestWithURL:@"https://example.com/api" parameters:params requestType:RequestGET];
    NSString *urlString = request.URL.absoluteString;
    XCTAssertTrue([urlString containsString:@"?page=1"]);
}

- (void)testJsonRequest_GET_WithExistingQuery_AppendsWithAmpersand {
    NSDictionary *params = @{@"b": @"2"};
    NSMutableURLRequest *request = [NetworkHandler jsonRequestWithURL:@"https://example.com/api?a=1" parameters:params requestType:RequestGET];
    NSString *urlString = request.URL.absoluteString;
    XCTAssertTrue([urlString containsString:@"&b=2"]);
}

- (void)testJsonRequest_UpgradesHTTPToHTTPS {
    NSMutableURLRequest *request = [NetworkHandler jsonRequestWithURL:@"http://example.com/api" parameters:nil requestType:RequestGET];
    XCTAssertTrue([request.URL.absoluteString hasPrefix:@"https://"]);
}

- (void)testJsonRequest_HTTPSRemainsHTTPS {
    NSMutableURLRequest *request = [NetworkHandler jsonRequestWithURL:@"https://example.com/api" parameters:nil requestType:RequestGET];
    XCTAssertTrue([request.URL.absoluteString hasPrefix:@"https://"]);
}

- (void)testJsonRequest_WithNilURL_ReturnsNil {
    NSMutableURLRequest *request = [NetworkHandler jsonRequestWithURL:nil parameters:nil requestType:RequestGET];
    XCTAssertNil(request);
}

- (void)testJsonRequest_POST_WithNilParameters_HasNoBody {
    NSMutableURLRequest *request = [NetworkHandler jsonRequestWithURL:@"https://example.com" parameters:nil requestType:RequestPOST];
    XCTAssertNotNil(request);
    XCTAssertNil(request.HTTPBody);
}

- (void)testJsonRequest_GET_WithNilParameters_NoQueryString {
    NSMutableURLRequest *request = [NetworkHandler jsonRequestWithURL:@"https://example.com/api" parameters:nil requestType:RequestGET];
    XCTAssertEqualObjects(request.URL.absoluteString, @"https://example.com/api");
}

#pragma mark - errorWithCode:message: Tests

- (void)testErrorWithCode_ReturnsCorrectCode {
    NSError *error = [NetworkHandler errorWithCode:404 message:@"Not Found"];
    XCTAssertEqual(error.code, 404);
}

- (void)testErrorWithCode_ReturnsCorrectMessage {
    NSError *error = [NetworkHandler errorWithCode:500 message:@"Internal Server Error"];
    XCTAssertEqualObjects(error.localizedDescription, @"Internal Server Error");
}

- (void)testErrorWithCode_HasAppBoxDomain {
    NSError *error = [NetworkHandler errorWithCode:0 message:@"test"];
    XCTAssertEqualObjects(error.domain, @"AppBoxNetworkHandler");
}

@end
