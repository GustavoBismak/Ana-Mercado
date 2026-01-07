import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
          final List<String> availableMonths = monthlyData
              .map((e) => e['month'] as String)
              .toSet() // dedupe
              .toList()
            ..sort((a, b) => b.compareTo(a)); // desc sort

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Month Filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedMonth,
                      isExpanded: true,
                      hint: const Text("Filtrar por Período"),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text("Geral (Até Agora)", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        ...availableMonths.map((month) {
                          // Format YYYY-MM to readable? leaving as is for now or simple format
                          return DropdownMenuItem<String?>(
                            value: month,
                            child: Text(month),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedMonth = val;
                        });
                        _loadStats(month: val);
                      },
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
        title: '${category}\nR\$${value.toStringAsFixed(0)}',
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
