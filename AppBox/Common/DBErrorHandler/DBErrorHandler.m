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

+(void)handleUploadSessionLookupError:(DBFILESUploadSessionLookupError *)error{
    switch (error.tag) {
        case DBFILESUploadSessionLookupErrorClosed:{
            [Common showAlertWithTitle:@"Error" andMessage:@"You are attempting to append data to an upload session that has already been closed. Please try again."];
        }break;
            
        case DBFILESUploadSessionLookupErrorNotFound:{
            [Common showAlertWithTitle:@"Error" andMessage:@"he upload session ID was not found or has expired. Upload sessions are valid for 48 hours. Please try again."];
        }break;
            
        case DBFILESUploadSessionLookupErrorNotClosed:{
            [Common showAlertWithTitle:@"Error" andMessage:@"The session must be closed before calling upload_session/finish_batch. Please try again."];
        }break;
            
        case DBFILESUploadSessionLookupErrorIncorrectOffset:{
            [Common showAlertWithTitle:@"Error" andMessage:@"The specified offset was incorrect. Please try again."];
        }break;
            
        case DBFILESUploadSessionLookupErrorOther:{
            [Common showAlertWithTitle:@"Error" andMessage:@"Something goes wrong. Please try again."];
        }break;
            
        default:
            break;
    }
}

+(void)handleUploadSessionFinishError:(DBFILESUploadSessionFinishError *)error{
    switch (error.tag) {
        case DBFILESUploadSessionFinishErrorPath:{
            [Common showAlertWithTitle:@"Error" andMessage:@"Unable to save the uploaded contents to a file. Please try again."];
        }break;
            
        case DBFILESUploadSessionFinishErrorLookupFailed:{
            [Common showAlertWithTitle:@"Error" andMessage:@"The session arguments are incorrect. Please try again."];
        }break;
            
        case DBFILESUploadSessionFinishErrorTooManyWriteOperations:{
            [Common showAlertWithTitle:@"Error" andMessage:@"There are too many write operations happening in the user's Dropbox. Please try again."];
        }break;
            
        case DBFILESUploadSessionFinishErrorTooManySharedFolderTargets:{
            [Common showAlertWithTitle:@"Error" andMessage:@"The batch request commits files into too many different shared folders. Please try again."];
        }break;
            
        case DBFILESUploadSessionFinishErrorOther:{
            [Common showAlertWithTitle:@"Error" andMessage:@"Something goes wrong. Please try again."];
        }break;
            
        default:
            break;
    }
}

@end
