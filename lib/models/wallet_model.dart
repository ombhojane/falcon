enum WalletType {
  ethereum,
  solana,
}

class WalletInfo {
  final String address;
  final String privateKey;
  final Map<String, double> balances;
  final WalletType walletType;
  String name;

  WalletInfo({
    required this.address,
    required this.privateKey,
    required this.balances,
    required this.walletType,
    this.name = '',
  });

  factory WalletInfo.fromJson(Map<String, dynamic> json) {
    return WalletInfo(
      address: json['address'] as String,
      privateKey: json['privateKey'] as String,
      balances: Map<String, double>.from(json['balances'] as Map),
      walletType: WalletType.values.firstWhere(
        (e) => e.toString() == json['walletType'],
      ),
      name: json['name'] ?? '', // Added this line
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'privateKey': privateKey,
      'balances': balances,
      'walletType': walletType.toString(),
      'name': name, // Added this line
    };
  }

  String get mainBalance => walletType == WalletType.ethereum
      ? '${balances['ETH']?.toStringAsFixed(4) ?? '0.0000'} ETH'
      : '${balances['SOL']?.toStringAsFixed(4) ?? '0.0000'} SOL';
}
