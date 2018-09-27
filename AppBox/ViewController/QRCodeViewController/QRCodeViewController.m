//
//  QRCodeViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 18/01/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "QRCodeViewController.h"

@implementation QRCodeViewController{
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //log screen
    [EventTracker logScreen:@"QR Code View"];
    
    //create qr code and show in imageview
    NSString *url;
    if (self.project) {
        url = self.project.appShortShareableURL.stringValue;
    } else if (self.uploadRecord){
        url = self.uploadRecord.shortURL;
    } else {
        url = @"No URL found.";
    }
    NSError *error = nil;
    ZXMultiFormatWriter *writer = [ZXMultiFormatWriter writer];
    ZXBitMatrix *result = [writer encode:url format:kBarcodeFormatQRCode width:250 height:250 error:&error];
    if (result){
        ZXImage *zxImage = [ZXImage imageWithMatrix: result
                                            onColor: NSColor.labelColor.CGColor
                                           offColor: NSColor.windowBackgroundColor.CGColor];
        NSImage *image = [[NSImage alloc] initWithCGImage:[zxImage cgimage] size:NSMakeSize(250, 250)];
        [imageViewQRCode setImage:image];
    }else{
        [Common showAlertWithTitle:@"Error" andMessage:error.localizedDescription];
    }
}

- (IBAction)buttonCloseTapped:(NSButton *)sender {
    [self dismissController:self];
}
@end
