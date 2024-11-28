import 'dart:convert';
import 'dart:typed_data';
import 'package:solana/base58.dart';
import 'package:web3dart/web3dart.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:hex/hex.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solana/solana.dart';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import '../models/wallet_model.dart';

// Add this method to the WalletService class
Uint8List base58decode(String base58String) {
  const base58Alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  
  // Convert base58 string to big integer
  BigInt value = BigInt.zero;
  for (int i = 0; i < base58String.length; i++) {
    final charIndex = base58Alphabet.indexOf(base58String[i]);
    if (charIndex == -1) {
      throw FormatException('Invalid Base58 character: ${base58String[i]}');
    }
    value = value * BigInt.from(58) + BigInt.from(charIndex);
  }

  // Convert big integer to bytes
  final bytes = value.toRadixString(16);
  final paddedBytes = bytes.padLeft(bytes.length + (bytes.length % 2), '0');
  return Uint8List.fromList(HEX.decode(paddedBytes));
}

class WalletService {
  static const String _walletKey = 'wallet_info';
  final Web3Client _ethClient = Web3Client(
    'https://mainnet.infura.io/v3/YOUR-PROJECT-ID',
    http.Client(),
  );
  final SolanaClient _solClient = SolanaClient(
    rpcUrl: Uri.parse('https://api.mainnet-beta.solana.com'),
    websocketUrl: Uri.parse('wss://api.mainnet-beta.solana.com'),
  );
  
  Future<WalletInfo?> getStoredWallet() async {
    final prefs = await SharedPreferences.getInstance();
    final walletJson = prefs.getString(_walletKey);
    if (walletJson == null) return null;
    return WalletInfo.fromJson(json.decode(walletJson));
  }

  Future<void> storeWallet(WalletInfo wallet) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_walletKey, json.encode(wallet.toJson()));
  }

  Future<WalletInfo> importFromMnemonic(String mnemonic, WalletType type) async {
    if (!bip39.validateMnemonic(mnemonic)) {
      throw Exception('Invalid mnemonic phrase');
    }

    switch (type) {
      case WalletType.ethereum:
        return _importEthereumFromMnemonic(mnemonic);
      case WalletType.solana:
        return _importSolanaFromMnemonic(mnemonic);
    }
  }

  Future<WalletInfo> importFromPrivateKey(String privateKey, WalletType type) async {
    switch (type) {
      case WalletType.ethereum:
        return _importEthereumFromPrivateKey(privateKey);
      case WalletType.solana:
        return _importSolanaFromPrivateKey(privateKey);
    }
  }

  Future<WalletInfo> _importEthereumFromMnemonic(String mnemonic) async {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final privateKey = HEX.encode(seed.sublist(0, 32));
    return _importEthereumFromPrivateKey(privateKey);
  }

  Future<WalletInfo> _importEthereumFromPrivateKey(String privateKey) async {
    if (!privateKey.startsWith('0x')) {
      privateKey = '0x$privateKey';
    }
    
    final credentials = EthPrivateKey.fromHex(privateKey);
    final address = await credentials.extractAddress();
    final balance = await _ethClient.getBalance(address);
    
    return WalletInfo(
      address: address.hex,
      privateKey: privateKey.substring(2),
      balances: {'ETH': balance.getValueInUnit(EtherUnit.ether)},
      walletType: WalletType.ethereum,
    );
  }

  Future<WalletInfo> _importSolanaFromMnemonic(String mnemonic) async {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final keyData = await ED25519_HD_KEY.derivePath(
      "m/44'/501'/0'/0'",
      seed,
    );
    final privateKey = base58encode(keyData.key);
    return _importSolanaFromPrivateKey(privateKey);
  }

  Future<WalletInfo> _importSolanaFromPrivateKey(String privateKey) async {
    final keyPair = await Ed25519HDKeyPair.fromPrivateKeyBytes(
      privateKey: base58decode(privateKey),
    );
    final balance = await _solClient.rpcClient.getBalance(
      keyPair.address,
      commitment: Commitment.confirmed,
    );
    
    return WalletInfo(
      address: keyPair.address,
      privateKey: privateKey,
      balances: {'SOL': balance.value / lamportsPerSol},
      walletType: WalletType.solana,
    );
  }

  Future<Map<String, double>> getBalances(WalletInfo wallet) async {
    switch (wallet.walletType) {
      case WalletType.ethereum:
        final ethAddress = EthereumAddress.fromHex(wallet.address);
        final balance = await _ethClient.getBalance(ethAddress);
        return {'ETH': balance.getValueInUnit(EtherUnit.ether)};
      
      case WalletType.solana:
        final balance = await _solClient.rpcClient.getBalance(
          wallet.address,
          commitment: Commitment.confirmed,
        );
        return {'SOL': balance.value / lamportsPerSol};
    }
  }
}
