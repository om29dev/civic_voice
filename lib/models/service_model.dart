import 'package:flutter/material.dart';

enum RuleOperator { greaterThan, lessThan, equalTo, contains }

class EligibilityRule {
  final String question;
  final String parameter;
  final RuleOperator operator;
  final dynamic value;
  final String explanation;

  const EligibilityRule({
    required this.question,
    required this.parameter,
    required this.operator,
    required this.value,
    required this.explanation,
  });

  bool evaluate(dynamic input) {
    switch (operator) {
      case RuleOperator.greaterThan:
        return (input as num) >= (value as num);
      case RuleOperator.lessThan:
        return (input as num) <= (value as num);
      case RuleOperator.equalTo:
        return input == value;
      case RuleOperator.contains:
        return (input as String).contains(value as String);
    }
  }
}

class ProcessStep {
  final String title;
  final int order;
  final bool isCompleted;
  final String? instruction;

  const ProcessStep({
    required this.title,
    required this.order,
    this.isCompleted = false,
    this.instruction,
  });
}

class GovernmentService {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<EligibilityRule> eligibilityRules;
  final List<String> documents;
  final List<ProcessStep> steps;

  const GovernmentService({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.eligibilityRules,
    required this.documents,
    required this.steps,
  });
}

// Initializing the 5 Core Modules as per requirements
final List<GovernmentService> appServices = [
  GovernmentService(
    id: 'pension',
    title: 'Old Age Pension',
    description: 'Financial assistance for senior citizens above 60 years.',
    icon: Icons.elderly_rounded,
    color: Colors.orange,
    eligibilityRules: [
      EligibilityRule(
        question: 'What is your age?',
        parameter: 'age',
        operator: RuleOperator.greaterThan,
        value: 60,
        explanation: 'The Old Age Pension is exclusively for citizens aged 60 and above.',
      ),
      EligibilityRule(
        question: 'What is your annual family income?',
        parameter: 'income',
        operator: RuleOperator.lessThan,
        value: 200000,
        explanation: 'Your family income must be less than ₹2,00,000 per year.',
      ),
    ],
    documents: [
      'Aadhaar Card',
      'Age Proof (Birth Certificate/10th Marksheet)',
      'Income Certificate',
      'Bank Passbook'
    ],
    steps: [
      ProcessStep(title: 'Visit Tehsil Office', order: 1, instruction: 'Collect Form 10A from the local office.'),
      ProcessStep(title: 'Identity Verification', order: 2),
      ProcessStep(title: 'Document Submission', order: 3),
      ProcessStep(title: 'Final Approval', order: 4),
    ],
  ),
  GovernmentService(
    id: 'ration',
    title: 'Ration Card',
    description: 'Subsidized food grains for eligible families.',
    icon: Icons.shopping_basket_rounded,
    color: Colors.green,
    eligibilityRules: [
      EligibilityRule(
        question: 'Do you currently have a ration card in another state?',
        parameter: 'has_other',
        operator: RuleOperator.equalTo,
        value: false,
        explanation: 'One family can only hold one ration card across India.',
      ),
    ],
    documents: [
      'Family Group Photo',
      'Aadhaar of all members',
      'Residence Proof',
      'Bank Details'
    ],
    steps: [
      ProcessStep(title: 'Online Application', order: 1),
      ProcessStep(title: 'Field Verification', order: 2),
      ProcessStep(title: 'E-Ration Generation', order: 3),
    ],
  ),
  GovernmentService(
    id: 'kisan',
    title: 'PM-KISAN Subsidy',
    description: 'Direct income support of ₹6,000 per year to farmer families.',
    icon: Icons.agriculture_rounded,
    color: Colors.brown,
    eligibilityRules: [
      EligibilityRule(
        question: 'Do you own cultivable land?',
        parameter: 'owns_land',
        operator: RuleOperator.equalTo,
        value: true,
        explanation: 'Land ownership is mandatory for PM-KISAN benefits.',
      ),
    ],
    documents: [
      'Land Records (Jamabandi)',
      'Aadhaar Card',
      'Bank Account Number'
    ],
    steps: [
      ProcessStep(title: 'Portal Registration', order: 1),
      ProcessStep(title: 'Physical Verification', order: 2),
      ProcessStep(title: 'Benefit Transfer', order: 3),
    ],
  ),
  GovernmentService(
    id: 'scholarship',
    title: 'Student Scholarship',
    description: 'Merit-cum-means financial aid for students.',
    icon: Icons.school_rounded,
    color: Colors.blue,
    eligibilityRules: [
      EligibilityRule(
        question: 'Are you currently enrolled in a recognized institution?',
        parameter: 'enrolled',
        operator: RuleOperator.equalTo,
        value: true,
        explanation: 'Scholarships are only for active students.',
      ),
    ],
    documents: [
      'Marksheet of previous year',
      'Fee Receipt',
      'Caste Certificate (if applicable)',
      'Income Certificate'
    ],
    steps: [
      ProcessStep(title: 'NSP Registration', order: 1),
      ProcessStep(title: 'Institute Verification', order: 2),
      ProcessStep(title: 'Disbursement', order: 3),
    ],
  ),
  GovernmentService(
    id: 'health',
    title: 'Ayushman Bharat Card',
    description: 'Free healthcare coverage up to ₹5 Lakhs per family.',
    icon: Icons.medical_services_rounded,
    color: Colors.red,
    eligibilityRules: [
      EligibilityRule(
        question: 'Are you listed in the SECC 2011 database?',
        parameter: 'secc_listed',
        operator: RuleOperator.equalTo,
        value: true,
        explanation: 'Ayushman Bharat targets families identified in the SECC 2011 survey.',
      ),
    ],
    documents: [
      'PM Letter / Ration Card',
      'Aadhaar Card',
      'Family Identification'
    ],
    steps: [
      ProcessStep(title: 'Eligibility Check at Hospital', order: 1),
      ProcessStep(title: 'KYC Verification', order: 2),
      ProcessStep(title: 'Golden Card Issuance', order: 3),
    ],
  ),
];
