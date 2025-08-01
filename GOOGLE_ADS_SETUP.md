# Google Mobile Ads Setup Guide

This guide explains how to set up Google Mobile Ads in your Smart Saver Flutter app.

## Current Implementation

The app is currently configured with **test ad unit IDs** for development purposes. You'll need to replace these with your actual ad unit IDs for production.

### Test Ad Unit IDs (Current)
- **Banner Ad**: `ca-app-pub-3940256099942544/6300978111`
- **Interstitial Ad**: `ca-app-pub-3940256099942544/1033173712`
- **Rewarded Ad**: `ca-app-pub-3940256099942544/5224354917`
- **Native Ad**: `ca-app-pub-3940256099942544/2247696110`

### Test App IDs (Current)
- **Android**: `ca-app-pub-3940256099942544~3347511713`
- **iOS**: `ca-app-pub-3940256099942544~1458002511`

## Setup Steps for Production

### 1. Create Google AdMob Account
1. Go to [Google AdMob](https://admob.google.com/)
2. Sign in with your Google account
3. Create a new app in AdMob console

### 2. Get Your App ID
1. In AdMob console, go to your app settings
2. Copy the App ID (format: `ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy`)

### 3. Create Ad Units
1. In AdMob console, create new ad units for:
   - Banner Ad
   - Interstitial Ad
   - Rewarded Ad (optional)
   - Native Ad (optional)
2. Copy the ad unit IDs (format: `ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy`)

### 4. Update Configuration Files

#### Update `lib/services/ads_service.dart`:
```dart
// Replace test ad unit IDs with your production IDs
static const String _bannerAdUnitId = 'your-banner-ad-unit-id';
static const String _interstitialAdUnitId = 'your-interstitial-ad-unit-id';
static const String _rewardedAdUnitId = 'your-rewarded-ad-unit-id';
static const String _nativeAdUnitId = 'your-native-ad-unit-id';
```

#### Update `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="your-android-app-id"/>
```

#### Update `ios/Runner/Info.plist`:
```xml
<key>GADApplicationIdentifier</key>
<string>your-ios-app-id</string>
```

### 5. Test Your Ads
1. Build and run your app
2. Verify that ads are loading correctly
3. Check the console logs for any ad loading errors

## Ad Placement Strategy

### Banner Ads
- **Location**: Bottom of the main screen
- **Frequency**: Always visible
- **Purpose**: Continuous monetization

### Interstitial Ads
- **Location**: After successful downloads
- **Frequency**: After each download completion
- **Purpose**: Reward user engagement

### Rewarded Ads (Optional)
- **Location**: Can be added for premium features
- **Frequency**: User-initiated
- **Purpose**: Optional monetization

## Best Practices

### 1. User Experience
- Don't show too many ads too frequently
- Ensure ads don't interfere with core app functionality
- Test ad loading times and user experience

### 2. Ad Loading
- Preload interstitial ads for better performance
- Handle ad loading failures gracefully
- Don't block the UI while ads are loading

### 3. Testing
- Always test with test ad unit IDs first
- Test on both Android and iOS devices
- Test with different network conditions

### 4. Compliance
- Follow Google AdMob policies
- Respect user privacy and GDPR requirements
- Don't place ads too close to interactive elements

## Troubleshooting

### Common Issues

1. **Ads not loading**
   - Check your internet connection
   - Verify ad unit IDs are correct
   - Check AdMob console for any policy violations

2. **App crashes on ad load**
   - Ensure proper initialization in main.dart
   - Check for memory leaks in ad disposal
   - Verify platform-specific configurations

3. **Test ads showing in production**
   - Make sure you've replaced all test ad unit IDs
   - Check that your app is approved in AdMob console
   - Wait for ad serving to begin (can take up to 24 hours)

### Debug Tips

1. Enable verbose logging:
```dart
MobileAds.instance.updateRequestConfiguration(
  RequestConfiguration(testDeviceIds: ['your-test-device-id']),
);
```

2. Check ad loading status in console logs
3. Use AdMob console to monitor ad performance
4. Test with different ad formats and sizes

## Revenue Optimization

1. **Ad Placement**: Strategic placement for maximum visibility
2. **Ad Formats**: Use appropriate formats for different contexts
3. **User Engagement**: Balance monetization with user experience
4. **A/B Testing**: Test different ad placements and frequencies

## Support

For additional help:
- [Google AdMob Documentation](https://developers.google.com/admob)
- [Flutter Google Mobile Ads Plugin](https://pub.dev/packages/google_mobile_ads)
- [AdMob Policy Center](https://support.google.com/admob/answer/6129563) 