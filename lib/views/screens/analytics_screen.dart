import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../models/tag.dart';
import '../../viewmodels/tag_viewmodel.dart';
import '../../widgets/tag_selector.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Default to last 7 days
    final now = DateTime.now();
    _selectedDateRange = DateRange(
      now.subtract(const Duration(days: 7)),
      now,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Analytics',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: _showDateRangePicker,
                        icon: const Icon(
                          Icons.date_range,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getDateRangeText(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF3478F4),
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Tags'),
                  Tab(text: 'Trends'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildTagsTab(),
                  _buildTrendsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards - Empty state
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Sessions',
                  '0',
                  Icons.play_circle_outline,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Total Time',
                  '0h',
                  Icons.timer,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Avg. Focus',
                  'N/A',
                  Icons.psychology,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Completion',
                  'N/A',
                  Icons.check_circle_outline,
                  Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Empty state message
          _buildEmptyState(
            icon: Icons.analytics_outlined,
            title: 'No Analytics Data Yet',
            subtitle: 'Start completing focus sessions to see your analytics here.',
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTagsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final analyticsAsync = ref.watch(tagAnalyticsProvider(_selectedDateRange));
        
        return analyticsAsync.when(
          data: (analytics) => analytics.isEmpty 
            ? _buildEmptyState(
                icon: Icons.label_outline,
                title: 'No Tag Analytics',
                subtitle: 'Create tags and use them in focus sessions to see analytics here.',
              )
            : _buildTagAnalytics(analytics),
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF3478F4),
            ),
          ),
          error: (error, stackTrace) => _buildEmptyState(
            icon: Icons.error_outline,
            title: 'Error Loading Analytics',
            subtitle: 'Unable to load tag analytics data.',
          ),
        );
      },
    );
  }

  Widget _buildTrendsTab() {
    return _buildEmptyState(
      icon: Icons.trending_up,
      title: 'Trends Coming Soon',
      subtitle: 'Advanced trend analysis will be available in a future update.',
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppColors.textSecondary,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagAnalytics(List<TagAnalytics> analytics) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: analytics.length,
      itemBuilder: (context, index) => _buildTagAnalyticsCard(analytics[index]),
    );
  }

  Widget _buildTagAnalyticsCard(TagAnalytics analytic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color((analytic.tag.color as int?) ?? 0xFF3478F4),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  analytic.tag.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${analytic.totalMinutes}m',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Sessions',
                  '${analytic.totalSessions}',
                  Icons.play_arrow,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Completion',
                  '${(analytic.completionRate * 100).round()}%',
                  Icons.check_circle,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Avg. Energy',
                  analytic.averageEnergy > 0 ? '${analytic.averageEnergy.toStringAsFixed(1)}' : 'N/A',
                  Icons.battery_charging_full,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.textSecondary,
          size: 16,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showDateRangePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Select Date Range',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Last 7 days', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => _selectDateRange(7),
            ),
            ListTile(
              title: Text('Last 30 days', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => _selectDateRange(30),
            ),
            ListTile(
              title: Text('Last 90 days', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => _selectDateRange(90),
            ),
          ],
        ),
      ),
    );
  }

  void _selectDateRange(int days) {
    final now = DateTime.now();
    setState(() {
      _selectedDateRange = DateRange(
        now.subtract(Duration(days: days)),
        now,
      );
    });
    Navigator.of(context).pop();
  }

  String _getDateRangeText() {
    if (_selectedDateRange == null) return 'All time';
    
    final start = _selectedDateRange!.start;
    final end = _selectedDateRange!.end;
    final difference = end.difference(start).inDays;
    
    if (difference == 7) return 'Last 7 days';
    if (difference == 30) return 'Last 30 days';
    if (difference == 90) return 'Last 90 days';
    
    return 'Custom range';
  }
} 