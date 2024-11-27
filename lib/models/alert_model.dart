class PriceAlert {
  final String cryptoId;
  final double targetPrice;
  final bool isGreaterThan;

  PriceAlert({
    required this.cryptoId,
    required this.targetPrice,
    required this.isGreaterThan,
  });
} 