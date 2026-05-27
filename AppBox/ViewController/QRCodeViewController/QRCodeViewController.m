//
//  QRCodeViewController.m
//  AppBox
//
//  Created by Vineet Choudhary on 18/01/17.
//  Copyright © 2017 Developer Insider. All rights reserved.
//

#import "QRCodeViewController.h"
#import <CoreImage/CoreImage.h>

@implementation QRCodeViewController{
}

- (void)viewDidLoad {
    [super viewDidLoad];

    //create qr code and show in imageview
    NSString *url;
    if (self.ipaUploadInfo) {
        url = self.ipaUploadInfo.appShortShareableURL.stringValue;
    } else if (self.uploadRecord){
        url = self.uploadRecord.shortURL;
    } else {
        url = @"No URL found.";
    }
    NSImage *image = [self qrCodeImageForString:url size:NSMakeSize(250, 250)];
    if (image){
        [imageViewQRCode setImage:image];
    }else{
        [Common showAlertWithTitle:@"Error" andMessage:@"Unable to generate QR code."];
    }
}

- (NSImage *)qrCodeImageForString:(NSString *)string size:(NSSize)size {
    NSData *data = [string dataUsingEncoding:NSISOLatin1StringEncoding];
    if (data == nil) {
        return nil;
    }

    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [qrFilter setValue:data forKey:@"inputMessage"];
    [qrFilter setValue:@"M" forKey:@"inputCorrectionLevel"];
    CIImage *qrImage = qrFilter.outputImage;
    if (qrImage == nil) {
        return nil;
    }

    // Map the black data modules to the label color and the white background to clear.
    CIFilter *colorFilter = [CIFilter filterWithName:@"CIFalseColor"];
    [colorFilter setValue:qrImage forKey:kCIInputImageKey];
    [colorFilter setValue:[CIColor colorWithCGColor:NSColor.labelColor.CGColor] forKey:@"inputColor0"];
    [colorFilter setValue:[CIColor colorWithCGColor:NSColor.clearColor.CGColor] forKey:@"inputColor1"];
    CIImage *coloredImage = colorFilter.outputImage ?: qrImage;

    // Scale up using nearest-neighbour sampling so the modules stay crisp.
    CGRect extent = coloredImage.extent;
    CGFloat scale = MIN(size.width / extent.size.width, size.height / extent.size.height);
    CIImage *scaledImage = [[coloredImage imageBySamplingNearest]
                            imageByApplyingTransform:CGAffineTransformMakeScale(scale, scale)];

    NSCIImageRep *rep = [NSCIImageRep imageRepWithCIImage:scaledImage];
    NSImage *image = [[NSImage alloc] initWithSize:size];
    [image addRepresentation:rep];
    return image;
}

- (IBAction)buttonCloseTapped:(NSButton *)sender {
    [self dismissController:self];
}
@end
