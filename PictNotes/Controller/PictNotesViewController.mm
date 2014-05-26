//
//  PictNotesViewController.m
//  PictNotes
//
//  Created by J. Blair Metcalf on 3/16/14.
//  Copyright (c) 2014 James Metcalf. All rights reserved.
//

#import "PictNotesViewController.h"
#import <TesseractOCR/TesseractOCR.h>
#import "ImageProcessing.h"

@interface PictNotesViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate,TesseractDelegate>

@property (nonatomic, strong) UIImage *image;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *sourceImageView;
@property (weak, nonatomic) IBOutlet UIImageView *optimizedImageView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraButton;

@end

@implementation PictNotesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.activityIndicator stopAnimating];
}

- (IBAction)takePhoto:(id)sender
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
        imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    } else {
        imagePickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    }
    [self presentViewController:imagePickerController
                       animated:YES
                     completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    self.optimizedImageView.image = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
    self.image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [self convertImage];
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    [self.sourceImageView setImage:image];
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (UIImage *)optimizeImage:(UIImage *)image
{
    UIImage *resizedImage = [[self class] imageWithImage:image scaledToSize:CGSizeMake(image.size.width / 3, image.size.height / 3)];
    ImageWrapper *greyScale=Image::createImage(resizedImage, resizedImage.size.width, resizedImage.size.height);
    ImageWrapper *edges = greyScale.image->autoLocalThreshold();
    return edges.image->toUIImage();
}

- (UIImage *)drawColors:(NSArray *)colors
{
    CGSize size = CGSizeMake(100, 100);
    UIGraphicsBeginImageContextWithOptions(size, YES, 0);
    [[UIColor grayColor] setFill];
    UIRectFill(CGRectMake(0, 0, size.width, size.height));
    
    int index = 0;
    
    for (UIColor *color in colors) {
        
        [(UIColor *)color setFill];
        UIRectFill(CGRectMake(index*20, 0, (index+1)*20, 100));
        
        index++;
    }
    
    UIImage *colorsImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return colorsImage;
}

- (void)convertImage
{
    if (self.image) {
        self.textView.text = nil;
        
        [self.activityIndicator startAnimating];
        [self setProgress:0];
        self.cameraButton.enabled = NO;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            Tesseract* tesseract = [[Tesseract alloc] initWithDataPath:@"/tessdata" language:@"eng"];
            tesseract.delegate = self;
            
            [tesseract setVariableValue:@")_-+?!,(/'.^`():<>@0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" forKey:@"tessedit_char_whitelist"];
            
            UIImage *optimizedImage = [[self class] optimizeImage:self.image];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.optimizedImageView.image = optimizedImage;
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    [tesseract setImage:optimizedImage];
                    [tesseract recognize];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        // self.textView.text = validString;
                        self.textView.text = [tesseract recognizedText];
                        [self.activityIndicator stopAnimating];
                        self.cameraButton.enabled = YES;
                    });
                });
                
            });
        });
    }
}

- (BOOL)shouldCancelImageRecognitionForTesseract:(Tesseract *)tesseract
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setProgress:tesseract.progress];
    });
    
    return NO;
}

- (void)setProgress:(NSUInteger)percent
{
    self.textView.text = [NSString stringWithFormat:@"Progress: %d", percent];
}

@end
