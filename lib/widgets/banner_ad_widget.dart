import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../data/services/ad_manager_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  int _retryCount = 0;
  static const int _maxRetries = 3; // أقصى 3 محاولات

  @override
  void initState() {
    super.initState();
    // نستخدم addPostFrameCallback حتى يكون الـ context جاهزاً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAd();
    });
  }

  Future<void> _loadAd() async {
    // لا تحمّل إعلاناً على الويب
    if (kIsWeb) return;
    // فقط Android و iOS
    if (!Platform.isAndroid && !Platform.isIOS) return;
    // لا تحمّل إذا كان المستخدم ad-free
    if (AdManagerService.isAdFree) return;

    _bannerAd = BannerAd(
      adUnitId: AdManagerService.bannerAdId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ BannerAd loaded successfully');
          if (mounted) {
            setState(() => _isLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ BannerAd failed [محاولة ${_retryCount + 1}/$_maxRetries]: [${error.code}] ${error.message}');
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isLoaded = false;
            });
          }
          // أعد المحاولة بعد 5 دقائق بحد أقصى 3 محاولات
          if (_retryCount < _maxRetries) {
            _retryCount++;
            Future.delayed(const Duration(minutes: 5), () {
              if (mounted) _loadAd();
            });
          } else {
            debugPrint('⛔ BannerAd: توقفت المحاولة بعد $_maxRetries محاولات فاشلة');
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
