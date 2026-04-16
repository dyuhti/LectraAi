import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_lecture_notes/theme/app_theme.dart';

class StudyDashboardScreen extends StatefulWidget {
  const StudyDashboardScreen({Key? key}) : super(key: key);

  @override
  State<StudyDashboardScreen> createState() => _StudyDashboardScreenState();
}

class _StudyDashboardScreenState extends State<StudyDashboardScreen>
    with TickerProviderStateMixin {
  int touchedIndex = -1;
  int? lineChartTouchedIndex;
  late AnimationController _touchAnimationController;
  late Animation<double> _touchAnimation;

  @override
  void initState() {
    super.initState();
    _touchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _touchAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _touchAnimationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _touchAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Study Dashboard',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stat Cards Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppDecorations.card(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: AppDecorations.iconContainer(radius: 10),
                                child: const Icon(
                                  Icons.note_outlined,
                                  color: AppColors.primaryLight,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Total Notes',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '41',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppDecorations.card(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: AppDecorations.iconContainer(radius: 10),
                                child: const Icon(
                                  Icons.access_time,
                                  color: AppColors.primaryLight,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Study Hours',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '28',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Notes by Subject
              const Text(
                'Notes by Subject',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                      spreadRadius: 1,
                    ),
                  ],
                  border: Border(
                    top: BorderSide(
                      color: AppColors.primaryLight.withOpacity(0.4),
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 280,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          groupsSpace: 12,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              tooltipBgColor: const Color(0xFF0A2A8A),
                              tooltipMargin: 12,
                              tooltipHorizontalAlignment:
                                  FLHorizontalAlignment.center,
                              tooltipHorizontalOffset: 0,
                              tooltipRoundedRadius: 12,
                              tooltipPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              getTooltipItem: (
                                group,
                                groupIndex,
                                rod,
                                rodIndex,
                              ) {
                                const subjects = [
                                  'Physics',
                                  'Math',
                                  'CS',
                                  'Biology'
                                ];
                                return BarTooltipItem(
                                  '${subjects[groupIndex]}\n${rod.toY.toInt()} notes',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 0.3,
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: 4,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const subjects = [
                                    'Physics',
                                    'Math',
                                    'CS',
                                    'Biology'
                                  ];
                                  return Text(
                                    subjects[value.toInt()],
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          barGroups: [
                            BarChartGroupData(
                              x: 0,
                              barRods: [
                                BarChartRodData(
                                  toY: 12,
                                  color: AppColors.primary,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                  ),
                                  width: 20,
                                  rodStackItems: [
                                    BarChartRodStackItem(0, 12, Colors.transparent),
                                  ],
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 1,
                              barRods: [
                                BarChartRodData(
                                  toY: 8,
                                  color: AppColors.primaryLight,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                  ),
                                  width: 20,
                                  rodStackItems: [
                                    BarChartRodStackItem(0, 8, Colors.transparent),
                                  ],
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 2,
                              barRods: [
                                BarChartRodData(
                                  toY: 15,
                                  color: const Color(0xFF4F6BFF),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                  ),
                                  width: 20,
                                  rodStackItems: [
                                    BarChartRodStackItem(0, 15, Colors.transparent),
                                  ],
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 3,
                              barRods: [
                                BarChartRodData(
                                  toY: 6,
                                  color: AppColors.primaryLight.withOpacity(0.7),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                  ),
                                  width: 20,
                                  rodStackItems: [
                                    BarChartRodStackItem(0, 6, Colors.transparent),
                                  ],
                                ),
                              ],
                            ),
                          ],
                          maxY: 20,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 4,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: AppColors.border.withOpacity(0.5),
                                strokeWidth: 1.2,
                              );
                            },
                          ),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildBarLabel('Physics', 12, AppColors.primary),
                          _buildBarLabel('Math', 8, AppColors.primaryLight),
                          _buildBarLabel('CS', 15, const Color(0xFF4F6BFF)),
                          _buildBarLabel('Biology', 6,
                              AppColors.primaryLight.withOpacity(0.7)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Weekly Activity
              const Text(
                'Weekly Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                      spreadRadius: 1,
                    ),
                  ],
                  border: Border(
                    top: BorderSide(
                      color: AppColors.primaryLight.withOpacity(0.4),
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 220,
                      child: LineChart(
                        LineChartData(
                          titlesData: FlTitlesData(
                            show: true,
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: 2,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const days = [
                                    'Mon',
                                    'Tue',
                                    'Wed',
                                    'Thu',
                                    'Fri',
                                    'Sat',
                                    'Sun'
                                  ];
                                  return Text(
                                    days[value.toInt() % 7],
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          lineTouchData: LineTouchData(
                            enabled: true,
                            touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                              if (event is FlTapUpEvent) {
                                setState(() {
                                  lineChartTouchedIndex =
                                      response?.lineBarSpots?.firstOrNull?.spotIndex ?? -1;
                                });
                                if (lineChartTouchedIndex != -1) {
                                  _touchAnimationController.forward().then((_) {
                                    _touchAnimationController.reverse();
                                  });
                                }
                              }
                            },
                            touchTooltipData: LineTouchTooltipData(
                              tooltipBgColor: const Color(0xFF0A2A8A),
                              tooltipMargin: 16,
                              tooltipHorizontalAlignment:
                                  FLHorizontalAlignment.center,
                              tooltipHorizontalOffset: 0,
                              tooltipRoundedRadius: 12,
                              tooltipPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              fitInsideHorizontally: true,
                              fitInsideVertically: true,
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((touchedSpot) {
                                  const days = [
                                    'Monday',
                                    'Tuesday',
                                    'Wednesday',
                                    'Thursday',
                                    'Friday',
                                    'Saturday',
                                    'Sunday'
                                  ];
                                  return LineTooltipItem(
                                    '${days[touchedSpot.x.toInt()]}\n${touchedSpot.y.toStringAsFixed(1)} hrs',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      letterSpacing: 0.3,
                                    ),
                                    textAlign: TextAlign.center,
                                  );
                                }).toList();
                              },
                            ),
                            handleBuiltInTouches: true,
                            getTouchLineStart: (data, index) => 0,
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 2,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: AppColors.border.withOpacity(0.5),
                                strokeWidth: 1.2,
                              );
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          minY: 0,
                          maxY: 8,
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                const FlSpot(0, 2),
                                const FlSpot(1, 3),
                                const FlSpot(2, 2.5),
                                const FlSpot(3, 4),
                                const FlSpot(4, 3.5),
                                const FlSpot(5, 5),
                                const FlSpot(6, 1.5),
                              ],
                              isCurved: true,
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primaryLight,
                                  AppColors.primary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  final isSelected = lineChartTouchedIndex == index;
                                  return FlDotCirclePainter(
                                    radius: isSelected ? 7 : 5,
                                    color: AppColors.primary,
                                    strokeWidth: isSelected ? 3 : 0,
                                    strokeColor: isSelected
                                        ? AppColors.primaryLight.withOpacity(0.6)
                                        : Colors.transparent,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryLight.withOpacity(0.2),
                                    AppColors.primaryLight.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Subject Distribution
              const Text(
                'Subject Distribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                      spreadRadius: 1,
                    ),
                  ],
                  border: Border(
                    top: BorderSide(
                      color: AppColors.primaryLight.withOpacity(0.4),
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: 30,
                              title: 'Physics\n30%',
                              radius: 85,
                              titleStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.3,
                                shadows: [
                                  Shadow(
                                    blurRadius: 3,
                                    color: Color.fromARGB(80, 0, 0, 0),
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                              color: AppColors.primary,
                              badgeWidget: const SizedBox.shrink(),
                            ),
                            PieChartSectionData(
                              value: 35,
                              title: 'CS\n35%',
                              radius: 85,
                              titleStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.3,
                                shadows: [
                                  Shadow(
                                    blurRadius: 3,
                                    color: Color.fromARGB(80, 0, 0, 0),
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                              color: AppColors.primaryLight,
                              badgeWidget: const SizedBox.shrink(),
                            ),
                            PieChartSectionData(
                              value: 20,
                              title: 'Math\n20%',
                              radius: 85,
                              titleStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.3,
                                shadows: [
                                  Shadow(
                                    blurRadius: 3,
                                    color: Color.fromARGB(80, 0, 0, 0),
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                              color: const Color(0xFF1E3A8A),
                              badgeWidget: const SizedBox.shrink(),
                            ),
                            PieChartSectionData(
                              value: 15,
                              title: 'Bio\n15%',
                              radius: 85,
                              titleStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.3,
                                shadows: [
                                  Shadow(
                                    blurRadius: 3,
                                    color: Color.fromARGB(80, 0, 0, 0),
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                              color: const Color(0xFF4F6BFF),
                              badgeWidget: const SizedBox.shrink(),
                            ),
                          ],
                          sectionsSpace: 6,
                          centerSpaceRadius: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegendItem(
                              color: AppColors.primary,
                              label: 'Physics',
                              percentage: '30%',
                            ),
                            const SizedBox(width: 36),
                            _buildLegendItem(
                              color: AppColors.primaryLight,
                              label: 'CS',
                              percentage: '35%',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegendItem(
                              color: const Color(0xFF1E3A8A),
                              label: 'Math',
                              percentage: '20%',
                            ),
                            const SizedBox(width: 36),
                            _buildLegendItem(
                              color: const Color(0xFF4F6BFF),
                              label: 'Biology',
                              percentage: '15%',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarLabel(String label, int value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '$value',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: color.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    String? percentage,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.2,
              ),
            ),
            if (percentage != null)
              Text(
                percentage,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary.withOpacity(0.6),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
