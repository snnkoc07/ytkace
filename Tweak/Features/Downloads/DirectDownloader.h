#import <Foundation/Foundation.h>
#import "SABRDownloader.h"

@class YTKACEStreamOption;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const YTKACEDownloadMethodKey;
FOUNDATION_EXPORT BOOL YTKACEDirectDownloadsEnabled(void);
FOUNDATION_EXPORT BOOL YTKACETVDownloadsEnabled(void);

@interface YTKACEDirectTask : NSObject
@property(atomic, assign, readonly) BOOL paused;
- (void)pause;
- (void)resume;
- (void)cancel;
@end

@interface YTKACEDirectDownloader : NSObject

+ (void)fetchOptionsForVideoID:(NSString *)videoID
                    completion:(void (^)(NSArray<YTKACEStreamOption *> *options))completion;
+ (NSString *)codecNameForOption:(YTKACEStreamOption *)option;

+ (YTKACEDirectTask *)downloadVideoID:(NSString *)videoID
                          videoOption:(nullable YTKACEStreamOption *)videoOption
                          audioOption:(YTKACEStreamOption *)audioOption
                            audioOnly:(BOOL)audioOnly
                           identifier:(NSString *)identifier
                             progress:(nullable YTKACESABRProgress)progress
                           completion:(YTKACESABRCompletion)completion;

@end

NS_ASSUME_NONNULL_END
