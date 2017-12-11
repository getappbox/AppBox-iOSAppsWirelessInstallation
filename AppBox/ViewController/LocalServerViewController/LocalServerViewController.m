//
//  LocalServerViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 10/12/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "LocalServerViewController.h"

@interface LocalServerViewController ()

@end

@implementation LocalServerViewController{
    NSTask *serverTask;
    NSMutableString *serverLogs;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self startLocalServer];
}

-(void)startLocalServer{
    NSString *launchPath = [[NSBundle mainBundle] pathForResource:@"PythonServer" ofType:@"sh"];
    if (launchPath == nil){
        return;
    }
    serverTask = [[NSTask alloc] init];
    serverTask.launchPath = launchPath;
    serverTask.arguments = @[[UserData buildLocation].resourceSpecifier];
    serverLogs = [[NSMutableString alloc] init];
    
    //Create error, output pipe with handler
    __block NSPipe *outputPipe = [[NSPipe alloc] init];
    [serverTask setStandardOutput:outputPipe];
    [serverTask setStandardError:outputPipe];
    [outputPipe.fileHandleForReading waitForDataInBackgroundAndNotify];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSFileHandleDataAvailableNotification object:outputPipe.fileHandleForReading queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        NSData *outputData =  outputPipe.fileHandleForReading.availableData;
        NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
        [serverLogs appendFormat:@"\n%@",outputString];
        [[AppDelegate appDelegate] addSessionLog:[NSString stringWithFormat:@"Server Log - %@", outputString]];
        if(![outputString isEqualToString:abEmptyString]){
            [outputPipe.fileHandleForReading waitForDataInBackgroundAndNotify];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [serverLogTextView setString:serverLogs];
            [serverLogTextView scrollToEndOfDocument:self];
            if ([serverLogs containsString:@"port 8888"]){
                [serverStatusIndicator setIntValue:1];
            } else {
                [serverStatusIndicator setIntValue:3];
            }
            
        });
    }];
    [serverTask launch];
}

@end
