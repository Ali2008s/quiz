import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'point_service.dart';

class AdManagerService {
  static bool _isAdFree = false;
  static bool _isAppOpenAdShowing = false;
  static AppOpenAd? _appOpenAd;

  static String get appId => !kIsWeb && Platform.isAndroid 
    ? 'ca-app-pub-8410384947331700~3990733004' 
    : 'ca-app-pub-8410384947331700~3990733004';

  static String get bannerAdId => !kIsWeb && Platform.isAndroid 
    ? 'ca-app-pub-8410384947331700/1077623036' 
    : 'ca-app-pub-8410384947331700/1077623036';

  static String get interstitialAdId => !kIsWeb && Platform.isAndroid 
    ? 'ca-app-pub-8410384947331700/1883438240' 
    : 'ca-app-pub-8410384947331700/1883438240';

  static String get rewardedAdId => !kIsWeb && Platform.isAndroid 
    ? 'ca-app-pub-8410384947331700/1259562220' 
    : 'ca-app-pub-8410384947331700/1259562220';

  static String get rewardedInterstitialAdId => !kIsWeb && Platform.isAndroid 
    ? 'ca-app-pub-8410384947331700/7322421005' 
    : 'ca-app-pub-8410384947331700/7322421005';

  static String get appOpenAdId => !kIsWeb && Platform.isAndroid 
    ? 'ca-app-pub-8410384947331700/1851648652' 
    : 'ca-app-pub-8410384947331700/1851648652';

  static Future<void> init() async {
    if (kIsWeb) return;
    await MobileAds.instance.initialize();
    await _checkAdFreeStatus();
    if (!_isAdFree) {
      loadAppOpenAd();
    }
  }

  static Future<void> _checkAdFreeStatus() async {
    try {
      final until = await PointService.getAdFreeUntil();
      _isAdFree = until.isAfter(DateTime.now());
    } catch (e) {
      _isAdFree = false;
    }
  }

  static void loadAppOpenAd() {
    if (kIsWeb || _isAdFree) return;
    
    AppOpenAd.load(
      adUnitId: appOpenAdId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('AppOpenAd failed to load: $error');
        },
      ),
    );
  }

  static void showAppOpenAd() {
    if (kIsWeb || _isAdFree || _isAppOpenAdShowing || _appOpenAd == null) return;
    
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isAppOpenAdShowing = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isAppOpenAdShowing = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isAppOpenAdShowing = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );
    _appOpenAd!.show();
  }

  static void showInterstitial() {
    if (kIsWeb || _isAdFree) return;
    
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
    if (kIsWeb) {
      onReward(10); 
      return;
    }
    
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

  static void showRewardedInterstitial(Function(int) onReward) {
    if (kIsWeb) {
      onReward(15); 
      return;
    }
    
    RewardedInterstitialAd.load(
      adUnitId: rewardedInterstitialAdId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.show(onUserEarnedReward: (ad, reward) {
            PointService.addPoints(15);
            onReward(15);
          });
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded Interstitial failed to load: $error');
        },
      ),
    );
  }
}
