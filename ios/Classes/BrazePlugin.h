#import <Flutter/Flutter.h>

@class ABKInAppMessage;
@class ABKContentCard;

@interface BrazePlugin : NSObject<FlutterPlugin>

/**
 * Process the In-App Message it in the Flutter layer.
 * @discussion If multiple Braze plugins have been allocated in the host app,
 *             perform this on each of the Flutter channels.
 */
+ (void)processInAppMessage:(ABKInAppMessage *)inAppMessage;

/**
 * Process the Content Cards it in the Flutter layer.
 * @discussion If multiple Braze plugins have been allocated in the host app,
 *             perform this on each of the Flutter channels.
 */
+ (void)processContentCards:(NSArray<ABKContentCard *> *)cards;

@end
