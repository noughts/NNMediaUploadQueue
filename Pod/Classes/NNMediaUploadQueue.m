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
#import "NBULogStub.h"
#import "NSURL+NNUtils.h"


NSString *const NNMediaUploadQueueUploadCompleteNotification = @"NNMediaUploadQueueUploadCompleteNotification";



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

+(NSString*)userDefaultsKey{
    return @"NNMediaUploadQueue_fileNames";
}



-(instancetype)init{
    if( self = [super init] ){
        _process_queue = [NSOperationQueue new];
        _network_queue = [NSOperationQueue new];
        _network_queue.maxConcurrentOperationCount = 2;
    }
    return self;
}


/// キューに溜まっているアップロードを再開。アプリ起動時に呼びましょう。
-(void)resume{
    /// ファイルURLリストをUserDefaultsから取得
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    NSArray<NSString*>* array = [[ud arrayForKey:[NNMediaUploadQueue userDefaultsKey]] mutableCopy];
    if( array.count == 0 ){
        NBULogInfo(@"アップロード待ちのメディアはありません");
        return;
    }
    
    NBULogInfo(@"アップロード待ちのメディアが%@件あります。", @(array.count));
    for (NSString* fileName in array) {
        NSURL* fileURL = [NSURL documentFileURLFromFileName:fileName];
        [self queueUploadImageFile:fileURL];
    }
}


/// PHAssetから画像アップロードをキューに追加
-(void)queueUploadImageFromAsset:(PHAsset*)asset targetSize:(CGSize)targetSize{
    NBULogInfo(@"PHAsset画像アップロードをキューに追加します");
    [_process_queue addOperationWithBlock:^{
        UIImage* img = [asset imageOfSize:targetSize];
        [self queueUploadImage:img];
    }];
}


/// 画像アップロードをキューに追加
-(void)queueUploadImage:(UIImage*)image{
    NBULogInfo(@"画像アップロードをキューに追加します image=%@", image);
    [_process_queue addOperationWithBlock:^{
        NSURL* url = [image saveJPEGFileToDocumentDirectoryWithoutCompressWithMetadata:nil];
        [self queueUploadImageFile:url];
    }];
}



-(void)queueUploadImageFile:(NSURL*)fileURL{
    /// アプリが再起動したあとも残りを処理できるように、UserDefaultsにストア
    [self storeFileNameToUserDefaults:fileURL];
    
    [_network_queue addOperationWithBlock:^{
        [self uploadImageFile:fileURL error:nil];
    }];
}


/// 画像ファイルをアップロード
-(NSString*)uploadImageFile:(NSURL*)fileURL error:(NSError**)error{
    NBULogInfo(@"画像のアップロードを開始します。fileURL=%@", fileURL);
    
    NSAssert( _imageServerUrlString, @"imageServerUrlStringを設定してください" );
    
    NSError* _error;
    
    AFHTTPRequestSerializer* requestSerializer = [[AFHTTPRequestSerializer alloc] init];
    NSMutableURLRequest *request = [requestSerializer multipartFormRequestWithMethod:@"POST" URLString:_imageServerUrlString parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileURL:fileURL name:@"image" fileName:@"image.jpg" mimeType:@"image/jpg" error:nil];
    } error:nil];
    NSData *contents = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&_error];
    NSString *responseString = [[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding];
    
//    if( arc4random()%100 < 50 ){
//        NBULogWarn(@"*************** デバッグのために、アップロード失敗をモックします");
//        responseString = @"";
//    }
    
    if( error || [responseString hasPrefix:@"https://"] == NO ){
        NBULogError(@"画像のアップロードに失敗しました。リトライします");
        [self queueUploadImageFile:fileURL];
        return nil;
    }
    
    NBULogInfo(@"画像のアップロードが完了しました。responseString=%@", responseString);
    [self removeFileNameFromUserDefaults:fileURL];
    
    /// アップロード完了通知
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:NNMediaUploadQueueUploadCompleteNotification object:self userInfo:@{@"fileURL":fileURL}];
    }];
    
    return responseString;
}





/// ファイル名をNSUserDefaultsに追加
-(void)storeFileNameToUserDefaults:(NSURL*)fileURL{
    NSString* fileName = fileURL.lastPathComponent;
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    NSMutableArray* array = [[ud arrayForKey:[NNMediaUploadQueue userDefaultsKey]] mutableCopy];
    if( !array ){
        array = [NSMutableArray new];
    }

    /// 重複チェック
    if( [array containsObject:fileName] ){
        NBULogInfo(@"すでにこのファイル名は登録されています。fileName=%@", fileName);
    } else {
        [array addObject:fileName];
        /// 永続化
        [ud setObject:array forKey:[NNMediaUploadQueue userDefaultsKey]];
        [ud synchronize];
    }
}


/// UserDefaultsからファイル名を削除。アップロード完了時に呼びましょう。
-(void)removeFileNameFromUserDefaults:(NSURL*)fileURL{
    NSString* fileName = fileURL.lastPathComponent;
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    NSMutableArray* array = [[ud arrayForKey:[NNMediaUploadQueue userDefaultsKey]] mutableCopy];
    [array removeObject:fileName];
    /// 永続化
    [ud setObject:array forKey:[NNMediaUploadQueue userDefaultsKey]];
    [ud synchronize];
}





@end
