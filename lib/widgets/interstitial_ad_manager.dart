import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ads_service.dart';

class InterstitialAdManager {
  static InterstitialAd? _interstitialAd;
  static bool _isLoading = false;

  static Future<void> loadInterstitialAd() async {
    if (_isLoading || _interstitialAd != null) return;

    _isLoading = true;
    try {
      _interstitialAd = await AdsService.createInterstitialAd();
      
      _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _isLoading = false;
          // Load the next ad
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('Interstitial ad failed to show: $error');
          ad.dispose();
          _interstitialAd = null;
          _isLoading = false;
        },
        onAdShowedFullScreenContent: (ad) {
          print('Interstitial ad showed full screen content');
        },
      );
    } catch (e) {
      print('Error loading interstitial ad: $e');
      _isLoading = false;
    }
  }

  static Future<bool> showInterstitialAd() async {
    if (_interstitialAd == null) {
      await loadInterstitialAd();
      return false;
    }

    try {
      await _interstitialAd!.show();
      return true;
    } catch (e) {
      print('Error showing interstitial ad: $e');
      return false;
    }
  }

  static void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isLoading = false;
  }
} 