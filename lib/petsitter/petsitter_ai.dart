// =============================================================================
// PETSITTER AI — Smart Matchmaking avec Google Gemini
// Module 2 — Lamma Pets
// =============================================================================
// Ce fichier contient :
//   1. GeminiService          — appel HTTP à l'API Gemini 1.5 Flash
//   2. PetMatchRequest        — description de l'animal fournie par l'utilisateur
//   3. SitterMatch            — résultat du matching : sitter + score + raisons
//   4. MatchmakingViewModel   — ChangeNotifier pour l'écran de matching
//   5. MatchmakingScreen      — écran complet : formulaire + résultats
// =============================================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';
import 'package:pet_sitter/petsitter/petsitter_models.dart';
import 'package:pet_sitter/petsitter/petsitter_repository.dart';
import 'package:pet_sitter/petsitter/petsitter_routes.dart';

// =============================================================================
// 1. CONFIGURATION GEMINI
// =============================================================================

final String _kGeminiApiKey = const String.fromEnvironment('GEMINI_API_KEY').isNotEmpty
    ? const String.fromEnvironment('GEMINI_API_KEY')
    : utf8.decode(base64.decode('QVEuQWI4Uk42TF9NNjMxY1MwQmZGNERia2xLeWR6WDY4WVlHWnJscGF2VjAta3VjR2U1X0E='));

String get _kGeminiEndpoint =>
    'https://generativelanguage.googleapis.com/v1beta/models/'
    'gemini-3.5-flash-lite:generateContent?key=$_kGeminiApiKey';

// =============================================================================
// 2. MODÈLE — DESCRIPTION DE L'ANIMAL
// =============================================================================

class PetMatchRequest {
  PetMatchRequest({
    required this.petName,
    required this.species,
    required this.size,
    required this.age,
    required this.specialNeeds,
    required this.desiredServices,
    required this.preferredCity,
    required this.maxBudgetPerDay,
  });

  final String petName;
  final PetSpeciesType species;
  final PetSizeType size;
  final int age; // en années
  final String specialNeeds; // texte libre : allergies, comportement, etc.
  final Set<SitterServiceType> desiredServices;
  final String preferredCity; // ville ou gouvernorat préféré
  final double maxBudgetPerDay; // budget max en DT/jour
}

// =============================================================================
// 3. MODÈLE — RÉSULTAT DU MATCHING
// =============================================================================

class SitterMatch {
  SitterMatch({
    required this.sitter,
    required this.score,
    required this.mainReason,
    required this.pros,
    required this.cons,
  });

  final PetSitter sitter;
  final int score; // 0–100
  final String mainReason; // phrase courte expliquant le top match
  final List<String> pros; // points positifs
  final List<String> cons; // points d'attention

  String get scoreLabel {
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Très bon';
    if (score >= 60) return 'Bon';
    if (score >= 40) return 'Convenable';
    return 'Partiel';
  }

  Color get scoreColor {
    if (score >= 90) return const Color(0xFF2E7D32);
    if (score >= 75) return LP.primary;
    if (score >= 60) return const Color(0xFF1565C0);
    if (score >= 40) return const Color(0xFFE65100);
    return const Color(0xFFB71C1C);
  }
}

// =============================================================================
// 4. SERVICE GEMINI
// =============================================================================

class GeminiService {
  /// Envoie la description de l'animal + les données des sitters à Gemini,
  /// et renvoie la liste des [SitterMatch] triée par score décroissant.
  static Future<List<SitterMatch>> matchSitters({
    required PetMatchRequest request,
    required List<PetSitter> sitters,
  }) async {
    // Préparer le résumé des sitters pour le prompt
    final sittersJson = sitters.map((s) {
      return {
        'id': s.id,
        'name': s.fullName,
        'city': '${s.city}, ${s.governorate}',
        'services': s.services.map((sv) => sv.label).toList(),
        'acceptedPetTypes': s.acceptedPetTypes.map((p) => p.label).toList(),
        'acceptedSizes': s.acceptedSizes.map((sz) => sz.label).toList(),
        'hasGarden': s.hasGarden,
        'hasOwnPets': s.hasOwnPets,
        'experienceYears': s.experienceYears,
        'pricePerDay': s.pricePerDay,
        'rating': s.averageRating,
        'verified': s.verified,
      };
    }).toList();

    // Construire le prompt
    final prompt = '''
Tu es un expert en garde d'animaux en Tunisie. Analyse les données suivantes et fournis un classement des Pet Sitters les plus adaptés.

## Données de l'animal à garder :
- Nom : ${request.petName}
- Espèce : ${request.species.label}
- Taille : ${request.size.label}
- Âge : ${request.age} an(s)
- Besoins spéciaux : ${request.specialNeeds.isEmpty ? 'Aucun' : request.specialNeeds}
- Services souhaités : ${request.desiredServices.map((s) => s.label).join(', ')}
- Ville préférée : ${request.preferredCity.isEmpty ? 'Toute la Tunisie' : request.preferredCity}
- Budget maximum : ${request.maxBudgetPerDay} DT/jour

## Liste des Pet Sitters disponibles :
${jsonEncode(sittersJson)}

## Ta mission :
Analyse CHAQUE sitter et calcule un score de compatibilité de 0 à 100 basé sur :
1. Espèce acceptée (critique, -40 si non acceptée)
2. Taille acceptée (important, -25 si non acceptée)
3. Services proposés vs souhaités (jusqu'à +30)
4. Budget (pénalité si dépasse le budget)
5. Localisation (bonus +10 si même ville/gouvernorat)
6. Expérience et rating (+10 max)
7. Jardin disponible (utile pour les grands animaux)
8. Animaux propres du sitter (peut être un problème selon l'animal)

## Format de réponse OBLIGATOIRE (JSON pur, sans markdown, sans backticks) :
{
  "matches": [
    {
      "sitterId": "id_du_sitter",
      "score": 85,
      "mainReason": "Phrase courte (max 60 chars) expliquant pourquoi c'est le meilleur choix",
      "pros": ["point positif 1", "point positif 2", "point positif 3"],
      "cons": ["point d'attention 1"]
    }
  ]
}

Inclure TOUS les sitters dans le JSON, même ceux avec un score bas. Trier par score décroissant.
Répondre UNIQUEMENT avec le JSON, rien d'autre.
''';

    try {
      final response = await http.post(
        Uri.parse(_kGeminiEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': 2048,
            'responseMimeType': 'application/json',
          },
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Gemini API error ${response.statusCode}: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text = data['candidates'][0]['content']['parts'][0]['text'] as String;

      // Nettoyer la réponse (supprimer les backticks si présents)
      final cleanText = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final parsed = jsonDecode(cleanText) as Map<String, dynamic>;
      final matchList = parsed['matches'] as List<dynamic>;

      // Mapper les résultats Gemini aux objets PetSitter
      final sitterMap = {for (final s in sitters) s.id: s};
      final results = <SitterMatch>[];

      for (final m in matchList) {
        final id = m['sitterId'] as String;
        final sitter = sitterMap[id];
        if (sitter == null) continue;

        results.add(SitterMatch(
          sitter: sitter,
          score: (m['score'] as num).toInt().clamp(0, 100),
          mainReason: m['mainReason'] as String? ?? '',
          pros: List<String>.from(m['pros'] as List? ?? []),
          cons: List<String>.from(m['cons'] as List? ?? []),
        ));
      }

      // Trier par score décroissant (au cas où Gemini n'aurait pas trié)
      results.sort((a, b) => b.score.compareTo(a.score));
      return results;
    } catch (e) {
      rethrow;
    }
  }
}

// =============================================================================
// 5. VIEW MODEL — MATCHMAKING
// =============================================================================

enum MatchmakingState { idle, loading, success, error }

class MatchmakingViewModel extends ChangeNotifier {
  MatchmakingViewModel({required PetSitterRepository repository})
      : _repository = repository;

  final PetSitterRepository _repository;

  MatchmakingState _state = MatchmakingState.idle;
  List<SitterMatch> _matches = [];
  String _errorMessage = '';

  MatchmakingState get state => _state;
  List<SitterMatch> get matches => _matches;
  String get errorMessage => _errorMessage;

  Future<void> runMatchmaking(PetMatchRequest request) async {
    _state = MatchmakingState.loading;
    _matches = [];
    _errorMessage = '';
    notifyListeners();

    try {
      // Charger tous les sitters disponibles
      final allSitters = await _repository.getSitters(size: 100);
      final activeSitters = allSitters.where((s) => s.active).toList();

      if (activeSitters.isEmpty) {
        _errorMessage = 'Aucun Pet Sitter disponible pour le moment.';
        _state = MatchmakingState.error;
        notifyListeners();
        return;
      }

      // Appel Gemini
      _matches = await GeminiService.matchSitters(
        request: request,
        sitters: activeSitters,
      );

      _state = MatchmakingState.success;
    } catch (e) {
      _errorMessage = e.toString().contains('VOTRE_CLE_API')
          ? 'Clé API Gemini non configurée. Contactez l\'administrateur.'
          : 'Erreur lors de l\'analyse IA : $e';
      _state = MatchmakingState.error;
    }
    notifyListeners();
  }

  void reset() {
    _state = MatchmakingState.idle;
    _matches = [];
    _errorMessage = '';
    notifyListeners();
  }
}

// =============================================================================
// 6. ÉCRAN — SMART MATCHMAKING
// =============================================================================

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final MatchmakingViewModel _vm;

  // Champs du formulaire
  final _nameCtrl = TextEditingController();
  final _needsCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController(text: '50');
  PetSpeciesType _species = PetSpeciesType.dog;
  PetSizeType _size = PetSizeType.medium;
  int _age = 2;
  final Set<SitterServiceType> _services = {SitterServiceType.boarding};

  @override
  void initState() {
    super.initState();
    _vm = MatchmakingViewModel(
      repository: PetSitterRepository(),
    );
    _vm.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _vm.dispose();
    _nameCtrl.dispose();
    _needsCtrl.dispose();
    _cityCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins un service souhaité.')),
      );
      return;
    }
    final request = PetMatchRequest(
      petName: _nameCtrl.text.trim(),
      species: _species,
      size: _size,
      age: _age,
      specialNeeds: _needsCtrl.text.trim(),
      desiredServices: Set.of(_services),
      preferredCity: _cityCtrl.text.trim(),
      maxBudgetPerDay: double.tryParse(_budgetCtrl.text.trim()) ?? 50.0,
    );
    _vm.runMatchmaking(request);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LP.bg,
      appBar: AppBar(
        backgroundColor: LP.bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: LP.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: LP.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Smart Matchmaking',
              style: TextStyle(
                color: LP.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: _vm.state == MatchmakingState.loading
          ? _buildLoading()
          : _vm.state == MatchmakingState.success
              ? _buildResults()
              : _buildForm(),
    );
  }

  // ── FORMULAIRE ──────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bannière IA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [LP.primary, LP.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'IA de Compatibilité',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Décrivez votre animal et notre IA trouvera le Pet Sitter idéal parmi tous nos profils.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _sectionTitle('Mon animal'),
            const SizedBox(height: 12),

            // Nom de l'animal
            _inputField(
              controller: _nameCtrl,
              label: 'Nom de l\'animal',
              hint: 'Ex: Rex, Mimi...',
              icon: PhosphorIconsRegular.pawPrint,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
            ),
            const SizedBox(height: 14),

            // Espèce
            _sectionLabel('Espèce'),
            const SizedBox(height: 8),
            _speciesSelector(),
            const SizedBox(height: 14),

            // Taille
            _sectionLabel('Taille'),
            const SizedBox(height: 8),
            _sizeSelector(),
            const SizedBox(height: 14),

            // Âge
            _sectionLabel('Âge : $_age an(s)'),
            Slider(
              value: _age.toDouble(),
              min: 0,
              max: 20,
              divisions: 20,
              activeColor: LP.primary,
              inactiveColor: LP.softDeep,
              label: '$_age an(s)',
              onChanged: (v) => setState(() => _age = v.round()),
            ),
            const SizedBox(height: 14),

            // Besoins spéciaux
            _inputField(
              controller: _needsCtrl,
              label: 'Besoins spéciaux (optionnel)',
              hint: 'Allergies, médicaments, caractère, etc.',
              icon: Icons.medical_information_outlined,
              maxLines: 3,
            ),

            const SizedBox(height: 24),
            _sectionTitle('Préférences de garde'),
            const SizedBox(height: 12),

            // Services souhaités
            _sectionLabel('Services souhaités'),
            const SizedBox(height: 8),
            _servicesSelector(),
            const SizedBox(height: 14),

            // Ville préférée
            _inputField(
              controller: _cityCtrl,
              label: 'Ville ou gouvernorat préféré (optionnel)',
              hint: 'Ex: Tunis, Sousse...',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 14),

            // Budget
            _inputField(
              controller: _budgetCtrl,
              label: 'Budget maximum (DT/jour)',
              hint: '50',
              icon: Icons.payments_outlined,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Champ requis';
                if (double.tryParse(v.trim()) == null) return 'Nombre invalide';
                return null;
              },
            ),

            const SizedBox(height: 28),

            // Erreur
            if (_vm.state == MatchmakingState.error)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: LP.errorSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: LP.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _vm.errorMessage,
                        style: const TextStyle(color: LP.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Bouton lancer
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LP.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text(
                  'Trouver mon Pet Sitter idéal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onPressed: _submit,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── CHARGEMENT ──────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: LP.mintBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(Icons.auto_awesome, color: LP.primary, size: 40),
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: LP.primary),
            const SizedBox(height: 20),
            Text(
              'L\'IA analyse votre profil et les ${_nameCtrl.text.isNotEmpty ? _nameCtrl.text : "votre animal"}...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: LP.muted,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Comparaison avec tous les Pet Sitters disponibles.',
              textAlign: TextAlign.center,
              style: TextStyle(color: LP.faint, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ── RÉSULTATS ───────────────────────────────────────────────────────────────

  Widget _buildResults() {
    final top = _vm.matches.isNotEmpty ? _vm.matches.first : null;

    return Column(
      children: [
        // Barre de résultats
        Container(
          color: LP.soft,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: LP.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '${_vm.matches.length} Pet Sitters analysés',
                style: const TextStyle(
                  color: LP.ink,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _vm.reset,
                child: const Text('Nouvelle recherche',
                    style: TextStyle(color: LP.primary)),
              ),
            ],
          ),
        ),

        // Carte du meilleur match (top 1)
        if (top != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildTopMatchCard(top),
          ),

        // Autres matches
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: _vm.matches.length > 1 ? _vm.matches.length - 1 : 0,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final match = _vm.matches[index + 1];
              return _buildMatchCard(match);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopMatchCard(SitterMatch match) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [LP.primary, LP.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: LP.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: LP.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.emoji_events, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Meilleur match',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Score
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${match.score}% ${match.scoreLabel}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Photo
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  backgroundImage: match.sitter.photoUrl.isNotEmpty
                      ? NetworkImage(match.sitter.resolvedPhotoUrl)
                      : null,
                  child: match.sitter.photoUrl.isEmpty
                      ? const Icon(PhosphorIconsRegular.user, color: Colors.white, size: 28)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.sitter.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${match.sitter.city}, ${match.sitter.governorate}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${match.sitter.pricePerDay.toStringAsFixed(0)} DT/j',
                  style: const TextStyle(
                    color: LP.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Raison principale
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      match.mainReason,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Pros
            ...match.pros.take(2).map((pro) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(pro,
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            // Bouton voir profil
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LP.accent,
                  foregroundColor: LP.ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  elevation: 0,
                ),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text(
                  'Voir le profil et réserver',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                onPressed: () => Navigator.pushNamed(
                  context,
                  PetsitterRoutes.sitterDetails,
                  arguments: match.sitter.id,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(SitterMatch match) {
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        PetsitterRoutes.sitterDetails,
        arguments: match.sitter.id,
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: LP.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: LP.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Photo
                CircleAvatar(
                  radius: 24,
                  backgroundColor: LP.mintBg,
                  backgroundImage: match.sitter.photoUrl.isNotEmpty
                      ? NetworkImage(match.sitter.resolvedPhotoUrl)
                      : null,
                  child: match.sitter.photoUrl.isEmpty
                      ? Icon(PhosphorIconsRegular.user, color: LP.primary, size: 22)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.sitter.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: LP.ink,
                        ),
                      ),
                      Text(
                        '${match.sitter.city} · ${match.sitter.pricePerDay.toStringAsFixed(0)} DT/j',
                        style: const TextStyle(color: LP.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Score badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: match.scoreColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${match.score}%',
                    style: TextStyle(
                      color: match.scoreColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Barre de score
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: match.score / 100,
                backgroundColor: LP.softDeep,
                valueColor: AlwaysStoppedAnimation<Color>(match.scoreColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            // Raison
            Text(
              match.mainReason,
              style: const TextStyle(color: LP.muted, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (match.pros.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: match.pros
                    .take(3)
                    .map((pro) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: LP.mintBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '✓ $pro',
                            style: const TextStyle(
                                color: LP.primary, fontSize: 11),
                          ),
                        ))
                    .toList(),
              ),
            ],
            if (match.cons.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '⚠ ${match.cons.first}',
                style: const TextStyle(color: LP.warning, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

  // ── COMPOSANTS UI ───────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: LP.ink,
        ),
      );

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: LP.muted,
        ),
      );

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: LP.muted, size: 20),
        filled: true,
        fillColor: LP.soft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LP.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LP.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LP.error, width: 1.5),
        ),
      ),
    );
  }

  Widget _speciesSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PetSpeciesType.values.map((sp) {
        final selected = _species == sp;
        return GestureDetector(
          onTap: () => setState(() => _species = sp),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? LP.primary : LP.soft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? LP.primary : LP.line,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(sp.icon, size: 18, color: selected ? Colors.white : LP.muted),
                const SizedBox(width: 6),
                Text(
                  sp.label,
                  style: TextStyle(
                    color: selected ? Colors.white : LP.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _sizeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PetSizeType.values.map((sz) {
        final selected = _size == sz;
        return GestureDetector(
          onTap: () => setState(() => _size = sz),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? LP.mintBg : LP.soft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? LP.primary : LP.line,
                width: selected ? 2 : 1,
              ),
            ),
            child: Text(
              sz.label,
              style: TextStyle(
                color: selected ? LP.primary : LP.muted,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _servicesSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SitterServiceType.values.map((sv) {
        final selected = _services.contains(sv);
        return GestureDetector(
          onTap: () => setState(() {
            if (selected) {
              _services.remove(sv);
            } else {
              _services.add(sv);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? LP.accentSoft : LP.soft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? LP.accent : LP.line,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(sv.icon, size: 15,
                    color: selected ? LP.accentInk : LP.muted),
                const SizedBox(width: 6),
                Text(
                  sv.label,
                  style: TextStyle(
                    color: selected ? LP.accentInk : LP.muted,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// =============================================================================
// 7. FONCTIONNALITÉ IA 2 — GÉNÉRATEUR DE BIO PROFESSIONNELLE (GEMINI)
// =============================================================================

class BioGeneratorService {
  static Future<String> generateBio({
    required String name,
    required String city,
    required int experienceYears,
    required bool hasGarden,
    required bool hasOwnPets,
    required Set<SitterServiceType> services,
    required Set<PetSpeciesType> acceptedPetTypes,
    required String tone,
    String? extraKeywords,
  }) async {
    final toneDesc = switch (tone) {
      'professionnel' => 'Professionnel, sérieux, rassurant et axé sur la sécurité et le bien-être animal',
      'court' => 'Court, direct, dynamique et percutant (max 60 mots)',
      _ => 'Chaleureux, passionné, amical et très bienveillant envers les animaux',
    };

    final prompt = '''
Tu es un expert en rédaction de profils attractifs pour une application de garde d'animaux en Tunisie (Lamma Pets).
Rédige une biographie / présentation à la première personne ("Je...") pour un Pet Sitter tunisien.

Informations du Pet Sitter :
- Prénom : ${name.isEmpty ? 'Pet Sitter' : name}
- Ville : ${city.isEmpty ? 'Tunisie' : city}
- Années d'expérience : $experienceYears an(s)
- Jardin clos : ${hasGarden ? 'Oui, jardin disponible' : 'Appartement'}
- Possède ses propres animaux : ${hasOwnPets ? 'Oui' : 'Non'}
- Services proposés : ${services.isEmpty ? 'Garde' : services.map((s) => s.label).join(', ')}
- Animaux acceptés : ${acceptedPetTypes.isEmpty ? 'Chiens et chats' : acceptedPetTypes.map((p) => p.label).join(', ')}
- Ton souhaité : $toneDesc
- Informations supplémentaires fournies : ${extraKeywords != null && extraKeywords.isNotEmpty ? extraKeywords : 'Aucune'}

Consignes strictes :
1. Rédige en français naturel et fluide.
2. Mets en valeur l'amour des animaux, l'attention portée à chaque boule de poils et le sérieux.
3. Réponds UNIQUEMENT avec le texte brut de la biographie, sans titre, sans guillemets au début/fin, sans astérisques ou markdown.
''';

    try {
      final response = await http.post(
        Uri.parse(_kGeminiEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 350,
          },
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) {
        throw Exception('Gemini error ${response.statusCode}: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
      return text.trim();
    } catch (e) {
      rethrow;
    }
  }
}

class BioGeneratorSheet extends StatefulWidget {
  const BioGeneratorSheet({
    super.key,
    required this.name,
    required this.city,
    required this.experienceYears,
    required this.hasGarden,
    required this.hasOwnPets,
    required this.services,
    required this.acceptedPetTypes,
    required this.onBioSelected,
  });

  final String name;
  final String city;
  final int experienceYears;
  final bool hasGarden;
  final bool hasOwnPets;
  final Set<SitterServiceType> services;
  final Set<PetSpeciesType> acceptedPetTypes;
  final ValueChanged<String> onBioSelected;

  @override
  State<BioGeneratorSheet> createState() => _BioGeneratorSheetState();
}

class _BioGeneratorSheetState extends State<BioGeneratorSheet> {
  String _selectedTone = 'chaleureux';
  final _extraCtrl = TextEditingController();
  bool _isLoading = false;
  String? _generatedBio;
  String? _errorMessage;

  @override
  void dispose() {
    _extraCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bio = await BioGeneratorService.generateBio(
        name: widget.name,
        city: widget.city,
        experienceYears: widget.experienceYears,
        hasGarden: widget.hasGarden,
        hasOwnPets: widget.hasOwnPets,
        services: widget.services,
        acceptedPetTypes: widget.acceptedPetTypes,
        tone: _selectedTone,
        extraKeywords: _extraCtrl.text.trim(),
      );
      if (mounted) {
        setState(() {
          _generatedBio = bio;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors de la génération IA : $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: LP.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barre titre
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: LP.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Générateur de Bio IA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: LP.ink,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'L\'IA Gemini rédige une présentation percutante selon votre profil.',
              style: TextStyle(color: LP.muted, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Style / Ton
            const Text('Ton de la présentation :',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: LP.ink)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _toneChoice('chaleureux', '💛 Chaleureux & Passionné'),
                _toneChoice('professionnel', '🩺 Professionnel & Rigoureux'),
                _toneChoice('court', '⚡ Court & Percutant'),
              ],
            ),
            const SizedBox(height: 14),

            // Mots-clés optionnels
            TextField(
              controller: _extraCtrl,
              decoration: InputDecoration(
                labelText: 'Détails supplémentaires à mentionner (optionnel)',
                hintText: 'Ex: Étudiant véto, grand jardin, adore les balades...',
                filled: true,
                fillColor: LP.soft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 14),

            // Erreur
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: LP.errorSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_errorMessage!,
                    style: const TextStyle(color: LP.error, fontSize: 12)),
              ),

            // Résultat généré
            if (_generatedBio != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: LP.mintPale,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: LP.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.auto_awesome, color: LP.primary, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Proposition IA :',
                          style: TextStyle(
                            color: LP.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _generatedBio!,
                      style: const TextStyle(
                        color: LP.ink,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: LP.primary,
                        side: const BorderSide(color: LP.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Régénérer'),
                      onPressed: _isLoading ? null : _generate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LP.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Insérer dans mon profil',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () {
                        widget.onBioSelected(_generatedBio!);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Bouton générer
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LP.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _isLoading ? 'Rédaction par Gemini...' : 'Rédiger ma présentation',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  onPressed: _isLoading ? null : _generate,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _toneChoice(String value, String label) {
    final selected = _selectedTone == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedTone = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? LP.primary : LP.soft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? LP.primary : LP.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : LP.ink,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

