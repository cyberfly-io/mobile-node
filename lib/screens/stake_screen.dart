import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wallet_service.dart';
import '../theme/theme.dart';

class StakeScreen extends StatefulWidget {
  const StakeScreen({super.key});

  @override
  State<StakeScreen> createState() => _StakeScreenState();
}

class _StakeScreenState extends State<StakeScreen> {
  final _amountController = TextEditingController();
  bool _isStaking = false;
  bool _isUnstaking = false;

  // Placeholder values - replace with actual blockchain queries
  double _stakedAmount = 0.0;
  double _availableBalance = 0.0;
  double _pendingRewards = 0.0;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _stake() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    setState(() => _isStaking = true);

    try {
      // TODO: Implement staking via Rust API
      await Future.delayed(const Duration(seconds: 2));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Staking not yet implemented')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isStaking = false);
    }
  }

  Future<void> _unstake() async {
    setState(() => _isUnstaking = true);

    try {
      // TODO: Implement unstaking via Rust API
      await Future.delayed(const Duration(seconds: 2));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unstaking not yet implemented')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isUnstaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch wallet service for updates
    context.watch<WalletService>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode 
        ? const Color(0xFF0A0E21) 
        : CyberColorsLight.backgroundLight;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Stake & Rewards'),
              floating: true,
              backgroundColor: backgroundColor.withOpacity(0.9),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Overview cards
                  _buildOverviewCard(),

                  const SizedBox(height: 24),

                  // Staking form
                  _buildStakingForm(),

                  const SizedBox(height: 24),

                  // Rewards section
                  _buildRewardsSection(),

                  const SizedBox(height: 24),

                  // Staking info
                  _buildInfoSection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColors = isDarkMode 
        ? [const Color(0xFF1D1E33), const Color(0xFF2D2E43)]
        : [CyberColorsLight.cardBackground, CyberColorsLight.backgroundMedium];
    final dividerColor = isDarkMode 
        ? Colors.white.withOpacity(0.1) 
        : CyberColorsLight.divider;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: cardColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatColumn(
                'Staked',
                '${_stakedAmount.toStringAsFixed(2)} CYB',
                const Color(0xFF00FF88),
              ),
              Container(
                width: 1,
                height: 50,
                color: dividerColor,
              ),
              _buildStatColumn(
                'Available',
                '${_availableBalance.toStringAsFixed(2)} CYB',
                const Color(0xFF00D9FF),
              ),
              Container(
                width: 1,
                height: 50,
                color: dividerColor,
              ),
              _buildStatColumn(
                'Rewards',
                '${_pendingRewards.toStringAsFixed(4)} CYB',
                const Color(0xFFFFD93D),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDarkMode 
        ? Colors.white.withOpacity(0.6) 
        : CyberColorsLight.textSecondary;
    
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: secondaryTextColor, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStakingForm() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode 
        ? const Color(0xFF1D1E33) 
        : CyberColorsLight.cardBackground;
    final textColor = isDarkMode ? Colors.white : CyberColorsLight.textPrimary;
    final secondaryTextColor = isDarkMode 
        ? Colors.white.withOpacity(0.7) 
        : CyberColorsLight.textSecondary;
    final inputBgColor = isDarkMode 
        ? const Color(0xFF0A0E21) 
        : CyberColorsLight.inputBackground;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00D9FF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock,
                  color: Color(0xFF00FF88),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Stake Tokens',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: textColor, fontSize: 18),
            decoration: InputDecoration(
              labelText: 'Amount to Stake',
              labelStyle: TextStyle(color: secondaryTextColor),
              suffixText: 'CYB',
              suffixStyle: const TextStyle(color: Color(0xFF00D9FF)),
              filled: true,
              fillColor: inputBgColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF00FF88)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isStaking ? null : _stake,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF88),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isStaking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Stake',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isUnstaking || _stakedAmount <= 0
                      ? null
                      : _unstake,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF6B6B),
                    side: const BorderSide(color: Color(0xFFFF6B6B)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUnstaking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFF6B6B),
                          ),
                        )
                      : const Text(
                          'Unstake',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode 
        ? const Color(0xFF1D1E33) 
        : CyberColorsLight.cardBackground;
    final textColor = isDarkMode ? Colors.white : CyberColorsLight.textPrimary;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD93D).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD93D).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: Color(0xFFFFD93D),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Pending Rewards',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_pendingRewards.toStringAsFixed(6)} CYB',
                style: const TextStyle(
                  color: Color(0xFFFFD93D),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _pendingRewards > 0
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Claim rewards not yet implemented'),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD93D),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.redeem),
              label: const Text(
                'Claim Rewards',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode 
        ? Colors.white.withOpacity(0.05) 
        : CyberColorsLight.backgroundMedium;
    final textColor = isDarkMode ? Colors.white : CyberColorsLight.textPrimary;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ℹ️ Staking Info',
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Minimum Stake', '100 CYB'),
          _buildInfoRow('Unbonding Period', '7 days'),
          _buildInfoRow('Current APY', '~12%'),
          _buildInfoRow('Reward Distribution', 'Every epoch'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : CyberColorsLight.textPrimary;
    final secondaryTextColor = isDarkMode 
        ? Colors.white.withOpacity(0.6) 
        : CyberColorsLight.textSecondary;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(color: textColor, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
