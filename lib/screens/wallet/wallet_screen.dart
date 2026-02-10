import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../config/theme.dart';
import '../../models/wallet.dart';
import '../../services/api_service.dart';
import '../../services/realtime_service.dart';
import 'topup_screen.dart';
import 'withdraw_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _apiService = ApiService();
  final _realtimeService = RealtimeService();
  Timer? _refreshTimer;
  StreamSubscription? _walletUpdateSubscription;
  Wallet? _wallet;
  List<WalletTransaction> _transactions = [];
  double _commissionRate = 3.0;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWalletData();
    
    // Auto-refresh every 10 seconds to check for pending payments
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && _transactions.any((tx) => tx.status == 'pending')) {
        _loadWalletData(showLoading: false);
      }
    });
    
    // Listen for realtime wallet updates
    _walletUpdateSubscription = _realtimeService.walletUpdated.listen((data) {
      print('WalletScreen: Received wallet update via WebSocket');
      _loadWalletData(showLoading: false);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    _walletUpdateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadWalletData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() => _isRefreshing = true);
    }

    try {
      // Fetch transactions first to trigger any status updates via polling in the backend
      final transactionsData = await _apiService.getWalletTransactions();
      final walletData = await _apiService.getWallet();

      if (!mounted) return;
      setState(() {
        if (walletData != null && walletData['wallet'] != null) {
          _wallet = Wallet.fromJson(walletData['wallet']);
          _commissionRate = (walletData['commission_rate'] as num?)?.toDouble() ?? 3.0;
        }
        _transactions = transactionsData;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadWalletData,
                  color: AppTheme.primary,
                  child: NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) => [
                      SliverAppBar(
                        title: Row(
                          children: [
                            Text(
                              'Wallet',
                              style: GoogleFonts.oswald(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.navy,
                              ),
                            ),
                            if (_isRefreshing) ...[
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                                ),
                              ),
                            ],
                          ],
                        ),
                        actions: [
                          IconButton(
                            icon: const Icon(LucideIcons.refreshCw, size: 20),
                            color: AppTheme.navy,
                            onPressed: _isRefreshing ? null : () => _loadWalletData(showLoading: false),
                            tooltip: 'Refresh',
                          ),
                        ],
                        backgroundColor: Colors.white,
                        elevation: 0,
                        centerTitle: false,
                        floating: true,
                        pinned: true,
                        expandedHeight: 260,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Container(
                            padding: const EdgeInsets.only(top: 105),
                            child: _buildBalanceCard(),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildCommissionInfo(),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverAppBarDelegate(
                          minHeight: 64,
                          maxHeight: 64,
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.neutral100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                indicator: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                labelColor: Colors.white,
                                unselectedLabelColor: AppTheme.neutral600,
                                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                indicatorSize: TabBarIndicatorSize.tab,
                                dividerColor: Colors.transparent,
                                tabs: const [
                                  Tab(text: 'Transactions'),
                                  Tab(text: 'Earnings'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    body: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTransactionsTab(),
                        _buildEarningsTab(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle, size: 64, color: AppTheme.neutral400),
            const SizedBox(height: 16),
            Text(
              'Failed to load wallet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadWalletData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.navy,
            AppTheme.navy.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Balance',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${_wallet?.balance.toStringAsFixed(2) ?? '0.00'}',
                    style: GoogleFonts.oswald(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.wallet,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: LucideIcons.arrowUpRight,
                  label: 'Withdraw',
                  onTap: () async {
                    final balance = _wallet?.balance ?? 0.0;
                    if (balance < 5) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Minimum withdrawal is \$5.00'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (context) => WithdrawScreen(availableBalance: balance),
                      ),
                    );
                    if (result == true) {
                      _loadWalletData();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  icon: LucideIcons.plus,
                  label: 'Add Funds',
                  onTap: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (context) => const TopUpScreen(),
                      ),
                    );
                    if (result == true) {
                      _loadWalletData();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.info, color: Colors.amber.shade700, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Commission Rate: ${_commissionRate.toStringAsFixed(1)}% (charged when offer is accepted)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    if (_transactions.isEmpty) {
      return SingleChildScrollView(
        child: _buildEmptyState(
          icon: LucideIcons.receipt,
          title: 'No transactions yet',
          subtitle: 'Your transaction history will appear here once you top up your wallet or complete tasks.',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) => _buildTransactionItem(_transactions[index]),
    );
  }

  Widget _buildTransactionItem(WalletTransaction tx) {
    final isPositive = tx.amount > 0;
    final formatter = DateFormat('MMM d, yyyy • h:mm a');

    IconData icon;
    Color iconColor;
    switch (tx.type) {
      case 'topup':
        icon = LucideIcons.arrowDownLeft;
        iconColor = Colors.green;
        break;
      case 'commission_debit':
        icon = LucideIcons.percent;
        iconColor = Colors.purple;
        break;
      case 'withdrawal':
        icon = LucideIcons.arrowUpRight;
        iconColor = Colors.blue;
        break;
      default:
        icon = isPositive ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight;
        iconColor = isPositive ? Colors.green : Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.displayType,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.navy,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tx.reference ?? formatter.format(tx.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : ''}\$${tx.amount.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green : Colors.red,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              _buildStatusBadge(tx.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'completed':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'failed':
        color = Colors.red;
        break;
      default:
        color = AppTheme.neutral400;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEarningsTab() {
    // Filter for earnings (completed task payments)
    final earnings = _transactions.where((tx) => tx.type == 'credit' && tx.isCompleted).toList();
    final thisMonthEarnings = earnings
        .where((tx) => tx.createdAt.month == DateTime.now().month && tx.createdAt.year == DateTime.now().year)
        .fold<double>(0, (sum, tx) => sum + tx.amount);
    final totalEarnings = earnings.fold<double>(0, (sum, tx) => sum + tx.amount);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Earnings Summary Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildEarningsSummaryCard(
                    title: 'This Month',
                    amount: '\$${thisMonthEarnings.toStringAsFixed(2)}',
                    icon: LucideIcons.calendar,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEarningsSummaryCard(
                    title: 'Total Earned',
                    amount: '\$${totalEarnings.toStringAsFixed(2)}',
                    icon: LucideIcons.trendingUp,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Earnings List
          if (earnings.isEmpty)
            _buildEmptyState(
              icon: LucideIcons.banknote,
              title: 'No earnings yet',
              subtitle: 'Complete tasks to start earning money.',
            )
          else
            ...earnings.map((tx) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTransactionItem(tx),
            )),
        ],
      ),
    );
  }

  Widget _buildEarningsSummaryCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: GoogleFonts.oswald(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.neutral100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: AppTheme.neutral400),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.neutral500,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Coming soon!'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
