//
//  DBErrorHandler.m
//  AppBox
//
//  Created by Vineet Choudhary on 17/10/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "DBErrorHandler.h"

@implementation DBErrorHandler

+(void)handleNetworkErrorWith:(DBRequestError *)networkError abErrorMessage:(NSString *)abErrorMessage {
    NSMutableString *errorMessage = [[NSMutableString alloc] init];
    if (networkError) {
        [errorMessage appendFormat:@"\n\nDropbox Request Error - "];
        [errorMessage appendFormat:@"\nError Content - %@", networkError.errorContent];
        [errorMessage appendFormat:@"\nStatus Code - %@", networkError.statusCode];
        [errorMessage appendFormat:@"\nRequest Id - %@", networkError.requestId];
        if (abErrorMessage) {
            [errorMessage appendFormat:@"\n\nAppBox Error - %@", abErrorMessage];
        }
        
        switch (networkError.tag) {
            case DBRequestErrorAuth:{
                [errorMessage insertString:@"Errors due to invalid authentication credentials. Please login Again." atIndex:0];
                [Common showAlertWithTitle:@"Error" andMessage:errorMessage];
                [[NSNotificationCenter defaultCenter] postNotificationName:abDropBoxLoggedOutNotification object:self];
            }break;
                
            case DBRequestErrorHttp:{
                [errorMessage insertString:@"Errors produced at the HTTP layer. Please check following details and try again." atIndex:0];
                [Common showAlertWithTitle:@"Error" andMessage:errorMessage];
            }break;
                
            case DBRequestErrorAccess:{
                [errorMessage insertString:@"Errors due to invalid permission to access." atIndex:0];
                [Common showAlertWithTitle:@"Error" andMessage:errorMessage];
            }break;
                
            case DBRequestErrorClient:{
                if (![[AppDelegate appDelegate] isInternetConnected]){
                    [Common showNoInternetConnectionAvailabeAlert];
                } else {
                    [errorMessage insertString:@"Errors due to a problem on the client-side of the SDK. Please check following details and try again." atIndex:0];
                    [Common showAlertWithTitle:@"Error" andMessage:errorMessage];
                }
            }break;
                
            case DBRequestErrorBadInput:{
                [errorMessage insertString:@"Errors due to bad input parameters to an API Operation. Please report the issue." atIndex:0];
                [Common showAlertWithTitle:@"Error" andMessage:errorMessage];
            }break;
                
            case DBRequestErrorPathRoot:{
                [errorMessage insertString:@"Errors due to invalid authentication credentials." atIndex:0];
                [Common showAlertWithTitle:@"Error" andMessage:errorMessage];
            }break;
                
            case DBRequestErrorRateLimit:{
                [errorMessage insertString:@"Error caused by rate limiting." atIndex:0];
                [Common showAlertWithTitle:@"Error" andMessage:errorMessage];
            }break;
                
            case DBRequestErrorInternalServer:{
                [errorMessage insertString:@"Errors due to a problem on Dropbox Server. Please try again." atIndex:0];
                [Common showAlertWithTitle:@"Error" andMessage:errorMessage];
            }break;
                
            default:{
                [errorMessage insertString:@"Something goes wrong. Please try again." atIndex:0];
                [Common showAlertWithTitle:@"Error" andMessage:errorMessage];
            }break;
        }
    } else {
        [errorMessage insertString:@"Something goes wrong. Please try again." atIndex:0];
        [Common showAlertWithTitle:@"Error" andMessage:errorMessage];
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

+(void)handleUploadSessionAppendError:(DBFILESUploadSessionAppendError *)error {
	switch (error.tag) {
		case DBFILESUploadSessionAppendErrorNotFound: {
			[Common showAlertWithTitle:@"Error" andMessage:@"Upload session not found. Please try again."];
		}break;
			
		case DBFILESUploadSessionAppendErrorIncorrectOffset: {
			[Common showAlertWithTitle:@"Error" andMessage:@"Offset is incorrect for the upload session. Please try again."];
		}break;
			
		case DBFILESUploadSessionAppendErrorClosed: {
			[Common showAlertWithTitle:@"Error" andMessage:@"Upload session closed. Please try again."];
		}break;
			
		case DBFILESUploadSessionAppendErrorNotClosed: {
			[Common showAlertWithTitle:@"Error" andMessage:@"Upload session not closed. Please try again."];
		}break;
			
		case DBFILESUploadSessionAppendErrorTooLarge: {
			[Common showAlertWithTitle:@"Error" andMessage:@"The file size is too large. Please try again."];
		}break;
			
		case DBFILESUploadSessionAppendErrorConcurrentSessionInvalidOffset: {
			[Common showAlertWithTitle:@"Error" andMessage:@"Invalid offset for the concurrent session. Please try again."];
		}break;
			
		case DBFILESUploadSessionAppendErrorConcurrentSessionInvalidDataSize: {
			[Common showAlertWithTitle:@"Error" andMessage:@"Invalid data size for the concurrent session. Please try again."];
		}break;
			
		case DBFILESUploadSessionAppendErrorPayloadTooLarge: {
			[Common showAlertWithTitle:@"Error" andMessage:@"The payload size is too large. Please try again."];
		}break;
			
		case DBFILESUploadSessionAppendErrorOther: {
			[Common showAlertWithTitle:@"Error" andMessage:@"Something goes wrong. Please try again."];
		}break;
			
		case DBFILESUploadSessionAppendErrorContentHashMismatch: {
			[Common showAlertWithTitle:@"Error" andMessage:@"The content hash does not match. Please try again."];
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
