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
    
    /*
     NSArray *colors = [[NSArray alloc] initWithObjects:
     [[UIColor alloc] initWithRed:0.00392157 green:0.0117647 blue:0.0156863 alpha:1],
     [[UIColor alloc] initWithRed:0.843137 green:0.643137 blue:0.623529 alpha:1],
     [[UIColor alloc] initWithRed:0.588235 green:0.145098 blue:0.235294 alpha:1],
     [[UIColor alloc] initWithRed:0.231373 green:0.243137 blue:0.27451 alpha:1],
     [[UIColor alloc] initWithRed:0.592157 green:0.458824 blue:0.415686 alpha:1], nil];
     UIImage *colorsImage = [self drawColors:colors];
     self.colorsImageView.image = colorsImage;
     
     NSLog(@"%@", [self validateString:@"Lorem ipsum dolor hello world."]);
     
     self.textView.text = [self validateString:@" 7 IT'S EASY TO APPLY! 3 ways to apply for the REI Visa@ card: M V - Visit: 5 ' Call: 1-877-734-9737 ext. 83971 n ' - Download: The REI Visa App1, 7 9 7 vu xx for:Phone or Android n Get a 5100 REI gift card when you apply by 2/28/2013 and make a purchase by 3/31/2013f : ,_,? _: 'SeeorferdetailsatREIVISAmmIreie391l L '- - - o 7 y . - , I '"];
     */
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

/*
 - (NSString *)validateString:(NSString *)string
 {
 NSString *validString = @"";
 NSArray *split = [string componentsSeparatedByString:@" "];
 // NSLog(@"%d", [split count]);
 for (NSString *word in split) {
 // NSString *word = [split objectAtIndex:i];
 // NSLog(@"word: %@", word);
 if ([self isDictionaryWord:word]) validString = [NSString stringWithFormat:@"%@ %@", validString, word];
 }
 return validString;
 }
 
 - (BOOL)isDictionaryWord:(NSString*)word {
 UITextChecker *checker = [[UITextChecker alloc] init];
 NSLocale *currentLocale = [NSLocale currentLocale];
 NSString *currentLanguage = [currentLocale objectForKey:NSLocaleLanguageCode];
 NSRange searchRange = NSMakeRange(0, [word length]);
 NSRange misspelledRange = [checker rangeOfMisspelledWordInString:word range: searchRange startingAt:0 wrap:NO language: currentLanguage];
 // NSLog(@"misspelledRange.location: %lu", (unsigned long)misspelledRange.location);
 return misspelledRange.location == NSNotFound;
 }
 */

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
                    
                    // NSString *validString = [self validateString:[tesseract recognizedText]];
                    
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
