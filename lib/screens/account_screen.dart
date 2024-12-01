import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../models/wallet_model.dart';
import '../models/user_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:material_symbols_icons/symbols.dart';

class AccountScreen extends StatefulWidget {
  final WalletInfo? wallet;
  final Function() onBack;
  final Function() onWalletImport;
  final Function(String name, String avatar) onNameUpdate;

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
  String _currentAvatar = "👤";
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('user_settings');
    if (settingsJson != null) {
      final settings = UserSettings.fromJson(json.decode(settingsJson));
      setState(() {
        _currentName = settings.name;
        _currentAvatar = settings.avatar;
        _nameController.text = _currentName;
      });
    }
  }

  Future<void> _saveUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = UserSettings(
      name: _nameController.text.trim(),
      avatar: _currentAvatar,
    );
    await prefs.setString('user_settings', json.encode(settings.toJson()));
    widget.onNameUpdate(_nameController.text.trim(), _currentAvatar);
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      builder: (BuildContext context) {
        return SizedBox(
          height: 300,
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              setState(() {
                _currentAvatar = emoji.emoji;
              });
              Navigator.pop(context);
            },
          ),
        );
      },
    );
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
          if (_isEditing)
            TextButton(
              onPressed: () {
                _saveUserSettings();
                setState(() => _isEditing = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully')),
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
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _isEditing ? _showEmojiPicker : null,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _currentAvatar,
                                  style: const TextStyle(fontSize: 32),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _isEditing
                                ? TextField(
                                    controller: _nameController,
                                    style: AppTheme.titleLarge,
                                    decoration: InputDecoration(
                                      border: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: AppTheme.textGrey),
                                      ),
                                      hintText: 'Enter your name',
                                      hintStyle: AppTheme.titleLarge.copyWith(color: AppTheme.textGrey),
                                    ),
                                  )
                                : Text(
                                    _currentName,
                                    style: AppTheme.titleLarge,
                                  ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isEditing ? Icons.close : Icons.edit,
                              color: AppTheme.textLight,
                            ),
                            onPressed: () {
                              setState(() {
                                if (_isEditing) {
                                  _nameController.text = _currentName;
                                }
                                _isEditing = !_isEditing;
                              });
                            },
                          ),
                        ],
                      ),
                      if (_isEditing) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Tap the avatar to change emoji',
                          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textGrey),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Wallet Section
              if (widget.wallet != null) ...[
                Card(
                  color: AppTheme.cardDark,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Wallet',
                                  style: AppTheme.titleMedium.copyWith(
                                    color: AppTheme.textGrey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      widget.wallet!.walletType == WalletType.ethereum
                                          ? Symbols.currency_bitcoin  // Better crypto icon
                                          : Icons.solar_power,
                                      color: AppTheme.primary,
                                      size: 24,
                                      weight: 700,  // Make the icon bolder
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.wallet!.walletType.name.toUpperCase(),
                                      style: AppTheme.titleLarge.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: AppTheme.primary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Connected',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Balance',
                                style: AppTheme.titleMedium.copyWith(
                                  color: AppTheme.textGrey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.wallet!.mainBalance,
                                style: AppTheme.headlineLarge.copyWith(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.textGrey.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Wallet Address',
                                    style: AppTheme.titleMedium.copyWith(
                                      color: AppTheme.textGrey,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(
                                        ClipboardData(text: widget.wallet!.address),
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Address copied to clipboard'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.copy,
                                            color: AppTheme.primary,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Copy',
                                            style: AppTheme.bodySmall.copyWith(
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.wallet!.address,
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.textLight.withOpacity(0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Card(
                  color: AppTheme.cardDark,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: widget.onWalletImport,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_outlined,
                              color: AppTheme.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Connect Wallet',
                            style: AppTheme.titleLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Import your existing wallet or create a new one',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textGrey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
