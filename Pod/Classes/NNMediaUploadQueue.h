//
//  NNMediaUploadQueue.h
//  Pods
//
//  Created by noughts on 2015/11/27.
//
//

@import Photos;
#import <Foundation/Foundation.h>



extern NSString *const NNMediaUploadQueueUploadCompleteNotification;






@interface NNMediaUploadQueue : NSObject

@property NSString* imageServerUrlString;


+ (instancetype)sharedInstance;

/// キューに溜まっているアップロードを再開。アプリ起動時に呼びましょう。
-(void)resume;

/// 画像ファイルURLをアップロードキューに追加
-(void)queueUploadImageFile:(NSURL*)fileURL;

/// 画像アップロードをキューに追加
-(void)queueUploadImage:(UIImage*)image;

/// PHAssetから画像アップロードをキューに追加
-(void)queueUploadImageFromAsset:(PHAsset*)asset targetSize:(CGSize)targetSize;

@end
