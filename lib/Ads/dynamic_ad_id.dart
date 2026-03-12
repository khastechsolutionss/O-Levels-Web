class AdIdModel {
  String adId;
  bool status;
  AdIdModel({required this.adId, required this.status});
}

class DynamicAdIds {
  AdIdModel openAd;
  AdIdModel backInt;
  AdIdModel bannerAd;
  AdIdModel startInt;
  AdIdModel msint;
  AdIdModel selectInt;
  AdIdModel native;
  bool customBannerStatus;
  bool customInterstitialStatus;
  String customBannerUrl;
  String customInterstitialUrl;

  DynamicAdIds({
    required this.openAd,
    required this.backInt,
    required this.bannerAd,
    required this.startInt,
    required this.msint,
    required this.selectInt,
    required this.native,
    required this.customBannerStatus,
    required this.customInterstitialStatus,
    required this.customBannerUrl,
    required this.customInterstitialUrl,
  });

  factory DynamicAdIds.fromMap(Map<String, dynamic> map) {
    // O-Level Custom Ad URLs
    const String kHardcodedBannerUrl =
        "https://openeduforum.com/pages/O_Levels_Past_Papers/json_files/OLevel-banner.json";
    const String kHardcodedInterstitialUrl =
        "https://openeduforum.com/pages/O_Levels_Past_Papers/json_files/OLevel-Intads.json";

    bool customBannerEnabled = map['apibanner'] ?? false;
    bool customInterstitialEnabled = map['apiinterstitial'] ?? false;

    return DynamicAdIds(
      openAd: AdIdModel(
        adId: map['OpenAd_ID'] ?? '',
        status: map['OpenAd_Status'] ?? false,
      ),
      backInt: AdIdModel(
        adId: map['BackInt_ID'] ?? '',
        status: map['BackInt_Status'] ?? false,
      ),
      startInt: AdIdModel(
        adId: map['StartInt_ID'] ?? '',
        status: map['StartInt_Status'] ?? false,
      ),
      bannerAd: AdIdModel(
        adId: map['Banner_ID'] ?? '',
        status: map['Banner_Status'] ?? false,
      ),
      msint: AdIdModel(
        adId: map['MSInt_ID'] ?? '',
        status: map['MSInt_Status'] ?? false,
      ),
      selectInt: AdIdModel(
        adId: map['SelectInt_ID'] ?? '',
        status: map['SelectInt_Status'] ?? false,
      ),
      native: AdIdModel(
        adId: map['NativeAd_ID'] ?? '',
        status: map['NativeAd_Status'] ?? false,
      ),
      customBannerStatus: customBannerEnabled,
      customInterstitialStatus: customInterstitialEnabled,
      customBannerUrl: kHardcodedBannerUrl,
      customInterstitialUrl: kHardcodedInterstitialUrl,
    );
  }
}
