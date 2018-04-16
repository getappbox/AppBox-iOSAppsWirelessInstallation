//
//  QRCodeViewController.h
//  AppBox
//
//  Created by Vineet Choudhary on 18/01/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ZXingObjC/ZXingObjC.h>

@interface QRCodeViewController : NSViewController{
    IBOutlet NSImageView *imageViewQRCode;
}

@property(nonatomic, strong) XCProject *project;
@property(nonatomic, strong) UploadRecord *uploadRecord;

- (IBAction)buttonCloseTapped:(NSButton *)sender;

@end
