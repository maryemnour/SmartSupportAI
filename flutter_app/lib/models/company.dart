import 'package:flutter/material.dart';

class Company {
  final String id;
  final String name;
  final String? logoUrl;
  final String primaryColor;
  final String welcomeMessage;
  final String? supportEmail;
  final String? whatsappNumber;
  final String? apiKey;
  final String plan;
  final bool isActive;
  final String? botPersonality;
  final DateTime createdAt;

  const Company({
    required this.id,
    required this.name,
    this.logoUrl,
    this.primaryColor = '#6366F1',
    this.welcomeMessage = 'Hello! How can I help you today?',
    this.supportEmail,
    this.whatsappNumber,
    this.apiKey,
    this.plan = 'free',
    this.isActive = true,
    this.botPersonality = 'friendly',
    required this.createdAt,
  });

  Color get color {
    try {
      return Color(int.parse('FF${primaryColor.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  factory Company.fromJson(Map<String, dynamic> j) => Company(
    id: j['id'],
    name: j['name'],
    logoUrl: j['logo_url'],
    primaryColor: j['primary_color'] ?? '#6366F1',
    welcomeMessage: j['welcome_message'] ?? 'Hello! How can I help you today?',
    supportEmail: j['support_email'],
    whatsappNumber: j['whatsapp_number'],
    apiKey: j['api_key'],
    plan: j['plan'] ?? 'free',
    isActive: j['is_active'] ?? true,
    botPersonality: j['bot_personality'] ?? 'friendly',
    createdAt: DateTime.parse(j['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'logo_url': logoUrl,
    'primary_color': primaryColor,
    'welcome_message': welcomeMessage,
    'support_email': supportEmail,
    'whatsapp_number': whatsappNumber,
    'api_key': apiKey,
    'plan': plan,
    'is_active': isActive,
    'bot_personality': botPersonality,
    'created_at': createdAt.toIso8601String(),
  };
}
