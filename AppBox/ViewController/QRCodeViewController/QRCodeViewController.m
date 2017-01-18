//
//  QRCodeViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 18/01/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "QRCodeViewController.h"

@implementation QRCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    NSError *error = nil;
    ZXMultiFormatWriter *writer = [ZXMultiFormatWriter writer];
    ZXBitMatrix *result = [writer encode:self.project.appShortShareableURL.absoluteString format:kBarcodeFormatQRCode width:250 height:250 error:&error];
    if (result){
        CGImageRef qrCodeImage = [[ZXImage imageWithMatrix:result] cgimage];
        [imageViewQRCode setImage:[[NSImage alloc] initWithCGImage:qrCodeImage size:NSMakeSize(250, 250)]];
    }else{
        [Common showAlertWithTitle:@"Error" andMessage:error.localizedDescription];
    }
}

- (IBAction)buttonCloseTapped:(NSButton *)sender {
    [self dismissController:self];
}
@end
