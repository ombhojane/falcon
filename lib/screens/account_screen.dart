import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/wallet_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountScreen extends StatefulWidget {
  final WalletInfo? wallet;
  final Function() onBack;
  final Function() onWalletImport;
  final Function(String) onNameUpdate;

  const AccountScreen({
    Key? key,
    required this.wallet,
    required this.onBack,
    required this.onWalletImport,
    required this.onNameUpdate,
  }) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _currentName = "User";

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentName = prefs.getString('user_name') ?? "User";
      _nameController.text = _currentName;
    });
  }

  Future<void> _saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    widget.onNameUpdate(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textLight),
          onPressed: widget.onBack,
        ),
        title: Text(
          'Your Account',
          style: AppTheme.titleLarge,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _saveName(_nameController.text);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Name saved successfully')),
              );
            },
            child: Text('Save', style: AppTheme.titleMedium.copyWith(color: AppTheme.primary)),
          ),
        ],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: AppTheme.cardDark,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppTheme.primary,
                        child: const Icon(Icons.person, size: 35, color: AppTheme.textLight),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          style: AppTheme.titleLarge,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(
                              borderSide: BorderSide(color: AppTheme.textGrey),
                            ),
                            hintText: 'Enter your name',
                            hintStyle: AppTheme.titleLarge.copyWith(color: AppTheme.textGrey),
                          ),
                          onSubmitted: (value) {
                            _saveName(value);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Name saved successfully')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Wallet Section
              Card(
                color: AppTheme.cardDark,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wallet',
                        style: AppTheme.titleLarge,
                      ),
                      if (widget.wallet != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Balance',
                          style: AppTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.wallet!.mainBalance,
                          style: AppTheme.headlineLarge,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Address',
                          style: AppTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.wallet!.address,
                                  style: AppTheme.titleMedium.copyWith(color: AppTheme.textGrey),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, color: AppTheme.primary),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: widget.wallet!.address));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Address copied to clipboard')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Type: ${widget.wallet!.walletType.toString().split('.').last.toUpperCase()}',
                          style: AppTheme.titleMedium,
                        ),
                      ] else ...[
                        const SizedBox(height: 16),
                        Text(
                          'No wallet connected',
                          style: AppTheme.titleMedium.copyWith(color: AppTheme.textGrey),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Connect Wallet Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onWalletImport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.wallet == null ? 'Connect Wallet' : 'Import Another Wallet',
                    style: AppTheme.titleMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
