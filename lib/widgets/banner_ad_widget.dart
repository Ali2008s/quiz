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
  static const int _maxRetries = 5;
  // ارتفاع البانر الثابت حتى لا يقفز التخطيط
  static const double _bannerHeight = 50.0;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadAd();
      });
    }
  }

  Future<void> _loadAd() async {
    if (!mounted) return;
    if (AdManagerService.isAdFree) return;

    _bannerAd = BannerAd(
      adUnitId: AdManagerService.bannerAdId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ BannerAd loaded');
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint(
              '❌ BannerAd failed [${_retryCount + 1}/$_maxRetries]: ${error.message}');
          ad.dispose();
          _bannerAd = null;
          if (mounted) setState(() => _isLoaded = false);
          if (_retryCount < _maxRetries) {
            _retryCount++;
            // تأخير تدريجي: 10ث، 20ث، 30ث ...
            final delay = Duration(seconds: 10 * _retryCount);
            Future.delayed(delay, () {
              if (mounted) _loadAd();
            });
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
    // لا تعرض شيئاً على الويب أو إذا كان الاشتراك مفعلاً
    if (kIsWeb) return const SizedBox.shrink();
    if (!Platform.isAndroid && !Platform.isIOS) return const SizedBox.shrink();
    if (AdManagerService.isAdFree) return const SizedBox.shrink();

    // احجز المساحة دائماً حتى تُظهر البانر فور تحميله بدون قفز
    return SizedBox(
      height: _bannerHeight,
      child: _isLoaded && _bannerAd != null
          ? AdWidget(ad: _bannerAd!)
          : const SizedBox.shrink(), // مساحة فارغة أثناء التحميل
    );
  }
}
