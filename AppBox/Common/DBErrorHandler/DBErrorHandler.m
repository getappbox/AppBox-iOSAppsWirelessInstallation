//
//  DBErrorHandler.m
//  AppBox
//
//  Created by Vineet Choudhary on 17/10/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "DBErrorHandler.h"

@implementation DBErrorHandler

+(void)handleNetworkErrorWith:(DBRequestError *)networkError{
    switch (networkError.tag) {
        case DBRequestErrorAuth:{
            [Common showAlertWithTitle:@"Error" andMessage:@"Errors due to invalid authentication credentials. Please login Again."];
            [[NSNotificationCenter defaultCenter] postNotificationName:abDropBoxLoggedOutNotification object:self];
        }break;
            
        case DBRequestErrorHttp:{
            [Common showAlertWithTitle:@"Error" andMessage:@"Errors produced at the HTTP layer. Please try again."];
        }break;
            
        case DBRequestErrorAccess:{
            [Common showAlertWithTitle:@"Error" andMessage:@"Errors due to invalid permission to access."];
        }break;
            
        case DBRequestErrorClient:{
            if (![[AppDelegate appDelegate] isInternetConnected]){
                [Common showNoInternetConnectionAvailabeAlert];
            } else {
                [Common showAlertWithTitle:@"Error" andMessage:@"Errors due to a problem on the client-side of the SDK. Please try again."];
            }
        }break;
            
        case DBRequestErrorBadInput:{
            [Common showAlertWithTitle:@"Error" andMessage:@"Errors due to bad input parameters to an API Operation. Please report the issue."];
        }break;
            
        case DBRequestErrorPathRoot:{
            [Common showAlertWithTitle:@"Error" andMessage:@"Errors due to invalid authentication credentials."];
        }break;
            
        case DBRequestErrorRateLimit:{
            [Common showAlertWithTitle:@"Error" andMessage:@"Error caused by rate limiting."];
        }break;
            
        case DBRequestErrorInternalServer:{
            [Common showAlertWithTitle:@"Error" andMessage:@"Errors due to a problem on Dropbox. Please try again."];
        }break;
            
        default:{
            [Common showAlertWithTitle:@"Error" andMessage:@"Something goes wrong. Please try again."];
        }break;
    }
}

+(void)handleDeleteErrorWith:(DBFILESDeleteError *)deleteError{
    switch (deleteError.tag) {
        case DBFILESDeleteErrorPathLookup:{
            [Common showAlertWithTitle:@"Error" andMessage:@"Can't able to find file/folder."];
        }break;
            
        case DBFILESDeleteErrorPathWrite: {
            [Common showAlertWithTitle:@"Error" andMessage:@"Can't able to write at give path."];
        }break;
            
        case DBFILESDeleteErrorTooManyFiles: {
            [Common showAlertWithTitle:@"Error" andMessage:@"There are too many files in one request. Please try again."];
        }break;
            
        case DBFILESDeleteErrorTooManyWriteOperations: {
            [Common showAlertWithTitle:@"Error" andMessage:@"There are too many write operations in user's Dropbox. Please try again."];
        }break;
            
        case DBFILESDeleteErrorOther: {
            [Common showAlertWithTitle:@"Error" andMessage:@"Something goes wrong. Please try again."];
        }break;
            
        default:{
            [Common showAlertWithTitle:@"Error" andMessage:@"Something goes wrong. Please try again."];
        }break;
    }
}

+(void)handleUploadErrorWith:(DBFILESUploadError *)uploadError{
    switch (uploadError.tag) {
        case DBFILESUploadErrorPath:{
            [Common showAlertWithTitle:@"Error" andMessage:@"Unable to save the uploaded contents to a file."];
        }break;
            
        case DBFILESUploadErrorOther:{
            [Common showAlertWithTitle:@"Error" andMessage:@"Something goes wrong. Please try again."];
        }break;
            
        default:{
            [Common showAlertWithTitle:@"Error" andMessage:@"Something goes wrong. Please try again."];
        }break;
    }
}

@end
