import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'point_service.dart';

class AdManagerService {
  static bool _isAdFree = false;

  static String get appId => Platform.isAndroid 
    ? 'ca-app-pub-8410384947331700~5272670916' 
    : 'ca-app-pub-8410384947331700~5272670916';

  static String get bannerAdId => Platform.isAndroid 
    ? 'ca-app-pub-8410384947331700/4091184281' 
    : 'ca-app-pub-8410384947331700/4091184281';

  static String get interstitialAdId => Platform.isAndroid 
    ? 'ca-app-pub-8410384947331700/2778102615' 
    : 'ca-app-pub-8410384947331700/2778102615';

  static String get rewardedAdId => Platform.isAndroid 
    ? 'ca-app-pub-8410384947331700/9543088417' 
    : 'ca-app-pub-8410384947331700/9543088417';

  static String get appOpenAdId => Platform.isAndroid 
    ? 'ca-app-pub-8410384947331700/9822290010' 
    : 'ca-app-pub-8410384947331700/9822290010';

  static Future<void> init() async {
    if (kIsWeb) return;
    await MobileAds.instance.initialize();
    _checkAdFreeStatus();
  }

  static Future<void> _checkAdFreeStatus() async {
    final until = await PointService.getAdFreeUntil();
    _isAdFree = until.isAfter(DateTime.now());
  }

  static void showInterstitial() {
    if (_isAdFree) return;
    
    InterstitialAd.load(
      adUnitId: interstitialAdId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.show();
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load: $error');
        },
      ),
    );
  }

  static void showRewarded(Function(int) onReward) {
    RewardedAd.load(
      adUnitId: rewardedAdId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.show(onUserEarnedReward: (ad, reward) {
            PointService.addPoints(10);
            onReward(10);
          });
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded failed to load: $error');
        },
      ),
    );
  }
}
