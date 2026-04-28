class Intent {
  final String id;
  final String companyId;
  final String name;
  final String? description;
  final List<String> trainingPhrases;
  final String response;
  final String category;
  final bool isActive;
  final int matchCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Intent({
    required this.id,
    required this.companyId,
    required this.name,
    this.description,
    required this.trainingPhrases,
    required this.response,
    this.category = 'general',
    this.isActive = true,
    this.matchCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Intent.fromJson(Map<String, dynamic> j) => Intent(
    id: j['id'],
    companyId: j['company_id'],
    name: j['name'],
    description: j['description'],
    trainingPhrases: List<String>.from(j['training_phrases'] ?? []),
    response: j['response'] ?? '',
    category: j['category'] ?? 'general',
    isActive: j['is_active'] ?? true,
    matchCount: j['match_count'] ?? 0,
    createdAt: DateTime.parse(j['created_at']),
    updatedAt: DateTime.parse(j['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'company_id': companyId,
    'name': name,
    'description': description,
    'training_phrases': trainingPhrases,
    'response': response,
    'category': category,
    'is_active': isActive,
  };
}
