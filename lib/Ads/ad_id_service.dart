import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:olevel/Ads/dynamic_ad_id.dart';

class DynamicAdsService {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  Stream<DynamicAdIds?> getAdIds() {
    return firestore
        .collection('ADS')
        .doc('khastech')
        .snapshots()
        .map(
          (event) =>
              event.data() == null ? null : DynamicAdIds.fromMap(event.data()!),
        );
  }
}
