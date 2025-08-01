import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  // Test Ad Unit IDs - Replace with your actual ad unit IDs for production
  static const String _bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _nativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';

  // Production Ad Unit IDs (uncomment and replace when ready for production)
  // static const String _bannerAdUnitId = 'your-banner-ad-unit-id';
  // static const String _interstitialAdUnitId = 'your-interstitial-ad-unit-id';
  // static const String _rewardedAdUnitId = 'your-rewarded-ad-unit-id';
  // static const String _nativeAdUnitId = 'your-native-ad-unit-id';

  static String get bannerAdUnitId => _bannerAdUnitId;
  static String get interstitialAdUnitId => _interstitialAdUnitId;
  static String get rewardedAdUnitId => _rewardedAdUnitId;
  static String get nativeAdUnitId => _nativeAdUnitId;

  // Create a banner ad
  static BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('Banner ad loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed to load: $error');
          ad.dispose();
        },
        onAdOpened: (ad) {
          print('Banner ad opened');
        },
        onAdClosed: (ad) {
          print('Banner ad closed');
        },
      ),
    );
  }

  // Create an interstitial ad
  static Future<InterstitialAd?> createInterstitialAd() async {
    try {
      InterstitialAd? interstitialAd;
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            interstitialAd = ad;
            print('Interstitial ad loaded successfully');
          },
          onAdFailedToLoad: (error) {
            print('Interstitial ad failed to load: $error');
          },
        ),
      );
      return interstitialAd;
    } catch (e) {
      print('Error creating interstitial ad: $e');
      return null;
    }
  }

  // Create a rewarded ad
  static Future<RewardedAd?> createRewardedAd() async {
    try {
      RewardedAd? rewardedAd;
      await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            rewardedAd = ad;
            print('Rewarded ad loaded successfully');
          },
          onAdFailedToLoad: (error) {
            print('Rewarded ad failed to load: $error');
          },
        ),
      );
      return rewardedAd;
    } catch (e) {
      print('Error creating rewarded ad: $e');
      return null;
    }
  }

  // Create a native ad
  static NativeAd createNativeAd() {
    return NativeAd(
      adUnitId: nativeAdUnitId,
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          print('Native ad loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          print('Native ad failed to load: $error');
          ad.dispose();
        },
        onAdOpened: (ad) {
          print('Native ad opened');
        },
        onAdClosed: (ad) {
          print('Native ad closed');
        },
      ),
    );
  }
} 