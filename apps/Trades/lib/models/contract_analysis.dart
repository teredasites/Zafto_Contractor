/// ZAFTO Contract Analysis Model
/// Sprint P0 - February 2026
/// AI-powered contract review results

import 'package:flutter/material.dart';

/// Severity level for red flags and issues
enum IssueSeverity {
  low,      // Minor concern, acceptable in some contexts
  medium,   // Should be negotiated if possible
  high,     // Significant risk, strongly recommend changes
  critical, // Deal-breaker, do not sign without modification
}

extension IssueSeverityExtension on IssueSeverity {
  String get label {
    switch (this) {
      case IssueSeverity.low:
        return 'Low';
      case IssueSeverity.medium:
        return 'Medium';
      case IssueSeverity.high:
        return 'High';
      case IssueSeverity.critical:
        return 'Critical';
    }
  }

  Color get color {
    switch (this) {
      case IssueSeverity.low:
        return const Color(0xFF34C759); // Green
      case IssueSeverity.medium:
        return const Color(0xFFFF9500); // Orange
      case IssueSeverity.high:
        return const Color(0xFFFF3B30); // Red
      case IssueSeverity.critical:
        return const Color(0xFF8E0000); // Dark red
    }
  }

  int get sortOrder {
    switch (this) {
      case IssueSeverity.critical:
        return 0;
      case IssueSeverity.high:
        return 1;
      case IssueSeverity.medium:
        return 2;
      case IssueSeverity.low:
        return 3;
    }
  }
}

/// A red flag found in the contract
class RedFlag {
  final String id;
  final String title;
  final String description;
  final String? excerpt; // The problematic text from the contract
  final String? location; // Page/section reference
  final IssueSeverity severity;
  final String? suggestedChange;

  const RedFlag({
    required this.id,
    required this.title,
    required this.description,
    this.excerpt,
    this.location,
    required this.severity,
    this.suggestedChange,
  });

  factory RedFlag.fromJson(Map<String, dynamic> json) {
    return RedFlag(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      excerpt: json['excerpt'] as String?,
      location: json['location'] as String?,
      severity: IssueSeverity.values.firstWhere(
        (s) => s.name == json['severity'],
        orElse: () => IssueSeverity.medium,
      ),
      suggestedChange: json['suggestedChange'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'excerpt': excerpt,
    'location': location,
    'severity': severity.name,
    'suggestedChange': suggestedChange,
  };
}

/// A protection that should be in the contract but is missing
class MissingProtection {
  final String id;
  final String title;
  final String description;
  final IssueSeverity severity;
  final String? recommendedLanguage;

  const MissingProtection({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    this.recommendedLanguage,
  });

  factory MissingProtection.fromJson(Map<String, dynamic> json) {
    return MissingProtection(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      severity: IssueSeverity.values.firstWhere(
        (s) => s.name == json['severity'],
        orElse: () => IssueSeverity.medium,
      ),
      recommendedLanguage: json['recommendedLanguage'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'severity': severity.name,
    'recommendedLanguage': recommendedLanguage,
  };
}

/// A recommendation for the contract
class ContractRecommendation {
  final String id;
  final String title;
  final String description;
  final String? actionItem;
  final bool isUrgent;

  const ContractRecommendation({
    required this.id,
    required this.title,
    required this.description,
    this.actionItem,
    this.isUrgent = false,
  });

  factory ContractRecommendation.fromJson(Map<String, dynamic> json) {
    return ContractRecommendation(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      actionItem: json['actionItem'] as String?,
      isUrgent: json['isUrgent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'actionItem': actionItem,
    'isUrgent': isUrgent,
  };
}

/// Contract type detected from analysis
enum ContractType {
  subcontractor,
  primeContractor,
  serviceAgreement,
  purchaseOrder,
  changeOrder,
  warranty,
  lien,
  other,
}

extension ContractTypeExtension on ContractType {
  String get label {
    switch (this) {
      case ContractType.subcontractor:
        return 'Subcontractor Agreement';
      case ContractType.primeContractor:
        return 'Prime Contract';
      case ContractType.serviceAgreement:
        return 'Service Agreement';
      case ContractType.purchaseOrder:
        return 'Purchase Order';
      case ContractType.changeOrder:
        return 'Change Order';
      case ContractType.warranty:
        return 'Warranty';
      case ContractType.lien:
        return 'Lien Waiver';
      case ContractType.other:
        return 'Other';
    }
  }
}

/// Full contract analysis result
class ContractAnalysis {
  final String id;
  final String? bidId; // If created bid from this
  final String fileName;
  final String? customerName; // Extracted from contract
  final String? projectName; // Extracted
  final double? contractValue; // Extracted
  final DateTime analyzedAt;
  final ContractType contractType;
  final int riskScore; // 1-10 (1 = safe, 10 = very risky)
  final String summary; // Plain English summary
  final List<RedFlag> redFlags;
  final List<MissingProtection> missingProtections;
  final List<ContractRecommendation> recommendations;
  final String? rawText; // OCR extracted text
  final String? pdfPath; // Path to original document
  final List<String>? imagePaths; // Paths to scanned images
  final bool isFavorite;
  final String? notes; // User notes

  const ContractAnalysis({
    required this.id,
    this.bidId,
    required this.fileName,
    this.customerName,
    this.projectName,
    this.contractValue,
    required this.analyzedAt,
    required this.contractType,
    required this.riskScore,
    required this.summary,
    required this.redFlags,
    required this.missingProtections,
    required this.recommendations,
    this.rawText,
    this.pdfPath,
    this.imagePaths,
    this.isFavorite = false,
    this.notes,
  });

  /// Get color based on risk score
  Color get riskColor {
    if (riskScore <= 3) return const Color(0xFF34C759); // Green - low risk
    if (riskScore <= 5) return const Color(0xFFFF9500); // Orange - medium risk
    if (riskScore <= 7) return const Color(0xFFFF3B30); // Red - high risk
    return const Color(0xFF8E0000); // Dark red - critical risk
  }

  /// Get risk label
  String get riskLabel {
    if (riskScore <= 3) return 'Low Risk';
    if (riskScore <= 5) return 'Medium Risk';
    if (riskScore <= 7) return 'High Risk';
    return 'Critical Risk';
  }

  /// Count critical and high severity issues
  int get criticalIssueCount {
    int count = 0;
    for (final flag in redFlags) {
      if (flag.severity == IssueSeverity.critical || flag.severity == IssueSeverity.high) {
        count++;
      }
    }
    for (final protection in missingProtections) {
      if (protection.severity == IssueSeverity.critical || protection.severity == IssueSeverity.high) {
        count++;
      }
    }
    return count;
  }

  /// Total issue count
  int get totalIssueCount => redFlags.length + missingProtections.length;

  /// Whether this analysis found significant issues
  bool get hasSignificantIssues => riskScore >= 6 || criticalIssueCount > 0;

  factory ContractAnalysis.fromJson(Map<String, dynamic> json) {
    return ContractAnalysis(
      id: json['id'] as String,
      bidId: json['bidId'] as String?,
      fileName: json['fileName'] as String,
      customerName: json['customerName'] as String?,
      projectName: json['projectName'] as String?,
      contractValue: (json['contractValue'] as num?)?.toDouble(),
      analyzedAt: DateTime.parse(json['analyzedAt'] as String),
      contractType: ContractType.values.firstWhere(
        (t) => t.name == json['contractType'],
        orElse: () => ContractType.other,
      ),
      riskScore: json['riskScore'] as int,
      summary: json['summary'] as String,
      redFlags: (json['redFlags'] as List<dynamic>?)
          ?.map((e) => RedFlag.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      missingProtections: (json['missingProtections'] as List<dynamic>?)
          ?.map((e) => MissingProtection.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      recommendations: (json['recommendations'] as List<dynamic>?)
          ?.map((e) => ContractRecommendation.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      rawText: json['rawText'] as String?,
      pdfPath: json['pdfPath'] as String?,
      imagePaths: (json['imagePaths'] as List<dynamic>?)?.cast<String>(),
      isFavorite: json['isFavorite'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bidId': bidId,
    'fileName': fileName,
    'customerName': customerName,
    'projectName': projectName,
    'contractValue': contractValue,
    'analyzedAt': analyzedAt.toIso8601String(),
    'contractType': contractType.name,
    'riskScore': riskScore,
    'summary': summary,
    'redFlags': redFlags.map((e) => e.toJson()).toList(),
    'missingProtections': missingProtections.map((e) => e.toJson()).toList(),
    'recommendations': recommendations.map((e) => e.toJson()).toList(),
    'rawText': rawText,
    'pdfPath': pdfPath,
    'imagePaths': imagePaths,
    'isFavorite': isFavorite,
    'notes': notes,
  };

  ContractAnalysis copyWith({
    String? id,
    String? bidId,
    String? fileName,
    String? customerName,
    String? projectName,
    double? contractValue,
    DateTime? analyzedAt,
    ContractType? contractType,
    int? riskScore,
    String? summary,
    List<RedFlag>? redFlags,
    List<MissingProtection>? missingProtections,
    List<ContractRecommendation>? recommendations,
    String? rawText,
    String? pdfPath,
    List<String>? imagePaths,
    bool? isFavorite,
    String? notes,
  }) {
    return ContractAnalysis(
      id: id ?? this.id,
      bidId: bidId ?? this.bidId,
      fileName: fileName ?? this.fileName,
      customerName: customerName ?? this.customerName,
      projectName: projectName ?? this.projectName,
      contractValue: contractValue ?? this.contractValue,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      contractType: contractType ?? this.contractType,
      riskScore: riskScore ?? this.riskScore,
      summary: summary ?? this.summary,
      redFlags: redFlags ?? this.redFlags,
      missingProtections: missingProtections ?? this.missingProtections,
      recommendations: recommendations ?? this.recommendations,
      rawText: rawText ?? this.rawText,
      pdfPath: pdfPath ?? this.pdfPath,
      imagePaths: imagePaths ?? this.imagePaths,
      isFavorite: isFavorite ?? this.isFavorite,
      notes: notes ?? this.notes,
    );
  }
}

/// Common red flags in contractor agreements
class CommonRedFlags {
  static const payWhenPaid = 'Pay-when-paid or pay-if-paid clauses';
  static const broadIndemnification = 'Overly broad indemnification language';
  static const noRetainageLimit = 'No retainage release timeline';
  static const unlimitedLiability = 'Unlimited liability exposure';
  static const waiverOfLiens = 'Premature lien waiver requirements';
  static const noChangeOrderProcess = 'Missing change order provisions';
  static const shortPaymentTerms = 'Unreasonably short payment terms';
  static const onesidedTermination = 'One-sided termination rights';
  static const liquidatedDamages = 'Excessive liquidated damages';
  static const noDisputeResolution = 'Missing dispute resolution process';
  static const flowDownClauses = 'Unlimited flow-down clauses';
  static const insuranceRequirements = 'Unreasonable insurance requirements';
}

/// Common missing protections
class CommonMissingProtections {
  static const progressPayments = 'Progress payment schedule';
  static const changeOrderRights = 'Change order compensation rights';
  static const delayDamages = 'Delay damage provisions';
  static const scopeDefinition = 'Clear scope of work definition';
  static const warrantyCaps = 'Warranty period limitations';
  static const limitationOfLiability = 'Limitation of liability clause';
  static const termination = 'Mutual termination rights';
  static const disputeResolution = 'Dispute resolution mechanism';
  static const forceMAJEURE = 'Force majeure provisions';
  static const ownerObligations = 'Owner/GC obligation definitions';
}
