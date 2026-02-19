import 'models/partner.dart';

abstract class PartnersRepository {
  Future<List<Partner>> getPartners();
  Future<Partner?> getPartnerById(String id);
}
