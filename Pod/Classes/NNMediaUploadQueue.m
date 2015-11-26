//
//  NNMediaUploadQueue.m
//  Pods
//
//  Created by noughts on 2015/11/27.
//
//


#import "NNMediaUploadQueue.h"
#import "UIImage+NNUtils.h"
#import "AFNetworking.h"
#import "PHAsset+NNUtils.h"

@implementation NNMediaUploadQueue{
    NSOperationQueue* _process_queue;
    NSOperationQueue* _network_queue;
}


+ (instancetype)sharedInstance{
    static NNMediaUploadQueue* sharedInstance;
    static dispatch_once_t once;
    dispatch_once( &once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}


-(instancetype)init{
    if( self = [super init] ){
        _process_queue = [NSOperationQueue new];
        _network_queue = [NSOperationQueue new];
    }
    return self;
}


/// キューに溜まっているアップロードを再開。アプリ起動時に呼びましょう。
-(void)resume{
    
}


/// PHAssetから画像アップロードをキューに追加
-(void)queueUploadImageFromAsset:(PHAsset*)asset targetSize:(CGSize)targetSize{
    [_process_queue addOperationWithBlock:^{
        UIImage* img = [asset imageOfSize:targetSize];
        [self queueUploadImage:img];
    }];
}


/// 画像アップロードをキューに追加
-(void)queueUploadImage:(UIImage*)image{
    [_process_queue addOperationWithBlock:^{
        NSURL* url = [image saveJPEGFileToDocumentDirectoryWithoutCompressWithMetadata:nil];
        [_network_queue addOperationWithBlock:^{
            [self uploadImageFile:url error:nil];
        }];
    }];
}



/// 画像ファイルをアップロード
-(NSString*)uploadImageFile:(NSURL*)filePath error:(NSError**)error{
    NSAssert( _imageServerUrlString, @"imageServerUrlStringを設定してください" );
    
    NSError* _error;
    
    AFHTTPRequestSerializer* requestSerializer = [[AFHTTPRequestSerializer alloc] init];
    NSMutableURLRequest *request = [requestSerializer multipartFormRequestWithMethod:@"POST" URLString:_imageServerUrlString parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileURL:filePath name:@"image" fileName:@"image.jpg" mimeType:@"image/jpg" error:nil];
    } error:nil];
    NSData *contents = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&_error];
    NSString *responseString = [[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding];
    //	responseString = @"<html></html>";// デバッグ用
    
    return responseString;
}






@end
