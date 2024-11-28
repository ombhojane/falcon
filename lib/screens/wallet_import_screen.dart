import 'package:flutter/material.dart';
import '../services/wallet_service.dart';
import '../models/wallet_model.dart';

class WalletImportScreen extends StatefulWidget {
  const WalletImportScreen({super.key});

  @override
  State<WalletImportScreen> createState() => _WalletImportScreenState();
}

class _WalletImportScreenState extends State<WalletImportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _isLoading = false;
  bool _isMnemonic = true;
  WalletType _walletType = WalletType.ethereum;
  final _walletService = WalletService();

  Future<void> _importWallet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      WalletInfo wallet;
      if (_isMnemonic) {
        wallet = await _walletService.importFromMnemonic(
          _controller.text.trim(),
          _walletType,
        );
      } else {
        wallet = await _walletService.importFromPrivateKey(
          _controller.text.trim(),
          _walletType,
        );
      }

      await _walletService.storeWallet(wallet);
      if (mounted) {
        Navigator.pop(context, wallet);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Wallet'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<WalletType>(
                segments: const [
                  ButtonSegment(
                    value: WalletType.ethereum,
                    label: Text('Ethereum'),
                  ),
                  ButtonSegment(
                    value: WalletType.solana,
                    label: Text('Solana'),
                  ),
                ],
                selected: {_walletType},
                onSelectionChanged: (Set<WalletType> selected) {
                  setState(() {
                    _walletType = selected.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Recovery Phrase'),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Private Key'),
                  ),
                ],
                selected: {_isMnemonic},
                onSelectionChanged: (Set<bool> selected) {
                  setState(() {
                    _isMnemonic = selected.first;
                  });
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _controller,
                maxLines: _isMnemonic ? 3 : 1,
                decoration: InputDecoration(
                  labelText: _isMnemonic ? 'Recovery Phrase' : 'Private Key',
                  hintText: _isMnemonic
                      ? 'Enter your 12 or 24 word recovery phrase'
                      : 'Enter your private key',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  if (_isMnemonic) {
                    final wordCount = value.trim().split(' ').length;
                    if (wordCount != 12 && wordCount != 24) {
                      return 'Please enter 12 or 24 words';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _importWallet,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Import ${_walletType.name.toUpperCase()} Wallet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
