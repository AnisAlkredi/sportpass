abstract class CheckinRepository {
  Future<Map<String, dynamic>> performCheckin(
      String qrToken, double lat, double lng);
}
