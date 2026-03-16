import 'package:purchases_flutter/purchases_flutter.dart';

class OfferingModel {
  final String identifier;
  final String title;
  final String description;
  final String priceString;
  final Package rcPackage;

  const OfferingModel({
    required this.identifier,
    required this.title,
    required this.description,
    required this.priceString,
    required this.rcPackage,
  });

  factory OfferingModel.fromRCPackage(Package package) {
    return OfferingModel(
      identifier: package.identifier,
      title: package.storeProduct.title,
      description: package.storeProduct.description,
      priceString: package.storeProduct.priceString,
      rcPackage: package,
    );
  }

  /// Whether this offering should be highlighted as the recommended choice.
  /// Annual/yearly plans are recommended by default.
  bool get isRecommended {
    final id = identifier.toLowerCase();
    return id.contains('annual') || id.contains('yearly');
  }
}
