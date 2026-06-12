import 'package:flutter/material.dart';
import 'package:yt_downloader/core/theme/theme.dart';
import 'package:yt_downloader/services/api_client.dart';
import 'package:yt_downloader/services/hive_db.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isLoading = true;
  List<dynamic> _plans = [];
  String _selectedPlanId = 'monthly_sub';
  bool _isPremiumActive = false;

  @override
  void initState() {
    super.initState();
    _isPremiumActive = HiveDb.isPremium;
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    final result = await ApiClient.fetchSubscriptionPlans();
    if (mounted) {
      setState(() {
        _plans = result['plans'] as List<dynamic>? ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _processPurchase() async {
    setState(() => _isLoading = true);
    final result = await ApiClient.purchasePlan(_selectedPlanId);
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      await HiveDb.setPremiumStatus(true);
      setState(() {
        _isPremiumActive = true;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.stars, color: MskColors.secondary),
                SizedBox(width: 8),
                Text('Purchase Successful!'),
              ],
            ),
            content: const Text('Thank you! You are now subscribed to MSK Premium Pro. Enjoy your ad-free experience and 4K downloads!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Awesome'),
              )
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment failed. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Upgrade'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: MskColors.secondary))
          : _isPremiumActive
              ? _buildActivePremiumState()
              : _buildUpgradeOfferState(),
    );
  }

  Widget _buildActivePremiumState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.stars_rounded, size: 90, color: MskColors.secondary),
          const SizedBox(height: 24),
          const Text(
            'You are Pro!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: MskColors.textDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Your MSK Software Solutions Premium Subscription is active. Enjoy unlimited access to high-speed conversions, 4K resolutions, and ad-free toolkit operations.',
            style: TextStyle(fontSize: 14, color: MskColors.textLight, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('Back to Tools'),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeOfferState() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Choose Your Plan',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: MskColors.textDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Unlock the ultimate creation toolkit features',
                style: TextStyle(fontSize: 14, color: MskColors.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Plans cards selector
              ..._plans.map((p) {
                final id = p['id'] as String;
                final name = p['name'] as String;
                final price = p['price'] as String;
                final duration = p['duration'] as String;
                final features = p['features'] as List<dynamic>? ?? [];
                final isSelected = _selectedPlanId == id;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPlanId = id;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? MskColors.secondary : Colors.grey.shade200,
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: MskColors.secondary.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? MskColors.secondary : MskColors.textDark,
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, color: MskColors.secondary),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              price,
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: MskColors.textDark),
                            ),
                            Text(
                              ' / $duration',
                              style: const TextStyle(fontSize: 13, color: MskColors.textLight),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        // Features list
                        ...features.map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.check, size: 14, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      f as String,
                                      style: const TextStyle(fontSize: 12, color: MskColors.textLight),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        // Bottom checkout button & Ad banner placeholder
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _processPurchase,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Subscribe & Unlock'),
              ),
              const SizedBox(height: 16),
              // AdMob placeholder
              Container(
                height: 50,
                color: Colors.grey.shade100,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      color: Colors.grey.shade400,
                      child: const Text('AD', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    const Text('Banner ad placeholder from Google Mobile Ads', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
