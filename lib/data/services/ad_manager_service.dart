import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'point_service.dart';

class AdManagerService {
  static bool _isAdFree = false;
  static bool _isAppOpenAdShowing = false;
  static AppOpenAd? _appOpenAd;
  static InterstitialAd? _preloadedInterstitial;
  static bool _isInterstitialLoading = false;

  // ── مؤقت التكرار: يُظهر الإعلان البيني مرة كل [_freqCap] استدعاء ──────────
  static int _interstitialCallCount = 0;
  static const int _freqCap = 3; // كل 3 ضغطات اعرض إعلاناً واحداً

  // ── getter عام يُستخدم في BannerAdWidget وغيرها ──────────────────────────
  static bool get isAdFree => _isAdFree;

  // ─── مجموعات معرفات وحدات الإعلانات ──────────────────────────────────────
  // بانر
  static String get bannerAdId {
    if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // Test ID iOS
    }
    return 'ca-app-pub-8410384947331700/1077623036';
  }

  // بمكافأة
  static String get rewardedAdId {
    if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // Test ID iOS
    }
    return 'ca-app-pub-8410384947331700/1259562220';
  }

  // إعلان بيني
  static String get interstitialAdId {
    if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Test ID iOS
    }
    return 'ca-app-pub-8410384947331700/1883438240';
  }

  // إعلان بيني مقابل مكافأة
  static String get rewardedInterstitialAdId {
    if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/6978759866'; // Test ID iOS
    }
    return 'ca-app-pub-8410384947331700/7322421005';
  }

  // إعلان على شاشة فتح التطبيق
  static String get appOpenAdId {
    if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/5662855259'; // Test ID iOS
    }
    return 'ca-app-pub-8410384947331700/1851648652';
  }

  // ─── تهيئة AdMob ──────────────────────────────────────────────────────────
  static Future<void> init() async {
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
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
      _preloadInterstitial(); // تحميل الإعلان البيني مسبقاً
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

  // ─── تحميل الإعلان البيني مسبقاً (Preload) ───────────────────────────────
  static void _preloadInterstitial() {
    if (kIsWeb || _isAdFree || _isInterstitialLoading) return;
    if (_preloadedInterstitial != null) return; // موجود بالفعل

    _isInterstitialLoading = true;
    debugPrint('⏳ Preloading interstitial...');

    InterstitialAd.load(
      adUnitId: interstitialAdId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _preloadedInterstitial = ad;
          _isInterstitialLoading = false;
          debugPrint('✅ Interstitial preloaded and ready');
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          _preloadedInterstitial = null;
          debugPrint('❌ Interstitial preload failed: ${error.code} - ${error.message}');
          // إعادة المحاولة بعد 30 ثانية
          Future.delayed(const Duration(seconds: 30), _preloadInterstitial);
        },
      ),
    );
  }

  // ─── إعلان فتح التطبيق (App Open) ────────────────────────────────────────
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
    if (kIsWeb || _isAdFree || _isAppOpenAdShowing || _appOpenAd == null) {
      return;
    }

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

  // ─── إعلان بيني (Interstitial) ────────────────────────────────────────────
  // يستخدم الإعلان المحمّل مسبقاً للعرض الفوري بدون تأخير
  // مع Frequency Cap: لا يعرض الإعلان إلا مرة كل [_freqCap] استدعاءات
  static void showInterstitial({VoidCallback? onAdClosed}) {
    if (kIsWeb || _isAdFree) {
      onAdClosed?.call();
      return;
    }

    // احسب الاستدعاء وتحقق من الـ cap
    _interstitialCallCount++;
    if (_interstitialCallCount % _freqCap != 0) {
      // ليس وقت الإعلان → انتقل مباشرة
      debugPrint('⏭️ Interstitial skipped ($_interstitialCallCount/$_freqCap)');
      onAdClosed?.call();
      return;
    }

    // إذا كان الإعلان جاهزاً → عرضه فوراً
    if (_preloadedInterstitial != null) {
      final ad = _preloadedInterstitial!;
      _preloadedInterstitial = null; // أفرغه لتحميل واحد جديد

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          onAdClosed?.call();
          _preloadInterstitial(); // حمّل الإعلان التالي
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('❌ Interstitial show failed: $error');
          ad.dispose();
          onAdClosed?.call();
          _preloadInterstitial();
        },
      );
      ad.show();
    } else {
      // إذا لم يكن جاهزاً → انتقل مباشرة ولا تنتظر
      debugPrint('⚠️ No preloaded interstitial, navigating directly');
      onAdClosed?.call();
      // ابدأ التحميل للمرة القادمة
      _preloadInterstitial();
    }
  }

  // ─── إعلان بالمكافأة (Rewarded) ──────────────────────────────────────────
  static void showRewarded(Function(int) onReward) {
    if (kIsWeb) {
      onReward(10);
      return;
    }
    if (_isAdFree) {
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

  // ─── إعلان بيني مقابل مكافأة (Rewarded Interstitial) ─────────────────────
  static void showRewardedInterstitial(Function(int) onReward) {
    if (kIsWeb) {
      onReward(15);
      return;
    }
    if (_isAdFree) {
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
