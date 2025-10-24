//pages/quarterly_installment_page.dart
import 'package:flutter/material.dart';
import '../services/tax_computation_service.dart';
import '../services/tax_data_service.dart';
import '../services/income_calculator.dart';

class QuarterlyInstallmentsPage extends StatefulWidget {
  const QuarterlyInstallmentsPage({super.key});

  @override
  State<QuarterlyInstallmentsPage> createState() =>
      _QuarterlyInstallmentsPageState();
}

class _QuarterlyInstallmentsPageState extends State<QuarterlyInstallmentsPage>
    with TickerProviderStateMixin {
  final TaxDataService service = TaxDataService();
  late final TaxComputationService taxService;
  late final IncomeCalculator incomeCalculator;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    taxService = TaxComputationService();
    incomeCalculator = IncomeCalculator();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _cardControllers = List.generate(
      4,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      ),
    );
    _cardAnimations = _cardControllers
        .map(
          (controller) => Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
          ),
        )
        .toList();

    _fadeController.forward();
    _slideController.forward();

    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 200 * i), () {
        if (mounted) _cardControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
    required int animationIndex,
  }) {
    const neutral900 = Color(0xFF111714);
    return FadeTransition(
      opacity: _cardAnimations[animationIndex],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_cardControllers[animationIndex]),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: neutral900,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: children),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget summaryRow(
    String label,
    double value, {
    bool isHighlight = false,
    Color? valueColor,
  }) {
    const neutral900 = Color(0xFF111714);
    const accentGreen = Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isHighlight ? accentGreen.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isHighlight
            ? Border.all(color: accentGreen.withOpacity(0.3))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isHighlight ? 16 : 15,
                fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
                color: neutral900,
                height: 1.3,
              ),
            ),
          ),
          Text(
            "Rs. ${value.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: isHighlight ? 16 : 15,
              fontWeight: FontWeight.bold,
              color: valueColor ?? (isHighlight ? accentGreen : neutral900),
            ),
          ),
        ],
      ),
    );
  }

  // --- UPDATED FUNCTION ---
  double _calculateQuarterlyIncome(String category, int quarter) {
    // Calculate the start index for the quarter
    // Tax Year: April (0) is month 1, March (11) is month 12
    final startIndex = (quarter - 1) * 3;
    if (startIndex < 0 || startIndex >= 12) return 0.0;

    double income = 0.0;

    // THE FIX:
    // Removed the "if (service.selectedTaxYear == "2025/2026")" check.
    // The monthly totals arrays are *always* populated correctly,
    // so we should *always* read from them.
    for (int i = 0; i < 3; i++) {
      final monthIndex = startIndex + i;
      if (monthIndex < 12) {
        // Ensure index is within bounds before accessing
        if (category == 'employment' &&
            service.monthlyEmploymentTotals.length > monthIndex) {
          income += service.monthlyEmploymentTotals[monthIndex];
        } else if (category == 'business' &&
            service.monthlyBusinessTotals.length > monthIndex) {
          income += service.monthlyBusinessTotals[monthIndex];
        } else if (category == 'investment' &&
            service.monthlyInvestmentTotals.length > monthIndex) {
          income += service.monthlyInvestmentTotals[monthIndex];
        } else if (category == 'foreign' &&
            service.monthlyForeignTotals.length > monthIndex) {
          income += service.monthlyForeignTotals[monthIndex];
        } else if (category == 'other' &&
            service.monthlyOtherTotals.length > monthIndex) {
          income += service.monthlyOtherTotals[monthIndex];
        }
      }
    }
    return income;
  }
  // --- END OF UPDATED FUNCTION ---

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF38E07B);
    const primaryLight = Color(0xFF5FE896);
    const neutral50 = Color(0xFFf8faf9);
    const neutral900 = Color(0xFF111714);
    const accentGreen = Color(0xFF10B981);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              neutral50,
              primaryColor.withOpacity(0.05),
              primaryLight.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          // Added 'const' here as suggested by linter
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Quarterly Installments",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: neutral900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              "Breakdown for the ${service.selectedTaxYear} tax year",
                              style: const TextStyle(
                                fontSize: 14,
                                color: accentGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildSectionCard(
                          title: "1st Quarterly Installment (April - June)",
                          icon: Icons.calendar_today,
                          color: primaryColor,
                          animationIndex: 0,
                          children: [
                            summaryRow(
                              "Total 1st Installment Employment Income",
                              _calculateQuarterlyIncome('employment', 1),
                            ),
                            summaryRow(
                              "Total 1st Installment Business Income",
                              _calculateQuarterlyIncome('business', 1),
                            ),
                            summaryRow(
                              "Total 1st Installment Investment Income",
                              _calculateQuarterlyIncome('investment', 1),
                            ),
                            summaryRow(
                              "Total 1st Installment Other Income",
                              _calculateQuarterlyIncome('other', 1),
                            ),
                            summaryRow(
                              "Total 1st Installment Foreign Income",
                              _calculateQuarterlyIncome('foreign', 1),
                            ),
                          ],
                        ),
                        _buildSectionCard(
                          title: "2nd Quarterly Installment (July - September)",
                          icon: Icons.calendar_today,
                          color: primaryColor,
                          animationIndex: 1,
                          children: [
                            summaryRow(
                              "Total 2nd Installment Employment Income",
                              _calculateQuarterlyIncome('employment', 2),
                            ),
                            summaryRow(
                              "Total 2nd Installment Business Income",
                              _calculateQuarterlyIncome('business', 2),
                            ),
                            summaryRow(
                              "Total 2nd Installment Investment Income",
                              _calculateQuarterlyIncome('investment', 2),
                            ),
                            summaryRow(
                              "Total 2nd Installment Other Income",
                              _calculateQuarterlyIncome('other', 2),
                            ),
                            summaryRow(
                              "Total 2nd Installment Foreign Income",
                              _calculateQuarterlyIncome('foreign', 2),
                            ),
                          ],
                        ),
                        _buildSectionCard(
                          title:
                              "3rd Quarterly Installment (October - December)",
                          icon: Icons.calendar_today,
                          color: primaryColor,
                          animationIndex: 2,
                          children: [
                            summaryRow(
                              "Total 3rd Installment Employment Income",
                              _calculateQuarterlyIncome('employment', 3),
                            ),
                            summaryRow(
                              "Total 3rd Installment Business Income",
                              _calculateQuarterlyIncome('business', 3),
                            ),
                            summaryRow(
                              "Total 3rd Installment Investment Income",
                              _calculateQuarterlyIncome('investment', 3),
                            ),
                            summaryRow(
                              "Total 3rd Installment Other Income",
                              _calculateQuarterlyIncome('other', 3),
                            ),
                            summaryRow(
                              "Total 3rd Installment Foreign Income",
                              _calculateQuarterlyIncome('foreign', 3),
                            ),
                          ],
                        ),
                        _buildSectionCard(
                          title: "4th Quarterly Installment (January - March)",
                          icon: Icons.calendar_today,
                          color: primaryColor,
                          animationIndex: 3,
                          children: [
                            summaryRow(
                              "Total 4th Installment Employment Income",
                              _calculateQuarterlyIncome('employment', 4),
                            ),
                            summaryRow(
                              "Total 4th Installment Business Income",
                              _calculateQuarterlyIncome('business', 4),
                            ),
                            summaryRow(
                              "Total 4th Installment Investment Income",
                              _calculateQuarterlyIncome('investment', 4),
                            ),
                            summaryRow(
                              "Total 4th Installment Other Income",
                              _calculateQuarterlyIncome('other', 4),
                            ),
                            summaryRow(
                              "Total 4th Installment Foreign Income",
                              _calculateQuarterlyIncome('foreign', 4),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

