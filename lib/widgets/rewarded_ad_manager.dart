import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ads_service.dart';

class RewardedAdManager {
  static RewardedAd? _rewardedAd;
  static bool _isLoading = false;

  static Future<void> loadRewardedAd() async {
    if (_isLoading) {
      print('Rewarded ad already loading, waiting...');
      // Wait for current loading to complete
      int attempts = 0;
      while (_isLoading && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }
      if (_isLoading) {
        print('Rewarded ad loading timeout, resetting...');
        _isLoading = false;
      }
    }
    
    if (_rewardedAd != null) {
      print('Rewarded ad already loaded');
      return;
    }

    print('Loading rewarded ad...');
    _isLoading = true;
    try {
      _rewardedAd = await AdsService.createRewardedAd();
      print('Rewarded ad created successfully');
      
      _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          print('Rewarded ad dismissed');
          ad.dispose();
          _rewardedAd = null;
          _isLoading = false;
          // Load the next ad
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('Rewarded ad failed to show: $error');
          ad.dispose();
          _rewardedAd = null;
          _isLoading = false;
        },
        onAdShowedFullScreenContent: (ad) {
          print('Rewarded ad showed full screen content');
        },
      );
      print('Rewarded ad loaded and ready');
    } catch (e) {
      print('Error loading rewarded ad: $e');
      _isLoading = false;
      _rewardedAd = null;
    }
  }

  static Future<bool> showRewardedAd() async {
    print('Attempting to show rewarded ad...');
    
    // Try to load ad if not ready
    if (_rewardedAd == null) {
      print('Rewarded ad is null, trying to load...');
      await loadRewardedAd();
      
      // Wait a bit more for ad to be ready
      int attempts = 0;
      while (_rewardedAd == null && attempts < 5) {
        await Future.delayed(const Duration(milliseconds: 1000));
        attempts++;
        print('Waiting for rewarded ad to load... attempt $attempts');
      }
      
      if (_rewardedAd == null) {
        print('Failed to load rewarded ad after waiting');
        return false;
      }
    }

    try {
      print('Showing rewarded ad...');
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          print('User earned reward: ${reward.amount} ${reward.type}');
        },
      );
      print('Rewarded ad shown successfully');
      return true;
    } catch (e) {
      print('Error showing rewarded ad: $e');
      return false;
    }
  }

  static bool get isAdReady => _rewardedAd != null;

  static void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isLoading = false;
  }
} 