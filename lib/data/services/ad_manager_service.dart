import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'point_service.dart';

class AdManagerService {
  static bool _isAdFree = false;
  static bool _isAppOpenAdShowing = false;
  static AppOpenAd? _appOpenAd;

  // ← getter عام يُستخدم في BannerAdWidget وغيرها
  static bool get isAdFree => _isAdFree;

  // ─── Ad Unit IDs (نفس الـ ID لـ Android وiOS في هذا التطبيق) ───────────────
  static String get bannerAdId => 'ca-app-pub-8410384947331700/1077623036';

  static String get interstitialAdId =>
      'ca-app-pub-8410384947331700/1883438240';

  static String get rewardedAdId => 'ca-app-pub-8410384947331700/1259562220';

  static String get rewardedInterstitialAdId =>
      'ca-app-pub-8410384947331700/7322421005';

  static String get appOpenAdId => 'ca-app-pub-8410384947331700/1851648652';

  // ─── تهيئة AdMob ──────────────────────────────────────────────────────────
  static Future<void> init() async {
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      // ✅ أضف Test Device IDs قبل التهيئة (مهم لأجهزة التطوير)

      await MobileAds.instance.initialize();
      debugPrint('✅ MobileAds initialized');
    } catch (e) {
      debugPrint('❌ MobileAds init error: $e');
    }
  }

  // يُستدعى بعد تهيئة Supabase
  static Future<void> postSupabaseInit() async {
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    await _refreshAdFreeStatus();

    if (!_isAdFree) {
      loadAppOpenAd();
    }
  }

  static Future<void> _refreshAdFreeStatus() async {
    try {
      final until = await PointService.getAdFreeUntil();
      _isAdFree = until.isAfter(DateTime.now());
    } catch (e) {
      _isAdFree = false;
    }
    debugPrint('📋 AdFree status: $_isAdFree');
  }

  // ─── App Open Ad ──────────────────────────────────────────────────────────
  static void loadAppOpenAd() {
    if (kIsWeb || _isAdFree) return;

    AppOpenAd.load(
      adUnitId: appOpenAdId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ AppOpenAd loaded');
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ AppOpenAd failed: ${error.code} - ${error.message}');
        },
      ),
    );
  }

  static void showAppOpenAd() {
    if (kIsWeb || _isAdFree || _isAppOpenAdShowing || _appOpenAd == null)
      return;

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isAppOpenAdShowing = true;
        debugPrint('✅ AppOpenAd showed');
      },
      onAdDismissedFullScreenContent: (ad) {
        _isAppOpenAdShowing = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('❌ AppOpenAd show failed: $error');
        _isAppOpenAdShowing = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );
    _appOpenAd!.show();
  }

  // ─── Interstitial ─────────────────────────────────────────────────────────
  static void showInterstitial() {
    if (kIsWeb || _isAdFree) return;

    InterstitialAd.load(
      adUnitId: interstitialAdId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ Interstitial loaded, showing...');
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('❌ Interstitial show failed: $error');
              ad.dispose();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Interstitial failed: ${error.code} - ${error.message}');
        },
      ),
    );
  }

  // ─── Rewarded ─────────────────────────────────────────────────────────────
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
          debugPrint('✅ RewardedAd loaded, showing...');
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('❌ Rewarded show failed: $error');
              ad.dispose();
            },
          );
          ad.show(onUserEarnedReward: (ad, reward) {
            PointService.addPoints(10);
            onReward(10);
          });
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Rewarded failed: ${error.code} - ${error.message}');
        },
      ),
    );
  }

  // ─── Rewarded Interstitial ─────────────────────────────────────────────────
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
          debugPrint('✅ RewardedInterstitial loaded, showing...');
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('❌ RewardedInterstitial show failed: $error');
              ad.dispose();
            },
          );
          ad.show(onUserEarnedReward: (ad, reward) {
            PointService.addPoints(15);
            onReward(15);
          });
        },
        onAdFailedToLoad: (error) {
          debugPrint(
              '❌ RewardedInterstitial failed: ${error.code} - ${error.message}');
        },
      ),
    );
  }
}
