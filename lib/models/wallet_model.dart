enum WalletType {
  ethereum,
  solana,
}

class WalletInfo {
  final String address;
  final String privateKey;
  final Map<String, double> balances;
  final WalletType walletType;

  WalletInfo({
    required this.address,
    required this.privateKey,
    required this.balances,
    required this.walletType,
  });

  factory WalletInfo.fromJson(Map<String, dynamic> json) {
    return WalletInfo(
      address: json['address'] as String,
      privateKey: json['privateKey'] as String,
      balances: Map<String, double>.from(json['balances'] as Map),
      walletType: WalletType.values.firstWhere(
        (e) => e.toString() == json['walletType'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'privateKey': privateKey,
      'balances': balances,
      'walletType': walletType.toString(),
    };
  }

  String get mainBalance => walletType == WalletType.ethereum
      ? '${balances['ETH']?.toStringAsFixed(4) ?? '0.0000'} ETH'
      : '${balances['SOL']?.toStringAsFixed(4) ?? '0.0000'} SOL';
}