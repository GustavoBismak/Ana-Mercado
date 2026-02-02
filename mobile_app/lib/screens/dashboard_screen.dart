import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  final int userId;

  const DashboardScreen({super.key, required this.userId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService apiService = ApiService();
  late Future<Map<String, dynamic>> _statsFuture;
  String? _selectedMonth;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }
  
  void _loadStats({String? month}) {
    setState(() {
      _statsFuture = apiService.getDashboardStats(widget.userId, month: month);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Sem dados disponíveis'));
          }

          final categoryData = snapshot.data!['category_spend'] as List;
          final monthlyData = snapshot.data!['monthly_spend'] as List;
          
          // Helper to get available months from history for the dropdown
          // We can assume monthlyData contains all history
          // Generate last 12 months for the dropdown
          final List<String> dropdownMonths = [];
          DateTime now = DateTime.now();
          for (int i = 0; i < 12; i++) {
            DateTime date = DateTime(now.year, now.month - i, 1);
            dropdownMonths.add(DateFormat('yyyy-MM').format(date));
          }
          
          // Also include any months that have data but are older than 12 months
          final List<String> dataMonths = monthlyData
              .map((e) => e['month'] as String)
              .toList();
          
          final Set<String> allVisibleMonths = {...dropdownMonths, ...dataMonths};
          final List<String> sortedMonths = allVisibleMonths.toList()
            ..sort((a, b) => b.compareTo(a)); // desc sort

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Month Filter
                GestureDetector(
                  onTap: () async {
                    final List<String> availableMonths = [];
                    DateTime now = DateTime.now();
                    // Show last 24 months for exhaustive list
                    for (int i = 0; i < 24; i++) {
                      DateTime date = DateTime(now.year, now.month - i, 1);
                      availableMonths.add(DateFormat('yyyy-MM').format(date));
                    }
                    
                    final result = await showDialog<String?>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Selecionar Mês"),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              ListTile(
                                title: const Text("Geral (Até Agora)", style: TextStyle(fontWeight: FontWeight.bold)),
                                selected: _selectedMonth == null,
                                onTap: () => Navigator.pop(context, "GERAL"),
                              ),
                              const Divider(),
                              ...availableMonths.map((m) {
                                DateTime date = DateTime.parse('$m-01');
                                String label = DateFormat('MMMM yyyy', 'pt_BR').format(date);
                                label = label[0].toUpperCase() + label.substring(1);
                                return ListTile(
                                  title: Text(label),
                                  selected: _selectedMonth == m,
                                  onTap: () => Navigator.pop(context, m),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    );
                    
                    if (result != null) {
                       final selectedVal = result == "GERAL" ? null : result;
                       setState(() {
                         _selectedMonth = selectedVal;
                       });
                       _loadStats(month: selectedVal);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, color: Colors.blue),
                            const SizedBox(width: 12),
                            Text(
                              _selectedMonth == null 
                                ? "Geral (Até Agora)" 
                                : (() {
                                    DateTime date = DateTime.parse('$_selectedMonth-01');
                                    String label = DateFormat('MMMM yyyy', 'pt_BR').format(date);
                                    return label[0].toUpperCase() + label.substring(1);
                                  })(),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Gastos por Categoria',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 250,
                          child: categoryData.isEmpty
                              ? const Center(child: Text('Nenhum dado de categoria.'))
                              : PieChart(
                                  PieChartData(
                                    pieTouchData: PieTouchData(
                                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                        setState(() {
                                          if (!event.isInterestedForInteractions ||
                                              pieTouchResponse == null ||
                                              pieTouchResponse.touchedSection == null) {
                                            _touchedIndex = -1;
                                            return;
                                          }
                                          _touchedIndex = pieTouchResponse
                                              .touchedSection!.touchedSectionIndex;
                                        });
                                      },
                                    ),
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 40,
                                    sections: _generatePieSections(categoryData),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        // Dynamic Legend
                        Wrap(
                          spacing: 12.0,
                          runSpacing: 8.0,
                          alignment: WrapAlignment.center,
                          children: categoryData.map((item) {
                             final String category = item['category'];
                             final String colorStr = (item['color'] as String?) ?? '#9E9E9E';
                             final Color color = _parseColor(colorStr);
                             return Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                 const SizedBox(width: 4),
                                 Text(category, style: const TextStyle(fontSize: 12)),
                               ],
                             );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Histórico Mensal',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 300,
                          child: monthlyData.isEmpty
                              ? const Center(child: Text('Nenhum histórico mensal.'))
                              : BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: _getMaxY(monthlyData),
                                    barTouchData: BarTouchData(
                                      enabled: true,
                                      touchTooltipData: BarTouchTooltipData(
                                        tooltipBgColor: Colors.blueGrey,
                                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                          String month = monthlyData[groupIndex]['month'];
                                          return BarTooltipItem(
                                            '$month\n',
                                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                            children: <TextSpan>[
                                              TextSpan(
                                                text: 'R\$ ${(rod.toY).toStringAsFixed(2)}',
                                                style: const TextStyle(color: Colors.yellow, fontSize: 12),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      show: true,
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (double value, TitleMeta meta) {
                                            if (value.toInt() >= 0 && value.toInt() < monthlyData.length) {
                                              String fullDate = monthlyData[value.toInt()]['month'];
                                              String shortDate = fullDate.substring(5);
                                              return SideTitleWidget(
                                                axisSide: meta.axisSide,
                                                child: Text(shortDate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                              );
                                            }
                                            return const Text('');
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          getTitlesWidget: (double value, TitleMeta meta) {
                                            if (value == 0) return const Text('');
                                            return Text('${value.toInt()}', style: const TextStyle(fontSize: 10));
                                          },
                                        ),
                                      ),
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    ),
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: _getMaxY(monthlyData) / 5,
                                      getDrawingHorizontalLine: (value) {
                                        return const FlLine(
                                          color: Colors.black12,
                                          strokeWidth: 1,
                                        );
                                      },
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: const Border(
                                        bottom: BorderSide(color: Colors.black12),
                                        left: BorderSide(color: Colors.black12),
                                      ),
                                    ),
                                    barGroups: _generateBarGroups(monthlyData),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<PieChartSectionData> _generatePieSections(List data) {
    return List.generate(data.length, (i) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 18.0 : 14.0;
      final radius = isTouched ? 70.0 : 60.0;
      
      final item = data[i];
      final String category = item['category'];
      final double value = (item['total'] as num).toDouble();
      final String colorStr = (item['color'] as String?) ?? '#9E9E9E';
      final Color color = _parseColor(colorStr);

      return PieChartSectionData(
        color: color,
        value: value,
        title: isTouched ? '${category}\nR\$${value.toStringAsFixed(0)}' : 'R\$${value.toStringAsFixed(0)}',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [const Shadow(color: Colors.black, blurRadius: 2)],
        ),
      );
    });
  }

  List<BarChartGroupData> _generateBarGroups(List data) {
    return List.generate(data.length, (i) {
      final item = data[i];
      final double value = (item['total'] as num).toDouble();
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: value,
            color: Colors.blue,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  double _getMaxY(List data) {
    double max = 0;
    for (var item in data) {
      double val = (item['total'] as num).toDouble();
      if (val > max) max = val;
    }
    return max * 1.2;
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}
