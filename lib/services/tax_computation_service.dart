//services/tax_computation_service.dart

import 'tax_data_service.dart';

class TaxComputationService {
  final TaxDataService service = TaxDataService();

  // Fixed system constants
  static double get personalRelief {
    return TaxDataService().selectedTaxYear == "2025/2026"
        ? 1800000.0
        : 1200000.0;
  }
  static const double solarPanelSystemValue = 600000.0;

  // 1. Estimated Assessable Income
  double estimatedAssessableIncome() {
    return service.totalEmploymentIncome +
        service.totalBusinessIncome +
        service.calculateTotalInvestmentIncome() +
        service.calculateTotalForeignIncome() +
        service.totalOtherIncome;
  }

  // 2. Total Qualifying Payments
  double totalQualifyingPayments() {
    return service.charity +
        service.govDonations +
        service.presidentsFund +
        service.femaleShop +
        service.filmExpenditure +
        service.cinemaNew +
        service.cinemaUpgrade;
  }

  // 3. Total Reliefs
  double totalReliefs() {
    // Personal relief
    double reliefTotal = personalRelief;

    // Solar relief calculation
    double totalInstallCost = service.solarInstallCost;
    int timesAvailed = service.solarReliefCount;
    double usedRelief = timesAvailed * solarPanelSystemValue;
    double solarCostBalance = totalInstallCost - usedRelief;

    double solarRelief = 0.0;
    if (solarCostBalance > 0) {
      if (solarCostBalance >= solarPanelSystemValue) {
        solarRelief = solarPanelSystemValue;
      } else {
        solarRelief = solarCostBalance;
      }
    }

    // Rent relief calculation
    double rentRelief = 0.0;
    // Check "Maintained by User?" for Rent for Business Purpose
    if (service.rentMaintainedByUser == true) {
      rentRelief += service.rentBusinessIncome * 0.25;
    }
    // Check "Is the building/house maintained by you?" for Rent Income
    if (service.isMaintainedByUser == true) {
      rentRelief += service.totalRentIncome * 0.25;
    }

    // Update service fields
    service.solarPanel = solarRelief;
    service.rentRelief = rentRelief;

    // Add them up
    reliefTotal += solarRelief + rentRelief;

    return reliefTotal;
  }

  // 4. Estimated Taxable Income
  double estimatedTaxableIncome() {
    double assessableIncome = estimatedAssessableIncome();
    if (assessableIncome <= personalRelief) {
      return 0;
    }
    double result =
        assessableIncome - totalQualifyingPayments() - totalReliefs();
    return result < 0 ? 0 : result;
  }

  // 5. Estimated APIT (Advance Personal Income Tax)
  double estimatedAPIT() {
    return service.apitAmount;
  }

  // 6. Taxable Income without foreign income
  double taxableIncomeWithoutForeign() {
    double taxable =
        estimatedTaxableIncome() - service.calculateTotalForeignIncome();
    return taxable < 0 ? 0 : taxable;
  }

  // 7. Estimated Tax Liability without foreign income (slab-based)
  double taxLiabilityWithoutForeign() {
    double taxable = taxableIncomeWithoutForeign();
    double tax = 0.0;

    if (taxable <= 0) return 0.0;

    // First 1,000,000 at 6%
    if (taxable <= 1000000) {
      return taxable * 0.06;
    }
    tax += 1000000 * 0.06;
    taxable -= 1000000;

    // Next 500,000 at 18%
    if (taxable <= 500000) {
      return tax + (taxable * 0.18);
    }
    tax += 500000 * 0.18;
    taxable -= 500000;

    // Next 500,000 at 24%
    if (taxable <= 500000) {
      return tax + (taxable * 0.24);
    }
    tax += 500000 * 0.24;
    taxable -= 500000;

    // Next 500,000 at 30%
    if (taxable <= 500000) {
      return tax + (taxable * 0.30);
    }
    tax += 500000 * 0.30;
    taxable -= 500000;

    // Balance at 36%
    return tax + (taxable * 0.36);
  }

  // 8. Annual Foreign Income Liability
  double annualForeignIncomeLiability() {
    double totalForeignIncome = service.calculateTotalForeignIncome();
    double liability = totalForeignIncome * 0.15;
    return liability < 0 ? 0 : liability;
  }

  // 9. Final Tax Liability
  double finalTaxLiability() {
    return taxLiabilityWithoutForeign() + annualForeignIncomeLiability();
  }

  // 10. Tax Payable
  double taxPayable() {
    double payable =
        finalTaxLiability() - estimatedAPIT() - service.foreignTaxCredits;
    return payable < 0 ? 0 : payable;
  }
}
