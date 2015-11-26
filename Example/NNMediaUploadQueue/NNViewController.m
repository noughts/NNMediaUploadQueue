//
//  NNViewController.m
//  NNMediaUploadQueue
//
//  Created by Koichi Yamamoto on 11/27/2015.
//  Copyright (c) 2015 Koichi Yamamoto. All rights reserved.
//

@import Photos;
#import "NNViewController.h"
#import <NNMultipleImagePickerController.h>
#import <NNMediaUploadQueue.h>

@implementation NNViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}


-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    NNMultipleImagePickerController* ipc = [NNMultipleImagePickerController instantiate];
    ipc.pickerDelegate = self;
    [self presentViewController:ipc animated:YES completion:nil];
}



-(void)imagePickerController:(NNMultipleImagePickerController *)picker didFinishPickingAssets:(NSArray<PHAsset>*)assets{
    for (PHAsset* asset in assets) {
        [[NNMediaUploadQueue sharedInstance] queueUploadImageFromAsset:asset targetSize:CGSizeMake(1334, 1334)];
    }
}


@end
