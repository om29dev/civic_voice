import 'package:flutter/material.dart';

class ServiceModel {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String category;
  final String officialWebsite;
  final List<String> requiredDocuments;
  final List<String> eligibilityCriteria;
  final String processingTime;
  final bool isOnlineAvailable;

  ServiceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    required this.officialWebsite,
    required this.requiredDocuments,
    required this.eligibilityCriteria,
    required this.processingTime,
    this.isOnlineAvailable = true,
  });

  static List<ServiceModel> getAllServices() {
    return [
      ServiceModel(
        id: 'aadhaar',
        title: 'Aadhaar Card',
        description: 'Unique identification number for Indian residents',
        icon: Icons.credit_card,
        color: const Color(0xFF667EEA),
        category: 'Identity',
        officialWebsite: 'https://uidai.gov.in',
        requiredDocuments: ['Proof of Identity', 'Proof of Address', 'Date of Birth Proof'],
        eligibilityCriteria: ['Indian Resident', 'Any Age'],
        processingTime: '90 days',
        isOnlineAvailable: true,
      ),
      ServiceModel(
        id: 'pan',
        title: 'PAN Card',
        description: 'Permanent Account Number for tax purposes',
        icon: Icons.contact_page,
        color: const Color(0xFF764BA2),
        category: 'Finance',
        officialWebsite: 'https://www.onlineservices.nsdl.com/paam/endUserRegisterContact.html',
        requiredDocuments: ['Identity Proof', 'Address Proof', 'Date of Birth Proof', 'Photograph'],
        eligibilityCriteria: ['Indian Citizen or Foreign National', 'Required for Income Tax'],
        processingTime: '15-20 days',
        isOnlineAvailable: true,
      ),
      ServiceModel(
        id: 'ration',
        title: 'Ration Card',
        description: 'Access subsidized food grains and essentials',
        icon: Icons.receipt_long,
        color: const Color(0xFF00FF9D),
        category: 'Food Security',
        officialWebsite: 'https://nfsa.gov.in',
        requiredDocuments: ['Aadhaar Card', 'Address Proof', 'Income Certificate', 'Family Photo'],
        eligibilityCriteria: ['Below Poverty Line', 'Annual Income < ₹1,00,000'],
        processingTime: '30 days',
        isOnlineAvailable: true,
      ),
      ServiceModel(
        id: 'pension',
        title: 'Senior Citizen Pension',
        description: 'Monthly pension for senior citizens',
        icon: Icons.elderly,
        color: const Color(0xFFFFD166),
        category: 'Social Welfare',
        officialWebsite: 'https://nsap.nic.in',
        requiredDocuments: ['Aadhaar Card', 'Age Proof', 'Bank Account Details', 'Income Certificate'],
        eligibilityCriteria: ['Age 60+', 'Below Poverty Line'],
        processingTime: '45 days',
        isOnlineAvailable: true,
      ),
      ServiceModel(
        id: 'birth',
        title: 'Birth Certificate',
        description: 'Official birth registration certificate',
        icon: Icons.child_care,
        color: const Color(0xFF00D4FF),
        category: 'Civil Registration',
        officialWebsite: 'https://crsorgi.gov.in',
        requiredDocuments: ['Hospital Birth Certificate', 'Parents Aadhaar', 'Address Proof'],
        eligibilityCriteria: ['Birth in India', 'Within 21 days of birth'],
        processingTime: '7-15 days',
        isOnlineAvailable: true,
      ),
      ServiceModel(
        id: 'land',
        title: 'Land Records',
        description: 'View and download land ownership records',
        icon: Icons.landscape,
        color: const Color(0xFF00FFE0),
        category: 'Property',
        officialWebsite: 'https://bhulekh.gov.in',
        requiredDocuments: ['Property Documents', 'Aadhaar Card', 'Survey Number'],
        eligibilityCriteria: ['Land Owner', 'Legal Heir'],
        processingTime: 'Instant',
        isOnlineAvailable: true,
      ),
      ServiceModel(
        id: 'passport',
        title: 'Passport',
        description: 'Apply for Indian passport',
        icon: Icons.flight,
        color: const Color(0xFFFF6B6B),
        category: 'Travel',
        officialWebsite: 'https://www.passportindia.gov.in',
        requiredDocuments: ['Aadhaar', 'Birth Certificate', 'Address Proof', 'Photographs'],
        eligibilityCriteria: ['Indian Citizen', 'Any Age'],
        processingTime: '30-45 days',
        isOnlineAvailable: true,
      ),
      ServiceModel(
        id: 'driving',
        title: 'Driving License',
        description: 'Apply for or renew driving license',
        icon: Icons.directions_car,
        color: const Color(0xFF9C27B0),
        category: 'Transport',
        officialWebsite: 'https://parivahan.gov.in',
        requiredDocuments: ['Aadhaar', 'Address Proof', 'Age Proof', 'Medical Certificate'],
        eligibilityCriteria: ['Age 18+ for Car', 'Age 16+ for Two-Wheeler'],
        processingTime: '30 days',
        isOnlineAvailable: true,
      ),
    ];
  }

  static List<String> getCategories() {
    return [
      'All',
      'Identity',
      'Finance',
      'Food Security',
      'Social Welfare',
      'Civil Registration',
      'Property',
      'Travel',
      'Transport',
    ];
  }
}
