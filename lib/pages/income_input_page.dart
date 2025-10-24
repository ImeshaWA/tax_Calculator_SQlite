//pages/income_input_page.dart
import 'package:flutter/material.dart';
import '../services/income_calculator.dart';
import '../widgets/income_field.dart';
import '../services/tax_data_service.dart';

class IncomeInputPage extends StatefulWidget {
  final String incomeType;
  const IncomeInputPage({super.key, required this.incomeType});

  @override
  State<IncomeInputPage> createState() => _IncomeInputPageState();
}

class _IncomeInputPageState extends State<IncomeInputPage>
    with TickerProviderStateMixin {
  final List<String> months = [
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

  String selectedMode = "Annual"; // Default UI mode
  int? selectedMonthIndex;

  final TextEditingController annualCtrl =
      TextEditingController(); // For dynamic types (Investment, Foreign, Other) Annual

  List<List<Map<String, TextEditingController>>> monthlyEmploymentCtrls = [];
  List<List<Map<String, TextEditingController>>> monthlyBusinessCtrls =
      []; // For Monthly UI
  List<List<TextEditingController>> monthlyDynamicCtrls =
      []; // For dynamic types Monthly
  List<TextEditingController> monthlyApitCtrls =
      []; // **** WILL BE POPULATED IN INIT ****
  final TextEditingController annualApitCtrl =
      TextEditingController(); // Employment Annual

  List<TextEditingController> monthlyRentBusinessIncomeCtrls = [];
  List<TextEditingController> monthlyRentBusinessWhtCtrls = [];
  List<String> monthlyRentMaintainedByUser = [];
  final TextEditingController rentBusinessIncomeCtrl =
      TextEditingController(); // Business Rent Annual
  final TextEditingController rentBusinessWhtCtrl =
      TextEditingController(); // Business Rent Annual
  String rentMaintainedByUser = "No"; // Business Rent Annual

  // Category Lists (Keep as is)
  final List<String> employmentCategories = const [
    "Salary / Wages",
    "Allowances",
    "Expense Reimbursements",
    "Agreement Payments",
    "Termination Payments",
    "Retirement Contributions & Payments",
    "Payments on Your Behalf",
    "Benefits in Kind",
    "Employee Share Schemes",
  ];
  final List<String> businessCategories = const [
    "Service Fees",
    "Sales of Trading Stock",
    "Capital Gains from Assets/Liabilities",
    "Realisation of Depreciable Assets",
    "Payments for Restrictions",
    "Other Business Income",
    "Rent for Business Purpose",
  ];
  final List<String> investmentCategories = const [
    "Dividends",
    "Discounts, Charges, Annuities",
    "Natural Resource Payments",
    "Premiums",
    "Royalties",
    "Gains from Selling Investment Assets",
    "Payments for Restricting Investment Activity",
    "Lottery, Betting, Gambling Winnings",
    "Other Investment",
  ];
  final List<String> foreignCategories = const [
    "Foreign Employment",
    "Foreign Business",
    "Foreign Investment",
    "Foreign Other",
  ];

  Map<String, TextEditingController> annualEmploymentCtrls =
      {}; // Employment Annual UI
  Map<String, TextEditingController> annualBusinessCtrls =
      {}; // Business Annual UI

  final service = TaxDataService();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // --- Animations (Keep as is) ---
    _fadeController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _slideController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _slideController, curve: Curves.easeOutCubic));
    _fadeController.forward();
    _slideController.forward();

    // --- Controller Initialization (MODIFIED) ---
    if (widget.incomeType == "Employment") {
      // --- Employment Init ---
      annualEmploymentCtrls = {
        for (var cat in employmentCategories)
          cat: TextEditingController(
              // **** MODIFICATION ****
              text: (service.employmentCategories[cat] ?? 0.0) > 0
                  ? service.employmentCategories[cat]!.toStringAsFixed(2)
                  : '')
      };

      if (service.monthlyEmploymentCategories.length < 12) {
        service.monthlyEmploymentCategories.addAll(List.generate(
            12 - service.monthlyEmploymentCategories.length, (_) => {}));
      }
      monthlyEmploymentCtrls = List.generate(
          12,
          (monthIndex) => employmentCategories.map((cat) {
                // **** MODIFICATION ****
                double val = (service.monthlyEmploymentCategories.length >
                            monthIndex &&
                        service.monthlyEmploymentCategories[monthIndex] != null)
                    ? service.monthlyEmploymentCategories[monthIndex][cat] ??
                        0.0
                    : 0.0;
                return {
                  cat: TextEditingController(
                      text: val > 0 ? val.toStringAsFixed(2) : '')
                };
                // **** END MODIFICATION ****
              }).toList());

      // **** MODIFICATION START: Load APIT Controllers Correctly ****
      // Ensure service.monthlyApitAmounts has 12 entries
      if (service.monthlyApitAmounts.length < 12) {
        service.monthlyApitAmounts
            .addAll(List.filled(12 - service.monthlyApitAmounts.length, 0.0));
      }
      // Load monthly APIT controllers from the service
      monthlyApitCtrls = List.generate(
          12,
          (i) => TextEditingController(
              text: service.monthlyApitAmounts[i] > 0
                  ? service.monthlyApitAmounts[i].toStringAsFixed(2)
                  : ''));

      // Load annual APIT controller (with 0 check)
      annualApitCtrl.text =
          service.apitAmount > 0 ? service.apitAmount.toStringAsFixed(2) : '';
      // **** MODIFICATION END ****

      selectedMode = "Annual"; // Default for Employment
    } else if (widget.incomeType == "Business") {
      // --- Business Init ---
      annualBusinessCtrls = {
        for (var cat in businessCategories)
          cat: TextEditingController(
              // **** MODIFICATION ****
              text: (service.businessCategories[cat] ?? 0.0) > 0
                  ? service.businessCategories[cat]!.toStringAsFixed(2)
                  : '')
      };

      if (service.monthlyBusinessCategories.length < 12) {
        service.monthlyBusinessCategories.addAll(List.generate(
            12 - service.monthlyBusinessCategories.length, (_) => {}));
      }
      monthlyBusinessCtrls = List.generate(
          12,
          (monthIndex) => businessCategories.map((cat) {
                // **** MODIFICATION ****
                double val = (service.monthlyBusinessCategories.length >
                            monthIndex &&
                        service.monthlyBusinessCategories[monthIndex] != null)
                    ? service.monthlyBusinessCategories[monthIndex][cat] ?? 0.0
                    : 0.0;
                return {
                  cat: TextEditingController(
                      text: val > 0 ? val.toStringAsFixed(2) : '')
                };
                // **** END MODIFICATION ****
              }).toList());

      // **** MODIFICATION ****
      rentBusinessIncomeCtrl.text = service.rentBusinessIncome > 0
          ? service.rentBusinessIncome.toStringAsFixed(2)
          : '';
      rentBusinessWhtCtrl.text = service.rentBusinessWht > 0
          ? service.rentBusinessWht.toStringAsFixed(2)
          : '';
      rentMaintainedByUser = service.rentMaintainedByUser ? "Yes" : "No";

      if (service.monthlyRentBusinessIncome.length < 12) {
        service.monthlyRentBusinessIncome.addAll(
            List.filled(12 - service.monthlyRentBusinessIncome.length, 0.0));
      }
      if (service.monthlyRentBusinessWht.length < 12) {
        service.monthlyRentBusinessWht.addAll(
            List.filled(12 - service.monthlyRentBusinessWht.length, 0.0));
      }
      if (service.monthlyRentMaintainedByUser.length < 12) {
        service.monthlyRentMaintainedByUser.addAll(
            List.filled(12 - service.monthlyRentMaintainedByUser.length, "No"));
      }

      monthlyRentBusinessIncomeCtrls = List.generate(
          12,
          (i) => TextEditingController(
              // **** MODIFICATION ****
              text: (service.monthlyRentBusinessIncome.length > i &&
                      service.monthlyRentBusinessIncome[i] > 0)
                  ? service.monthlyRentBusinessIncome[i].toStringAsFixed(2)
                  : ''));
      monthlyRentBusinessWhtCtrls = List.generate(
          12,
          (i) => TextEditingController(
              // **** MODIFICATION ****
              text: (service.monthlyRentBusinessWht.length > i &&
                      service.monthlyRentBusinessWht[i] > 0)
                  ? service.monthlyRentBusinessWht[i].toStringAsFixed(2)
                  : ''));
      // **** END OF MODIFICATION ****

      monthlyRentMaintainedByUser = List.generate(
          12,
          (i) => (service.monthlyRentMaintainedByUser.length > i)
              ? service.monthlyRentMaintainedByUser[i]
              : "No");
      selectedMode = service.businessInputMode;
    } else if (investmentCategories.contains(widget.incomeType) ||
        foreignCategories.contains(widget.incomeType) ||
        widget.incomeType == "Other") {
      // --- Dynamic Types Init ---
      List<Map<String, List<double>>> currentMonthlyMap;
      Map<String, double> currentAnnualMap;
      Map<String, String> currentModeMap;
      String currentIncomeType = widget.incomeType;
      bool isOther = false;

      if (investmentCategories.contains(currentIncomeType)) {
        currentMonthlyMap = service.monthlyInvestmentCategories;
        currentAnnualMap = service.investmentCategories;
        currentModeMap = service.investmentInputMode;
      } else if (foreignCategories.contains(currentIncomeType)) {
        currentMonthlyMap = service.monthlyForeignCategories;
        currentAnnualMap = service.foreignIncomeCategories;
        currentModeMap = service.foreignInputMode;
      } else {
        // Other Income
        isOther = true;
        if (service.monthlyOtherCategories.length < 12) {
          service.monthlyOtherCategories.addAll(List.generate(
              12 - service.monthlyOtherCategories.length, (_) => [0.0]));
        }
        final otherList = service.monthlyOtherCategories;
        monthlyDynamicCtrls = List.generate(
            12,
            (monthIndex) => List.generate(
                (otherList.length > monthIndex &&
                        otherList[monthIndex].isNotEmpty)
                    ? otherList[monthIndex].length
                    : 1,
                (index) => TextEditingController(
                    // **** MODIFICATION ****
                    text: (otherList.length > monthIndex &&
                            otherList[monthIndex].length > index &&
                            otherList[monthIndex][index] > 0)
                        ? otherList[monthIndex][index].toStringAsFixed(2)
                        : '')));
        // **** MODIFICATION ****
        annualCtrl.text = service.totalOtherIncome > 0
            ? service.totalOtherIncome.toStringAsFixed(2)
            : '';
        selectedMode = service.otherInputMode;
        return;
      }

      // Initialize controllers for Investment/Foreign dynamic types
      if (currentMonthlyMap.length < 12) {
        currentMonthlyMap
            .addAll(List.generate(12 - currentMonthlyMap.length, (_) => {}));
      }
      monthlyDynamicCtrls = List.generate(12, (monthIndex) {
        final monthMap = (currentMonthlyMap.length > monthIndex &&
                currentMonthlyMap[monthIndex] != null)
            ? currentMonthlyMap[monthIndex]
            : <String, List<double>>{};
        final entries = monthMap[currentIncomeType] ?? [0.0];
        final safeEntries = entries.isEmpty ? [0.0] : entries;
        return List.generate(
            safeEntries.length,
            (index) => TextEditingController(
                // **** MODIFICATION ****
                text: (safeEntries.length > index && safeEntries[index] > 0)
                    ? safeEntries[index].toStringAsFixed(2)
                    : ''));
      });

      // **** MODIFICATION ****
      double annualVal = currentAnnualMap[currentIncomeType] ?? 0.0;
      annualCtrl.text = annualVal > 0 ? annualVal.toStringAsFixed(2) : '';
      selectedMode = currentModeMap[currentIncomeType] ?? "Annual";
    } else {
      // Fallback for unknown types
      monthlyDynamicCtrls = List.generate(12, (_) => [TextEditingController()]);
      annualCtrl.text = ''; // Use empty string
      selectedMode = "Annual";
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    annualCtrl.dispose();
    annualApitCtrl.dispose();
    // Use forEach for safety on lists that might be modified
    monthlyApitCtrls.forEach((c) => c.dispose());
    monthlyRentBusinessIncomeCtrls.forEach((c) => c.dispose());
    monthlyRentBusinessWhtCtrls.forEach((c) => c.dispose());
    rentBusinessIncomeCtrl.dispose();
    rentBusinessWhtCtrl.dispose();
    monthlyEmploymentCtrls
        .forEach((m) => m.forEach((c) => c.values.first.dispose()));
    monthlyBusinessCtrls
        .forEach((m) => m.forEach((c) => c.values.first.dispose()));
    monthlyDynamicCtrls.forEach((m) => m.forEach((c) => c.dispose()));
    annualEmploymentCtrls.values.forEach((c) => c.dispose());
    annualBusinessCtrls.values.forEach((c) => c.dispose());
    super.dispose();
  }

  void addDynamicField(int monthIndex) {
    setState(
        () => monthlyDynamicCtrls[monthIndex].add(TextEditingController()));
  }

  void saveIncome() async {
    double annual = 0.0;
    double apitAmount = 0.0; // Specific to Employment

    // --- Data Processing based on Mode and Type ---
    if (selectedMode == "Annual") {
      if (widget.incomeType == "Employment") {
        // --- Employment Annual Save ---
        annual = annualEmploymentCtrls.values
            .map((c) => double.tryParse(c.text) ?? 0.0)
            .fold(0.0, (a, b) => a + b);
        apitAmount = double.tryParse(annualApitCtrl.text) ?? 0.0;
        for (var entry in annualEmploymentCtrls.entries) {
          service.employmentCategories[entry.key] =
              double.tryParse(entry.value.text) ?? 0.0;
        }
        double monthlyAverage =
            (annual == 0.0 || annual.isNaN) ? 0.0 : annual / 12; // Avoid NaN
        if (service.monthlyEmploymentTotals.length < 12) {
          service.monthlyEmploymentTotals.addAll(List.filled(
              12 - service.monthlyEmploymentTotals.length,
              0.0)); // Ensure length
        }
        for (int i = 0; i < 12; i++) {
          service.monthlyEmploymentTotals[i] = monthlyAverage;
        }

        // **** MODIFICATION: Clear monthly APIT if saving annual ****
        service.monthlyApitAmounts = List.filled(12, 0.0);
      } else if (widget.incomeType == "Business") {
        // --- Business Annual Save (Keep as is from previous fix) ---
        annual = 0.0;
        for (var entry in annualBusinessCtrls.entries) {
          if (entry.key != "Rent for Business Purpose") {
            double value = double.tryParse(entry.value.text) ?? 0.0;
            service.businessCategories[entry.key] =
                value; // Save annual category value
            annual += value;
          }
        }
        service.rentBusinessIncome =
            double.tryParse(rentBusinessIncomeCtrl.text) ?? 0.0;
        service.rentBusinessWht =
            double.tryParse(rentBusinessWhtCtrl.text) ?? 0.0;
        service.rentMaintainedByUser = (rentMaintainedByUser == "Yes");
        service.businessCategories["Rent for Business Purpose"] =
            service.rentBusinessIncome; // Add rent to annual map
        annual +=
            service.rentBusinessIncome; // Add rent to overall annual total
        double monthlyAverage =
            (annual == 0.0 || annual.isNaN) ? 0.0 : annual / 12;
        if (service.monthlyBusinessTotals.length < 12)
          service.monthlyBusinessTotals.addAll(List.filled(
              12 - service.monthlyBusinessTotals.length, 0.0)); // Ensure length
        for (int i = 0; i < 12; i++) {
          service.monthlyBusinessTotals[i] = monthlyAverage;
        }
        service.businessInputMode = "Annual"; // Set mode tracker
      } else {
        // ... (Investment, Foreign, Other - Keep as is) ...
        annual = double.tryParse(annualCtrl.text) ?? 0.0;
        List<double> targetMonthlyTotals;
        Map<String, double> targetAnnualCategoryMap;
        Map<String, String> targetModeMap;
        String currentIncomeType = widget.incomeType;
        bool isOther = false;
        if (investmentCategories.contains(currentIncomeType)) {
          targetMonthlyTotals = service.monthlyInvestmentTotals;
          targetAnnualCategoryMap = service.investmentCategories;
          targetModeMap = service.investmentInputMode;
        } else if (foreignCategories.contains(currentIncomeType)) {
          targetMonthlyTotals = service.monthlyForeignTotals;
          targetAnnualCategoryMap = service.foreignIncomeCategories;
          targetModeMap = service.foreignInputMode;
        } else {
          isOther = true;
          targetMonthlyTotals = service.monthlyOtherTotals;
          targetAnnualCategoryMap = {};
          targetModeMap = {};
        }
        if (!isOther) {
          targetAnnualCategoryMap[currentIncomeType] = annual;
        } else {
          service.totalOtherIncome = annual;
        }
        double monthlyAverage =
            (annual == 0.0 || annual.isNaN) ? 0.0 : annual / 12;
        if (targetMonthlyTotals.length < 12)
          targetMonthlyTotals
              .addAll(List.filled(12 - targetMonthlyTotals.length, 0.0));
        for (int i = 0; i < 12; i++) {
          targetMonthlyTotals[i] = monthlyAverage;
        }
        if (isOther) {
          service.otherInputMode = "Annual";
        } else {
          targetModeMap[currentIncomeType] = "Annual";
        }
      }
    } else {
      // Monthly Mode
      annual =
          getAnnualIncome(); // Calculate total from CURRENT monthly UI inputs
      if (widget.incomeType == "Employment") {
        // **** MODIFICATION START: Save Monthly APIT ****
        apitAmount = monthlyApitCtrls
            .map((c) => double.tryParse(c.text) ?? 0.0)
            .fold(0.0, (a, b) => a + b);

        if (service.monthlyEmploymentCategories.length < 12)
          service.monthlyEmploymentCategories.addAll(List.generate(
              12 - service.monthlyEmploymentCategories.length, (_) => {}));
        if (service.monthlyEmploymentTotals.length < 12)
          service.monthlyEmploymentTotals.addAll(
              List.filled(12 - service.monthlyEmploymentTotals.length, 0.0));
        if (service.monthlyApitAmounts.length < 12) // Safety check
          service.monthlyApitAmounts
              .addAll(List.filled(12 - service.monthlyApitAmounts.length, 0.0));

        for (int i = 0; i < 12; i++) {
          double monthTotal = 0.0;
          if (monthlyEmploymentCtrls.length > i) {
            for (var catMap in monthlyEmploymentCtrls[i]) {
              final category = catMap.keys.first;
              final value = double.tryParse(catMap.values.first.text) ?? 0.0;
              if (service.monthlyEmploymentCategories[i] == null)
                service.monthlyEmploymentCategories[i] = {};
              service.monthlyEmploymentCategories[i][category] = value;
              monthTotal += value;
            }
          }
          service.monthlyEmploymentTotals[i] = monthTotal;

          // *** ADD THIS LINE ***
          if (monthlyApitCtrls.length > i) {
            // Safety check
            service.monthlyApitAmounts[i] =
                double.tryParse(monthlyApitCtrls[i].text) ?? 0.0;
          } else {
            service.monthlyApitAmounts[i] = 0.0;
          }
          // *** END OF ADDITION ***
        }

        service.employmentCategories = {
          for (var cat in employmentCategories)
            cat: service.monthlyEmploymentCategories
                .fold(0.0, (sum, monthMap) => sum + (monthMap[cat] ?? 0.0))
        };
        // **** MODIFICATION END ****
      } else if (widget.incomeType == "Business") {
        // ... (Keep as is from previous fix) ...
        if (service.monthlyBusinessCategories.length < 12)
          service.monthlyBusinessCategories.addAll(List.generate(
              12 - service.monthlyBusinessCategories.length, (_) => {}));
        if (service.monthlyBusinessTotals.length < 12)
          service.monthlyBusinessTotals.addAll(
              List.filled(12 - service.monthlyBusinessTotals.length, 0.0));
        if (service.monthlyRentBusinessIncome.length < 12)
          service.monthlyRentBusinessIncome.addAll(
              List.filled(12 - service.monthlyRentBusinessIncome.length, 0.0));
        if (service.monthlyRentBusinessWht.length < 12)
          service.monthlyRentBusinessWht.addAll(
              List.filled(12 - service.monthlyRentBusinessWht.length, 0.0));
        if (service.monthlyRentMaintainedByUser.length < 12)
          service.monthlyRentMaintainedByUser.addAll(List.filled(
              12 - service.monthlyRentMaintainedByUser.length, "No"));
        for (int i = 0; i < 12; i++) {
          double monthTotal = 0.0;
          if (monthlyBusinessCtrls.length > i) {
            for (var catMap in monthlyBusinessCtrls[i]) {
              final category = catMap.keys.first;
              if (category != "Rent for Business Purpose") {
                final value = double.tryParse(catMap.values.first.text) ?? 0.0;
                if (service.monthlyBusinessCategories[i] == null)
                  service.monthlyBusinessCategories[i] = {};
                service.monthlyBusinessCategories[i][category] = value;
                monthTotal += value;
              }
            }
          }
          if (monthlyRentBusinessIncomeCtrls.length > i) {
            service.monthlyRentBusinessIncome[i] =
                double.tryParse(monthlyRentBusinessIncomeCtrls[i].text) ?? 0.0;
          } else {
            service.monthlyRentBusinessIncome[i] = 0.0;
          }
          if (monthlyRentBusinessWhtCtrls.length > i) {
            service.monthlyRentBusinessWht[i] =
                double.tryParse(monthlyRentBusinessWhtCtrls[i].text) ?? 0.0;
          } else {
            service.monthlyRentBusinessWht[i] = 0.0;
          }
          if (monthlyRentMaintainedByUser.length > i) {
            service.monthlyRentMaintainedByUser[i] =
                monthlyRentMaintainedByUser[i];
          } else {
            service.monthlyRentMaintainedByUser[i] = "No";
          }
          final rentValue = service.monthlyRentBusinessIncome[i];
          if (service.monthlyBusinessCategories[i] == null)
            service.monthlyBusinessCategories[i] = {};
          service.monthlyBusinessCategories[i]["Rent for Business Purpose"] =
              rentValue;
          monthTotal += rentValue;
          service.monthlyBusinessTotals[i] = monthTotal;
        }
        service.rentBusinessIncome = service.monthlyRentBusinessIncome
            .fold(0.0, (prev, curr) => prev + curr);
        service.rentBusinessWht = service.monthlyRentBusinessWht
            .fold(0.0, (prev, curr) => prev + curr);
        service.rentMaintainedByUser =
            service.monthlyRentMaintainedByUser.contains("Yes");
        service.businessCategories = {
          for (var cat in businessCategories)
            cat: service.monthlyBusinessCategories
                .fold(0.0, (sum, monthMap) => sum + (monthMap[cat] ?? 0.0))
        };
        service.businessCategories["Rent for Business Purpose"] =
            service.rentBusinessIncome;
        service.businessInputMode = "Monthly";
      } else {
        // ... (Investment, Foreign, Other - Keep as is) ...
        List<double> targetMonthlyTotals;
        Map<String, double> targetAnnualCategoryMap;
        List<Map<String, List<double>>> targetMonthlyCategoryMap;
        Map<String, String> targetModeMap;
        String currentIncomeType = widget.incomeType;
        bool isOther = false;
        if (investmentCategories.contains(currentIncomeType)) {
          targetMonthlyTotals = service.monthlyInvestmentTotals;
          targetAnnualCategoryMap = service.investmentCategories;
          targetMonthlyCategoryMap = service.monthlyInvestmentCategories;
          targetModeMap = service.investmentInputMode;
        } else if (foreignCategories.contains(currentIncomeType)) {
          targetMonthlyTotals = service.monthlyForeignTotals;
          targetAnnualCategoryMap = service.foreignIncomeCategories;
          targetMonthlyCategoryMap = service.monthlyForeignCategories;
          targetModeMap = service.foreignInputMode;
        } else {
          isOther = true;
          targetMonthlyTotals = service.monthlyOtherTotals;
          targetAnnualCategoryMap = {};
          targetMonthlyCategoryMap = [];
          targetModeMap = {};
        }
        if (targetMonthlyTotals.length < 12)
          targetMonthlyTotals
              .addAll(List.filled(12 - targetMonthlyTotals.length, 0.0));
        if (!isOther && targetMonthlyCategoryMap.length < 12)
          targetMonthlyCategoryMap.addAll(
              List.generate(12 - targetMonthlyCategoryMap.length, (_) => {}));
        if (isOther && service.monthlyOtherCategories.length < 12)
          service.monthlyOtherCategories.addAll(List.generate(
              12 - service.monthlyOtherCategories.length, (_) => [0.0]));
        for (int i = 0; i < 12; i++) {
          if (monthlyDynamicCtrls.length > i) {
            final monthlyValues = monthlyDynamicCtrls[i]
                .map((ctrl) => double.tryParse(ctrl.text) ?? 0.0)
                .toList();
            double monthTotal =
                monthlyValues.fold(0.0, (sum, val) => sum + val);
            targetMonthlyTotals[i] = monthTotal;
            if (isOther) {
              service.monthlyOtherCategories[i] =
                  monthlyValues.isNotEmpty ? monthlyValues : [0.0];
            } else {
              if (targetMonthlyCategoryMap.length <= i)
                targetMonthlyCategoryMap.add({});
              if (targetMonthlyCategoryMap[i] == null)
                targetMonthlyCategoryMap[i] = {};
              targetMonthlyCategoryMap[i][currentIncomeType] =
                  monthlyValues.isNotEmpty ? monthlyValues : [0.0];
            }
          } else {
            targetMonthlyTotals[i] = 0.0;
            if (isOther) {
              if (service.monthlyOtherCategories.length <= i)
                service.monthlyOtherCategories.add([0.0]);
              else
                service.monthlyOtherCategories[i] = [0.0];
            } else {
              if (targetMonthlyCategoryMap.length <= i)
                targetMonthlyCategoryMap.add({});
              if (targetMonthlyCategoryMap[i] == null)
                targetMonthlyCategoryMap[i] = {};
              targetMonthlyCategoryMap[i][currentIncomeType] = [0.0];
            }
          }
        }
        if (!isOther) {
          targetAnnualCategoryMap[currentIncomeType] = annual;
        } else {
          service.totalOtherIncome = annual;
        }
        if (isOther) {
          service.otherInputMode = "Monthly";
        } else {
          targetModeMap[currentIncomeType] = "Monthly";
        }
      }
    }

    // --- Final Update and Save ---
    service.totalEmploymentIncome =
        service.monthlyEmploymentTotals.fold(0.0, (prev, curr) => prev + curr);

    // **** MODIFICATION: Update service.apitAmount with the correct total ****
    // If we just saved monthly, apitAmount holds the sum. If we saved annual, apitAmount holds that value.
    service.apitAmount = apitAmount;

    service.totalBusinessIncome =
        service.monthlyBusinessTotals.fold(0.0, (prev, curr) => prev + curr);
    service.totalInvestmentIncome =
        service.monthlyInvestmentTotals.fold(0.0, (prev, curr) => prev + curr);
    service.totalForeignIncome =
        service.monthlyForeignTotals.fold(0.0, (prev, curr) => prev + curr);
    service.totalOtherIncome =
        service.monthlyOtherTotals.fold(0.0, (prev, curr) => prev + curr);

    if (selectedMode == "Monthly" && widget.incomeType == "Employment") {
      service.employmentCategories = {
        for (var cat in employmentCategories)
          cat: service.monthlyEmploymentCategories
              .fold(0.0, (sum, monthMap) => sum + (monthMap[cat] ?? 0.0))
      };
    }
    if (selectedMode == "Monthly" && widget.incomeType == "Business") {
      service.businessCategories = {
        for (var cat in businessCategories)
          cat: service.monthlyBusinessCategories
              .fold(0.0, (sum, monthMap) => sum + (monthMap[cat] ?? 0.0))
      };
      service.rentBusinessIncome = service.monthlyRentBusinessIncome
          .fold(0.0, (prev, curr) => prev + curr);
      service.businessCategories["Rent for Business Purpose"] =
          service.rentBusinessIncome;
    } else if (selectedMode == "Annual" && widget.incomeType == "Business") {
      service.businessCategories["Rent for Business Purpose"] =
          service.rentBusinessIncome;
    }
    if (selectedMode == "Monthly") {
      if (investmentCategories.contains(widget.incomeType)) {
        service.investmentCategories[widget.incomeType] = annual;
      } else if (foreignCategories.contains(widget.incomeType)) {
        service.foreignIncomeCategories[widget.incomeType] = annual;
      }
    } else if (selectedMode == "Annual") {
      if (investmentCategories.contains(widget.incomeType)) {
        service.investmentCategories[widget.incomeType] = annual;
      } else if (foreignCategories.contains(widget.incomeType)) {
        service.foreignIncomeCategories[widget.incomeType] = annual;
      }
    }
    service.calculateTotalInvestmentIncome();
    service.totalForeignIncome = service.calculateTotalForeignIncome();

    await service.saveDataForCurrentUserAndYear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Saved ${widget.incomeType} income (${selectedMode})"),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      Navigator.pop(context);
    }
  }
  // **** MODIFICATIONS END ****

  double getAnnualIncome() {
    // ... (keep as is) ...
    if (widget.incomeType == "Employment") {
      return monthlyEmploymentCtrls.fold(0.0, (sum, monthList) {
        final monthTotal = monthList.fold<double>(0.0, (mSum, catMap) {
          return mSum + (double.tryParse(catMap.values.first.text) ?? 0.0);
        });
        return sum + monthTotal;
      });
    } else if (widget.incomeType == "Business") {
      return monthlyBusinessCtrls.fold(0.0, (sum, monthList) {
        final monthTotal = monthList.fold<double>(0.0, (mSum, catMap) {
          return mSum + (double.tryParse(catMap.values.first.text) ?? 0.0);
        });
        return sum + monthTotal;
      });
    } else {
      return monthlyDynamicCtrls.fold(0.0, (annualSum, monthCtrls) {
        double monthTotal = monthCtrls.fold(0.0, (monthSum, ctrl) {
          return monthSum + (double.tryParse(ctrl.text) ?? 0.0);
        });
        return annualSum + monthTotal;
      });
    }
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
                                color: primaryColor.withOpacity(0.2)),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: Icon(Icons.arrow_back_rounded,
                              color: primaryColor, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${widget.incomeType} Income",
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: neutral900)),
                            const Text("Enter your income details",
                                style: TextStyle(
                                    fontSize: 14,
                                    color: accentGreen,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildModeToggle(),
                if (selectedMode == "Monthly") _buildMonthSelector(),
                Expanded(
                    child: selectedMode == "Annual"
                        ? _buildAnnualView()
                        : _buildMonthlyView()),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: saveIncome,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        label:
            const Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.save_rounded),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildModeToggle() {
    // ... (keep as is) ...
    const primaryColor = Color(0xFF38E07B);
    const primaryDark = Color(0xFF2DD96A);
    const neutral50 = Color(0xFFf8faf9);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: neutral50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: ["Annual", "Monthly"].map((mode) {
          final selected = selectedMode == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                selectedMode = mode;
                if (mode == "Annual") {
                  selectedMonthIndex = null;
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
                child: Text(mode,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: selected ? Colors.white : primaryDark,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthSelector() {
    // ... (keep as is) ...
    const primaryColor = Color(0xFF38E07B);
    const primaryLight = Color(0xFF5FE896);
    const neutral50 = Color(0xFFf8faf9);
    const neutral900 = Color(0xFF111714);
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: months.length,
        itemBuilder: (context, i) {
          final selected = selectedMonthIndex == i;
          return GestureDetector(
            onTap: () => setState(() => selectedMonthIndex = i),
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

  Widget _buildRentSection() {
    // ... (keep as is) ...
    const primaryColor = Color(0xFF38E07B);
    const accentGreen = Color(0xFF10B981);
    const neutral300 = Color(0xFFdce5df);
    const neutral900 = Color(0xFF111714);
    final rentIncomeCtrl = selectedMode == "Monthly" &&
            selectedMonthIndex != null &&
            monthlyRentBusinessIncomeCtrls.length > selectedMonthIndex!
        ? monthlyRentBusinessIncomeCtrls[selectedMonthIndex!]
        : rentBusinessIncomeCtrl;
    final rentWhtCtrl = selectedMode == "Monthly" &&
            selectedMonthIndex != null &&
            monthlyRentBusinessWhtCtrls.length > selectedMonthIndex!
        ? monthlyRentBusinessWhtCtrls[selectedMonthIndex!]
        : rentBusinessWhtCtrl;
    final maintainedByUser = selectedMode == "Monthly" &&
            selectedMonthIndex != null &&
            monthlyRentMaintainedByUser.length > selectedMonthIndex!
        ? monthlyRentMaintainedByUser[selectedMonthIndex!]
        : rentMaintainedByUser;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient:
                      const LinearGradient(colors: [primaryColor, accentGreen]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.home_work, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                "Rent for Business Purpose",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: neutral900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          IncomeField(
            controller: rentIncomeCtrl,
            label: selectedMode == "Monthly" && selectedMonthIndex != null
                ? "Rent Income (${months[selectedMonthIndex!]})"
                : "Rent Income (Annual)",
          ),
          const SizedBox(height: 12),
          IncomeField(
            controller: rentWhtCtrl,
            label: selectedMode == "Monthly" && selectedMonthIndex != null
                ? "WHT Amount (${months[selectedMonthIndex!]})"
                : "WHT Amount (Annual)",
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: neutral300),
            ),
            child: Row(
              children: [
                Text(
                  "Maintained by User? ",
                  style: TextStyle(
                    color: neutral900.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryColor.withOpacity(0.3)),
                  ),
                  child: DropdownButton<String>(
                    value: maintainedByUser,
                    underline: const SizedBox(),
                    dropdownColor: Colors.white,
                    style: const TextStyle(
                      color: neutral900,
                      fontWeight: FontWeight.w500,
                    ),
                    items: ["Yes", "No"]
                        .map(
                          (val) =>
                              DropdownMenuItem(value: val, child: Text(val)),
                        )
                        .toList(),
                    onChanged: (val) => setState(() {
                      if (selectedMode == "Monthly" &&
                          selectedMonthIndex != null &&
                          monthlyRentMaintainedByUser.length >
                              selectedMonthIndex!) {
                        monthlyRentMaintainedByUser[selectedMonthIndex!] =
                            val ?? "No";
                      } else {
                        rentMaintainedByUser = val ?? "No";
                      }
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnualView() {
    // ... (keep as is) ...
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: widget.incomeType == "Employment"
          ? Column(
              children: [
                ...annualEmploymentCtrls.keys.map(
                  (label) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: IncomeField(
                      controller: annualEmploymentCtrls[label]!,
                      label: label,
                    ),
                  ),
                ),
                Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color(0xFF38E07B),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                IncomeField(
                    controller: annualApitCtrl, label: "APIT Amount (Annual)"),
              ],
            )
          : widget.incomeType == "Business"
              ? Column(
                  children: [
                    ...annualBusinessCtrls.keys.map((label) {
                      if (label == "Rent for Business Purpose") {
                        return _buildRentSection();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: IncomeField(
                          controller: annualBusinessCtrls[label]!,
                          label: label,
                        ),
                      );
                    }),
                  ],
                )
              : Column(
                  children: [
                    IncomeField(
                      controller: annualCtrl,
                      label: "${widget.incomeType} Income (Annual)",
                    ),
                  ],
                ),
    );
  }

  Widget _buildMonthlyView() {
    // ... (keep as is) ...
    const primaryColor = Color(0xFF38E07B);
    if (selectedMonthIndex == null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(20),
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
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month_rounded, color: primaryColor, size: 32),
              SizedBox(height: 16),
              Text(
                "Select a month to enter details",
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }
    if (widget.incomeType == "Employment" &&
        monthlyEmploymentCtrls.length <= selectedMonthIndex!)
      return Container();
    if (widget.incomeType == "Business" &&
        monthlyBusinessCtrls.length <= selectedMonthIndex!) return Container();
    if ((investmentCategories.contains(widget.incomeType) ||
            foreignCategories.contains(widget.incomeType) ||
            widget.incomeType == "Other") &&
        monthlyDynamicCtrls.length <= selectedMonthIndex!) return Container();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: widget.incomeType == "Employment"
          ? Column(
              children: [
                ...monthlyEmploymentCtrls[selectedMonthIndex!].map((catMap) {
                  final label = catMap.keys.first;
                  final ctrl = catMap.values.first;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: IncomeField(controller: ctrl, label: label),
                  );
                }),
                Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        primaryColor,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                if (monthlyApitCtrls.length > selectedMonthIndex!)
                  IncomeField(
                    controller: monthlyApitCtrls[selectedMonthIndex!],
                    label: "APIT Amount (${months[selectedMonthIndex!]})",
                  ),
              ],
            )
          : widget.incomeType == "Business"
              ? Column(
                  children: [
                    ...monthlyBusinessCtrls[selectedMonthIndex!].map((catMap) {
                      final label = catMap.keys.first;
                      final ctrl = catMap.values.first;
                      if (label == "Rent for Business Purpose") {
                        return _buildRentSection();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: IncomeField(controller: ctrl, label: label),
                      );
                    }),
                  ],
                )
              : Column(
                  children: [
                    if (monthlyDynamicCtrls.length > selectedMonthIndex! &&
                        monthlyDynamicCtrls[selectedMonthIndex!].isNotEmpty)
                      ...List.generate(
                        monthlyDynamicCtrls[selectedMonthIndex!].length,
                        (j) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: IncomeField(
                            controller: monthlyDynamicCtrls[selectedMonthIndex!]
                                [j],
                            label: "${widget.incomeType} ${j + 1}",
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => addDynamicField(selectedMonthIndex!),
                      icon: const Icon(Icons.add_circle_outline,
                          color: Colors.white),
                      label: Text("Add ${widget.incomeType} Income",
                          style: const TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: primaryColor.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
    );
  }
}
