//pages/estimated_tax_page.dart
import 'package:flutter/material.dart';
import '../services/tax_computation_service.dart';
import '../services/tax_data_service.dart';
import 'quarterly_installment_page.dart'; // CORRECTED: Switched to plural 'installments'

class EstimatedTaxPage extends StatefulWidget {
  const EstimatedTaxPage({super.key});

  @override
  State<EstimatedTaxPage> createState() => _EstimatedTaxPageState();
}

class _EstimatedTaxPageState extends State<EstimatedTaxPage>
    with TickerProviderStateMixin {
  late final TaxComputationService taxService;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    // Initialize services
    taxService = TaxComputationService();
    // Trigger relief calculations to populate the values in the service
    taxService.totalReliefs();

    // Setup animations
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

    // Staggered animations for cards
    _cardControllers = List.generate(
      4, // Number of main sections
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

    // Start staggered animation for cards
    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 200 * i), () {
        if (mounted) _cardControllers[i].forward();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Retrieve the selectedYear passed from the previous page
    final selectedYear = ModalRoute.of(context)?.settings.arguments as String?;
    if (selectedYear != null) {
      // Update if needed, but the singleton should already be set
      TaxDataService().selectedTaxYear = selectedYear;
    }
    // Since tax values depend on input data, we trigger a rebuild to refresh the calculated values.
    // However, since we rely on `taxService` which is initialized once,
    // simply calling setState is usually enough if data mutated before arriving here.
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

  Widget _buildSummaryCard() {
    const primaryColor = Color(0xFF38E07B);
    const accentGreen = Color(0xFF10B981);
    final taxPayable = taxService.taxPayable();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: taxPayable > 0
              ? [const Color(0xFFFF6B35), const Color(0xFFFF8A50)]
              : [primaryColor, accentGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (taxPayable > 0 ? const Color(0xFFFF6B35) : primaryColor)
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  taxPayable > 0
                      ? Icons.account_balance_wallet
                      : Icons.check_circle,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taxPayable > 0 ? "Tax Payable" : "Tax Status",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      taxPayable > 0 ? "Amount Due" : "No Tax Due",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Rs. ",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  taxPayable.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF38E07B);
    const primaryLight = Color(0xFF5FE896);
    const neutral50 = Color(0xFFf8faf9);
    const neutral900 = Color(0xFF111714);
    const accentGreen = Color(0xFF10B981);
    const blueAccent = Color(0xFF1976D2);
    const orangeAccent = Color(0xFFFF6B35);
    final taxDataService = TaxDataService();

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
                // Custom App Bar
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Tax Summary",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: neutral900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              "Your complete tax calculation",
                              style: TextStyle(
                                fontSize: 14,
                                color: accentGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (taxDataService.selectedTaxYear == "2025/2026")
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                // CORRECTED: Switched to use the plural class name
                                builder: (_) =>
                                    const QuarterlyInstallmentsPage(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: accentGreen,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: accentGreen.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Text(
                              "Quarterly",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // Summary Card
                        _buildSummaryCard(),
                        // Income Components Section
                        _buildSectionCard(
                          title: "Income Components",
                          icon: Icons.account_balance_wallet,
                          color: primaryColor,
                          animationIndex: 0,
                          children: [
                            summaryRow(
                              "Total Annual Employment Income",
                              taxService.service.totalEmploymentIncome,
                            ),
                            summaryRow(
                              "Total Annual Business Income",
                              taxService.service.totalBusinessIncome,
                            ),
                            summaryRow(
                              "Total Annual Investment Income",
                              taxService.service
                                  .calculateTotalInvestmentIncome(),
                            ),
                            summaryRow(
                              "Total Annual Foreign Income",
                              taxService.service.calculateTotalForeignIncome(),
                            ),
                            Container(
                              height: 1,
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    primaryColor.withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            summaryRow(
                              "Total Assessable Income",
                              taxService.estimatedAssessableIncome(),
                              isHighlight: true,
                            ),
                          ],
                        ),
                        // Deductions & Relief Section
                        _buildSectionCard(
                          title: "Deductions & Relief",
                          icon: Icons.savings,
                          color: blueAccent,
                          animationIndex: 1,
                          children: [
                            summaryRow(
                              "Total Qualifying Payments",
                              taxService.totalQualifyingPayments(),
                            ),
                            summaryRow(
                              "Personal Relief",
                              TaxComputationService.personalRelief,
                            ),
                            summaryRow(
                              "Rent Relief",
                              taxService.service.rentRelief,
                            ),
                            summaryRow(
                              "Solar Relief",
                              taxService.service.solarPanel,
                            ),
                            Container(
                              height: 1,
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    blueAccent.withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            summaryRow(
                              "Total Relief",
                              taxService.totalReliefs(),
                              isHighlight: true,
                              valueColor: blueAccent,
                            ),
                            summaryRow(
                              "Taxable Income",
                              taxService.estimatedTaxableIncome(),
                              isHighlight: true,
                              valueColor: blueAccent,
                            ),
                          ],
                        ),
                        // Tax Calculation Section
                        _buildSectionCard(
                          title: "Tax Calculation",
                          icon: Icons.calculate,
                          color: accentGreen,
                          animationIndex: 2,
                          children: [
                            summaryRow(
                              "Taxable Income (without Foreign)",
                              taxService.taxableIncomeWithoutForeign(),
                            ),
                            summaryRow(
                              "Tax Liability (without Foreign)",
                              taxService.taxLiabilityWithoutForeign(),
                            ),
                            summaryRow(
                              "Tax Liability (Foreign @ 15%)",
                              taxService.annualForeignIncomeLiability(),
                            ),
                            summaryRow(
                              "Annual APIT (Tax Paid/Withheld)",
                              taxService.estimatedAPIT(),
                            ),
                            Container(
                              height: 1,
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    accentGreen.withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            summaryRow(
                              "Final Tax Liability",
                              taxService.finalTaxLiability(),
                              isHighlight: true,
                              valueColor: accentGreen,
                            ),
                          ],
                        ),
                        // Final Result Section
                        _buildSectionCard(
                          title: "Final Result",
                          icon: Icons.receipt_long,
                          color: orangeAccent,
                          animationIndex: 3,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    orangeAccent.withOpacity(0.1),
                                    orangeAccent.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: orangeAccent.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Tax Payable",
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: neutral900,
                                    ),
                                  ),
                                  Text(
                                    "Rs. ${taxService.taxPayable().toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: orangeAccent,
                                    ),
                                  ),
                                ],
                              ),
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
