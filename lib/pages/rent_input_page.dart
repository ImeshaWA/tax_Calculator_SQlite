//pages/rent_input_page.dart
import 'package:flutter/material.dart';
import '../services/tax_data_service.dart';
import '../widgets/income_field.dart';

class RentInputPage extends StatefulWidget {
  const RentInputPage({super.key});

  @override
  State<RentInputPage> createState() => _RentInputPageState();
}

class _RentInputPageState extends State<RentInputPage>
    with TickerProviderStateMixin {
  final TaxDataService service = TaxDataService();

  final List<String> months = const [
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
    "January",
    "February",
    "March",
  ];

  // Resident purpose
  String residentMode = "Annual"; // Default mode
  int? selectedResidentMonth;
  final TextEditingController annualResidentCtrl = TextEditingController();
  late List<List<TextEditingController>> monthlyResidentCtrls;

  // New field for maintenance responsibility
  bool isMaintainedByUser = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();

    // Initialize controllers
    isMaintainedByUser = service.isMaintainedByUser ?? false;
    annualResidentCtrl.text = service.totalRentIncome.toStringAsFixed(2);

    // Initialize monthly controllers with default placeholder/saved data
    // Ensure monthlyInvestmentCategories has 12 entries
    if (service.monthlyInvestmentCategories.length < 12) {
      service.monthlyInvestmentCategories.addAll(List.generate(
          12 - service.monthlyInvestmentCategories.length, (_) => {}));
    }

    monthlyResidentCtrls = List.generate(
      12,
      (monthIndex) {
        // Find saved monthly data in investment categories under 'Residential Rental Income'
        // Ensure the map for the month exists
        final monthMap = service.monthlyInvestmentCategories[monthIndex];
        final savedEntries = monthMap['Residential Rental Income'] ??
            [0.0]; // Default if key not found

        return List.generate(
          savedEntries.isNotEmpty
              ? savedEntries.length
              : 1, // Ensure at least one controller
          (index) => TextEditingController(
            text: savedEntries.length > index && savedEntries[index] >= 0
                ? savedEntries[index].toStringAsFixed(2)
                // Use empty string or '0.00' based on preference for empty fields
                : '', // Or '0.00'
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    annualResidentCtrl.dispose();
    for (var monthList in monthlyResidentCtrls) {
      for (var ctrl in monthList) {
        ctrl.dispose();
      }
    }
    super.dispose();
  }

  void addDynamicField(int monthIndex) {
    setState(() {
      // Ensure the list for the month exists before adding
      if (monthlyResidentCtrls.length > monthIndex) {
        monthlyResidentCtrls[monthIndex].add(TextEditingController());
      }
    });
  }

  // **** MODIFICATION: Added async and await saveData ****
  void saveRent() async {
    // Add async
    double totalResident = 0.0;

    // 1. Calculate and update monthly totals
    if (residentMode == "Annual") {
      totalResident = double.tryParse(annualResidentCtrl.text) ?? 0.0;
      // For annual mode, distribute evenly to monthly totals AND detailed monthly list
      double monthlyAmount = (totalResident.isNaN || totalResident == 0.0)
          ? 0.0
          : totalResident / 12; // Avoid NaN
      // Ensure lists have 12 elements
      if (service.monthlyInvestmentTotals.length < 12)
        service.monthlyInvestmentTotals.addAll(
            List.filled(12 - service.monthlyInvestmentTotals.length, 0.0));
      if (service.monthlyInvestmentCategories.length < 12)
        service.monthlyInvestmentCategories.addAll(List.generate(
            12 - service.monthlyInvestmentCategories.length, (_) => {}));

      for (int i = 0; i < 12; i++) {
        service.monthlyInvestmentTotals[i] =
            monthlyAmount; // Update main monthly total used for quarterly
        // Also update the detailed monthly list to reflect the annual input
        if (service.monthlyInvestmentCategories[i] == null)
          service.monthlyInvestmentCategories[i] = {}; // Ensure map exists
        service.monthlyInvestmentCategories[i]
            ['Residential Rental Income'] = [monthlyAmount];
      }
    } else if (residentMode == "Monthly") {
      // Ensure lists have 12 elements
      if (service.monthlyInvestmentTotals.length < 12)
        service.monthlyInvestmentTotals.addAll(
            List.filled(12 - service.monthlyInvestmentTotals.length, 0.0));
      if (service.monthlyInvestmentCategories.length < 12)
        service.monthlyInvestmentCategories.addAll(List.generate(
            12 - service.monthlyInvestmentCategories.length, (_) => {}));

      // Calculate total from monthly inputs and update monthly breakdown
      for (int i = 0; i < 12; i++) {
        // Ensure controllers exist for this month
        if (monthlyResidentCtrls.length > i) {
          // 1. Sum and save monthly itemized rent income
          final monthlyIncomeList = monthlyResidentCtrls[i]
              .map((ctrl) => double.tryParse(ctrl.text) ?? 0.0)
              .toList();
          // Ensure map for the month exists before assignment
          if (service.monthlyInvestmentCategories[i] == null)
            service.monthlyInvestmentCategories[i] = {};
          service.monthlyInvestmentCategories[i]['Residential Rental Income'] =
              monthlyIncomeList.isNotEmpty
                  ? monthlyIncomeList
                  : [0.0]; // Store even if empty, avoids null issues

          // 2. Calculate monthly total income
          final monthTotal =
              monthlyIncomeList.fold(0.0, (sum, value) => sum + value);
          totalResident += monthTotal;

          // 3. Update the monthly investment total for quarterly calculation
          service.monthlyInvestmentTotals[i] =
              monthTotal; // Update main monthly total
        } else {
          // Handle case where controllers might not exist (shouldn't happen with proper init)
          service.monthlyInvestmentTotals[i] = 0.0;
          if (service.monthlyInvestmentCategories[i] == null)
            service.monthlyInvestmentCategories[i] = {};
          service.monthlyInvestmentCategories[i]
              ['Residential Rental Income'] = [0.0];
        }
      }
    }

    // 2. Update service fields
    service.totalRentIncome = totalResident;
    service.isMaintainedByUser = isMaintainedByUser;
    // Update the master annual category map entry
    service.investmentCategories["Residential Rental Income"] = totalResident;
    // Recalculate overall investment total
    service.calculateTotalInvestmentIncome();

    // *** ADD THIS LINE TO SAVE TO DATABASE ***
    await service.saveDataForCurrentUserAndYear();
    // *** END OF ADDITION ***

    // 3. Show confirmation and pop
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                "Rent income saved: Rs. ${totalResident.toStringAsFixed(2)}", // Updated message
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    }
  }
  // **** END OF MODIFICATION ****

  Widget _buildModeToggle() {
    const primaryColor = Color(0xFF38E07B);
    const primaryDark = Color(0xFF2DD96A);
    const neutral50 = Color(0xFFf8faf9);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: neutral50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: ["Annual", "Monthly"].map((mode) {
          final selected = residentMode == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                residentMode = mode;
                if (mode == "Annual") {
                  selectedResidentMonth =
                      null; // Clear month selection if switching to Annual
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ]
                      : null,
                ),
                child: Text(
                  mode,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : primaryDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthSelector() {
    const primaryColor = Color(0xFF38E07B);
    const primaryLight = Color(0xFF5FE896);
    const neutral50 = Color(0xFFf8faf9);
    const neutral900 = Color(0xFF111714);

    // **** MODIFICATION: Always show month selector in Monthly mode ****
    // Removed the check for service.selectedTaxYear == "2025/2026"
    // Now monthly input is always possible if selected, though quarterly page might still handle years differently.

    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: months.length,
        itemBuilder: (context, i) {
          final selected = selectedResidentMonth == i;
          return GestureDetector(
            onTap: () => setState(() => selectedResidentMonth = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [primaryColor, primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: selected ? null : neutral50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      selected ? primaryColor : primaryColor.withOpacity(0.3),
                  width: selected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? primaryColor.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: selected ? 8 : 4,
                    offset: Offset(0, selected ? 3 : 1),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  months[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: selected ? Colors.white : neutral900,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  // **** END OF MODIFICATION ****

  Widget _buildMaintenanceSection() {
    // ... (keep as is) ...
    const primaryColor = Color(0xFF38E07B);
    const accentGreen = Color(0xFF10B981);
    const neutral900 = Color(0xFF111714);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryColor, accentGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.build_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  "Maintenance Responsibility",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: neutral900,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Is the building/house maintained by you?",
            style: TextStyle(
              fontSize: 16,
              color: neutral900.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => isMaintainedByUser = true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: isMaintainedByUser == true
                          ? const LinearGradient(
                              colors: [primaryColor, accentGreen])
                          : null,
                      color: isMaintainedByUser == true
                          ? null
                          : primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isMaintainedByUser == true
                            ? primaryColor
                            : primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isMaintainedByUser == true
                                  ? Colors.white
                                  : primaryColor,
                              width: 2,
                            ),
                            color: isMaintainedByUser == true
                                ? Colors.white
                                : Colors.transparent,
                          ),
                          child: isMaintainedByUser == true
                              ? Icon(Icons.check, size: 14, color: primaryColor)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Yes",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isMaintainedByUser == true
                                ? Colors.white
                                : primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => isMaintainedByUser = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: isMaintainedByUser == false
                          ? const LinearGradient(
                              colors: [primaryColor, accentGreen])
                          : null,
                      color: isMaintainedByUser == false
                          ? null
                          : primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isMaintainedByUser == false
                            ? primaryColor
                            : primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isMaintainedByUser == false
                                  ? Colors.white
                                  : primaryColor,
                              width: 2,
                            ),
                            color: isMaintainedByUser == false
                                ? Colors.white
                                : Colors.transparent,
                          ),
                          child: isMaintainedByUser == false
                              ? Icon(Icons.check, size: 14, color: primaryColor)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "No",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isMaintainedByUser == false
                                ? Colors.white
                                : primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildIncomeSection(String title) {
    const primaryColor = Color(0xFF38E07B);
    const primaryDark = Color(0xFF2DD96A);
    const accentGreen = Color(0xFF10B981);
    const neutral900 = Color(0xFF111714);

    String mode = residentMode;
    int? selectedMonth = selectedResidentMonth;
    List<List<TextEditingController>> monthlyCtrls = monthlyResidentCtrls;
    TextEditingController annualCtrl = annualResidentCtrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryColor, accentGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.home_outlined,
                    color: Colors.white, size: 24),
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

          // **** MODIFICATION: Show toggle regardless of year ****
          _buildModeToggle(),
          // **** END OF MODIFICATION ****

          const SizedBox(height: 16),

          // Annual mode
          if (mode == "Annual") // Show Annual field if mode is Annual
            IncomeField(controller: annualCtrl, label: "$title Annual Amount"),

          // Monthly mode
          if (mode == "Monthly") ...[
            // Show Monthly selector and fields if mode is Monthly
            _buildMonthSelector(),

            // Show inputs only for selected month
            if (selectedMonth != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.05),
                      accentGreen.withOpacity(0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${months[selectedMonth]} Income",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Ensure controllers exist before building fields
                    if (monthlyCtrls.length > selectedMonth &&
                        monthlyCtrls[selectedMonth].isNotEmpty)
                      ...List.generate(
                        monthlyCtrls[selectedMonth].length,
                        (j) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: IncomeField(
                            controller: monthlyCtrls[selectedMonth][j],
                            label: "$title ${j + 1}",
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => addDynamicField(selectedMonth),
                        icon: const Icon(Icons.add_circle_outline,
                            color: Colors.white),
                        label: Text("Add $title Income",
                            style: const TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ).copyWith(
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color?>((
                            Set<WidgetState> states,
                          ) {
                            if (states.contains(WidgetState.pressed))
                              return primaryDark;
                            return primaryColor;
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else // Show 'Select Month' placeholder if Monthly mode but no month selected
              Container(
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      color: primaryColor,
                      size: 32,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Select a month to enter details",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (keep as is) ...
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
                // Custom App Bar
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
                              "Rent Income",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: neutral900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              "Enter your rental income details",
                              style: TextStyle(
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

                // Content
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          buildIncomeSection("Resident Purpose"),
                          _buildMaintenanceSection(),
                          const SizedBox(
                              height: 100), // Space for floating button
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: saveRent, // Calls the modified saveRent
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        label: const Text(
          "Save Rent Income",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.save_rounded),
      ),
    );
  }
}

