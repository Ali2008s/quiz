import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'dart:io';
import 'point_service.dart';

class UnityAdService {
  static const String androidGameId = '5517112'; // Generic ID for testing, needs replacement
  static const String iosGameId = '5517113';

  static const String interstitialPlacementId = 'Interstitial_Android';
  static const String rewardedPlacementId = 'Rewarded_Android';

  static Future<void> init() async {
    await UnityAds.init(
      gameId: Platform.isAndroid ? androidGameId : iosGameId,
      testMode: true, // ALWAYS true during development
      onComplete: () => print('Unity Ads Initialized!'),
      onFailed: (error, message) => print('Unity Ads Failed: $error - $message'),
    );
  }

  static Future<void> showInterstitial() async {
    // 1. Check if user is ad-free
    if (await PointService.isAdFree()) {
      print('User is Ad-Free. Skipping ad!');
      return;
    }

    // 2. Show the ad
    UnityAds.showVideoAd(
      placementId: interstitialPlacementId,
      onComplete: (placementId) => print('Ad Complete: $placementId'),
      onFailed: (placementId, error, message) => print('Ad Failed: $placementId - $error - $message'),
      onStart: (placementId) => print('Ad Started: $placementId'),
      onClick: (placementId) => print('Ad Clicked: $placementId'),
    );
  }

  static Future<void> showRewardedAd({required Function(int) onRewardEarned}) async {
    UnityAds.showVideoAd(
      placementId: rewardedPlacementId,
      onComplete: (placementId) async {
        print('Rewarded Ad Complete: $placementId');
        await PointService.addPoints(10); // Reward 10 points!
        onRewardEarned(10);
      },
      onFailed: (placementId, error, message) => print('Rewarded Ad Failed: $placementId - $error - $message'),
      onStart: (placementId) => print('Rewarded Ad Started: $placementId'),
      onClick: (placementId) => print('Rewarded Ad Clicked: $placementId'),
    );
  }
}
