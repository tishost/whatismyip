import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class AdService {
  static Future<bool> isProUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyIsProUser) ?? false;
  }

  static Future<void> setProUser(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsProUser, value);
  }

  static Future<BannerAd?> createBannerAd({
    required AdSize adSize,
    required void Function(Ad) onAdLoaded,
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
  }) async {
    if (!AppConstants.adsEnabled) return null;
    if (await isProUser()) return null;
    
    return BannerAd(
      adUnitId: AppConstants.bannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    )..load();
  }

  static Future<InterstitialAd?> createInterstitialAd({
    required void Function() onAdDismissed,
    required void Function(LoadAdError) onAdFailedToLoad,
  }) async {
    if (!AppConstants.adsEnabled) return null;
    if (await isProUser()) return null;
    
    InterstitialAd.load(
      adUnitId: AppConstants.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              onAdDismissed();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
    return null;
  }

  static Future<RewardedAd?> createRewardedAd({
    required void Function(RewardedAd) onAdLoaded,
    required void Function(LoadAdError) onAdFailedToLoad,
  }) async {
    if (!AppConstants.adsEnabled) return null;
    if (await isProUser()) return null;
    
    RewardedAd.load(
      adUnitId: AppConstants.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
    return null;
  }
}

