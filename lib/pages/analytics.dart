import 'package:budgget_buddy/models/transaction.dart';
import 'package:budgget_buddy/provider/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  String _selectedPeriod = 'This Month';
  final List<String> _periodOptions = ['This Week', 'This Month', 'Last 30 Days', 'This Year'];

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            _buildPeriodSelector(),

            const SizedBox(height: 24),

            // Overview Cards
            _buildOverviewCards(transactions),

            const SizedBox(height: 24),

            // Income vs Expense Chart
            _buildIncomeExpenseChart(transactions),

            const SizedBox(height: 24),

            // Monthly Trend Chart
            _buildMonthlyTrendChart(transactions),

            const SizedBox(height: 24),

            // Category Breakdown
            _buildCategoryBreakdown(transactions),

            const SizedBox(height: 24),

            // Daily Spending Pattern
            _buildDailySpendingChart(transactions),

            const SizedBox(height: 24),

            // Top Spending Categories
            _buildTopCategories(transactions),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 20),
          const SizedBox(width: 12),
          const Text('Period: ', style: TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedPeriod,
              isExpanded: true,
              underline: Container(),
              items: _periodOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPeriod = newValue!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(List<Transaction> transactions) {
    final filteredTransactions = _filterTransactionsByPeriod(transactions);
    final totalIncome = _calculateTotalIncome(filteredTransactions);
    final totalExpense = _calculateTotalExpense(filteredTransactions);
    final netAmount = totalIncome - totalExpense;

    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            'Income',
            '₹${totalIncome.toStringAsFixed(2)}',
            Icons.arrow_upward,
            Colors.green,
            totalIncome > 0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'Expense',
            '₹${totalExpense.toStringAsFixed(2)}',
            Icons.arrow_downward,
            Colors.red,
            totalExpense > 0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            'Balance',
            '₹${netAmount.toStringAsFixed(2)}',
            netAmount >= 0 ? Icons.account_balance : Icons.warning,
            netAmount >= 0 ? Colors.blue : Colors.orange,
            true,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String amount, IconData icon, Color color, bool showPositive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseChart(List<Transaction> transactions) {
    final filteredTransactions = _filterTransactionsByPeriod(transactions);
    final monthlyData = _getMonthlyIncomeExpenseData(filteredTransactions);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                'Income vs Expense Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (monthlyData.isEmpty) return const Text('');
                        final index = value.toInt();
                        if (index >= 0 && index < monthlyData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              monthlyData[index]['month'] ?? '',
                              style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodyMedium?.color),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: monthlyData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value['income'] as double);
                    }).toList(),
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    belowBarData: BarAreaData(show: false),
                    dotData: FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: monthlyData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value['expense'] as double);
                    }).toList(),
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    belowBarData: BarAreaData(show: false),
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendItem(Colors.green, 'Income'),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.red, 'Expense'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendChart(List<Transaction> transactions) {
    final filteredTransactions = _filterTransactionsByPeriod(transactions);
    final monthlyTotals = _getMonthlyTotals(filteredTransactions);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                'Monthly Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (monthlyTotals.isEmpty) return const Text('');
                        final index = value.toInt();
                        if (index >= 0 && index < monthlyTotals.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              monthlyTotals[index]['month'] ?? '',
                              style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodyMedium?.color),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: monthlyTotals.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value['total'] as double,
                        color: entry.value['total'] >= 0 ? Colors.green : Colors.red,
                        width: 20,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(List<Transaction> transactions) {
    final filteredTransactions = _filterTransactionsByPeriod(transactions);
    final categoryData = _getCategoryBreakdown(filteredTransactions);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                'Spending by Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: categoryData.entries.map((entry) {
                  final color = _getCategoryColor(entry.key);
                  return PieChartSectionData(
                    value: entry.value.abs(),
                    title: '${entry.value.abs().toStringAsFixed(0)}₹',
                    color: color,
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: categoryData.entries.take(5).map((entry) {
              return _buildLegendItem(_getCategoryColor(entry.key), entry.key);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySpendingChart(List<Transaction> transactions) {
    final filteredTransactions = _filterTransactionsByPeriod(transactions);
    final dailyData = _getDailySpendingData(filteredTransactions);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_view_day, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                'Daily Spending Pattern',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, horizontalInterval: 1),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (dailyData.isEmpty) return const Text('');
                        final index = value.toInt();
                        if (index >= 0 && index < dailyData.length) {
                          final day = dailyData[index]['day'] as int?;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              day?.toString() ?? '',
                              style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodyMedium?.color),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: dailyData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value['amount'] as double);
                    }).toList(),
                    isCurved: true,
                    color: Theme.of(context).primaryColor,
                    barWidth: 2,
                    belowBarData: BarAreaData(show: false),
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategories(List<Transaction> transactions) {
    final filteredTransactions = _filterTransactionsByPeriod(transactions);
    final topCategories = _getTopCategories(filteredTransactions);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                'Top Spending Categories',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topCategories.entries.take(5).map((entry) {
            final percentage = (entry.value.abs() / filteredTransactions
                .where((t) => t.amount < 0)
                .fold(0.0, (sum, t) => sum + t.amount.abs())) * 100;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${entry.value.abs().toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
      ],
    );
  }

  // Helper methods for data processing
  List<Transaction> _filterTransactionsByPeriod(List<Transaction> transactions) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case 'This Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Last 30 Days':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    return transactions.where((t) => t.date.isAfter(startDate) || t.date.isAtSameMomentAs(startDate)).toList();
  }

  double _calculateTotalIncome(List<Transaction> transactions) {
    return transactions.where((t) => t.amount > 0).fold(0.0, (sum, t) => sum + t.amount);
  }

  double _calculateTotalExpense(List<Transaction> transactions) {
    return transactions.where((t) => t.amount < 0).fold(0.0, (sum, t) => sum + t.amount.abs());
  }

  List<Map<String, dynamic>> _getMonthlyIncomeExpenseData(List<Transaction> transactions) {
    final monthlyData = <String, Map<String, double>>{};

    for (var transaction in transactions) {
      final monthKey = DateFormat('MMM yyyy').format(transaction.date);

      monthlyData.putIfAbsent(monthKey, () => {'income': 0.0, 'expense': 0.0});

      if (transaction.amount > 0) {
        monthlyData[monthKey]!['income'] = monthlyData[monthKey]!['income']! + transaction.amount;
      } else {
        monthlyData[monthKey]!['expense'] = monthlyData[monthKey]!['expense']! + transaction.amount.abs();
      }
    }

    return monthlyData.entries.map((entry) => {
      'month': entry.key,
      'income': entry.value['income']!,
      'expense': entry.value['expense']!,
    }).toList();
  }

  List<Map<String, dynamic>> _getMonthlyTotals(List<Transaction> transactions) {
    final monthlyTotals = <String, double>{};

    for (var transaction in transactions) {
      final monthKey = DateFormat('MMM').format(transaction.date);
      monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + transaction.amount;
    }

    return monthlyTotals.entries.map((entry) => {
      'month': entry.key,
      'total': entry.value,
    }).toList();
  }

  Map<String, double> _getCategoryBreakdown(List<Transaction> transactions) {
    final categoryTotals = <String, double>{};

    for (var transaction in transactions) {
      if (transaction.amount < 0) {
        final category = transaction.title.split(' ').first; // Simple category extraction
        categoryTotals[category] = (categoryTotals[category] ?? 0) + transaction.amount.abs();
      }
    }

    return categoryTotals;
  }

  List<Map<String, dynamic>> _getDailySpendingData(List<Transaction> transactions) {
    final dailyTotals = <int, double>{};

    for (var transaction in transactions.where((t) => t.amount < 0)) {
      final day = transaction.date.day;
      dailyTotals[day] = (dailyTotals[day] ?? 0) + transaction.amount.abs();
    }

    return dailyTotals.entries.map((entry) => {
      'day': entry.key,
      'amount': entry.value,
    }).toList()..sort((a, b) => (a['day'] as int).compareTo(b['day'] as int));
  }

  Map<String, double> _getTopCategories(List<Transaction> transactions) {
    final categoryTotals = <String, double>{};

    for (var transaction in transactions.where((t) => t.amount < 0)) {
      final category = transaction.title.split(' ').first;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + transaction.amount.abs();
    }

    final sortedCategories = Map<String, double>.fromEntries(
      categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value))
    );

    return sortedCategories;
  }

  Color _getCategoryColor(String category) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];

    final hash = category.hashCode;
    return colors[hash.abs() % colors.length];
  }
}
