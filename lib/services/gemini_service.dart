import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/soil_log.dart';

/// ============================================================
/// AI AGRONOMIST & DISEASE ASSISTANT (Bring-Your-Own-Key)
/// ------------------------------------------------------------
/// The farmer supplies their own free Gemini API key, stored only
/// in the device's secure keystore/keychain — it never touches
/// Supabase or any Shamba Smart server. This keeps the AI feature
/// usable at zero infrastructure cost to Farmers Hope.
///
/// Two modes:
///  • askText()  — conversational agronomy advice, automatically
///                 grounded with the farmer's most recent SoilLog.
///  • askWithImage() — multi-modal crop/leaf disease diagnosis.
/// ============================================================
class GeminiService {
  GeminiService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _keyStorageKey = 'gemini_api_key';
  final FlutterSecureStorage _storage;

  Future<void> saveApiKey(String apiKey) =>
      _storage.write(key: _keyStorageKey, value: apiKey.trim());

  Future<String?> getApiKey() => _storage.read(key: _keyStorageKey);

  Future<void> clearApiKey() => _storage.delete(key: _keyStorageKey);

  Future<bool> get hasApiKey async => (await getApiKey())?.isNotEmpty ?? false;

  GenerativeModel _model(String apiKey, {bool vision = false}) {
    return GenerativeModel(
      model: vision ? 'gemini-1.5-flash' : 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(temperature: 0.4, maxOutputTokens: 800),
    );
  }

  String _systemContext(SoilLog? latest) {
    final buffer = StringBuffer(
      'You are the Shamba Smart AI Agronomist, helping a smallholder '
      'farmer in Tanzania. Reply in clear, practical Swahili unless the '
      'farmer writes in English. Keep advice short, actionable, and safe '
      '(no unverified pesticide dosages). ',
    );
    if (latest != null) {
      buffer.write(
        'Latest sensor reading — moisture: ${latest.soilMoisture.toStringAsFixed(1)}%, '
        'pH: ${latest.ph.toStringAsFixed(1)}, EC: ${latest.ec.toStringAsFixed(2)} mS/cm, '
        'temperature: ${latest.temperature.toStringAsFixed(1)}°C, '
        'humidity: ${latest.humidity.toStringAsFixed(1)}%. '
        'Use this context if the question relates to irrigation or soil health.',
      );
    }
    return buffer.toString();
  }

  /// Text-only Q&A, grounded with recent soil telemetry when available.
  Future<String> askText({
    required String prompt,
    SoilLog? latestSoilLog,
    List<Content> history = const [],
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw GeminiKeyMissingException();
    }

    final model = _model(apiKey);
    final chat = model.startChat(history: [
      Content.text(_systemContext(latestSoilLog)),
      ...history,
    ]);
    final response = await chat.sendMessage(Content.text(prompt));
    return response.text ?? 'Samahani, sikuweza kupata jibu. Jaribu tena.';
  }

  /// Multi-modal crop/leaf photo diagnosis.
  Future<String> askWithImage({
    required File imageFile,
    String prompt = 'Angalia picha hii ya zao/jani na tambua kama kuna '
        'dalili za ugonjwa au wadudu. Toa ushauri mfupi wa hatua za kuchukua.',
    SoilLog? latestSoilLog,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw GeminiKeyMissingException();
    }

    final Uint8List bytes = await imageFile.readAsBytes();
    final model = _model(apiKey, vision: true);
    final content = Content.multi([
      TextPart(_systemContext(latestSoilLog)),
      TextPart(prompt),
      DataPart('image/jpeg', bytes),
    ]);

    final response = await model.generateContent([content]);
    return response.text ?? 'Samahani, sikuweza kuchambua picha hiyo.';
  }
}

class GeminiKeyMissingException implements Exception {
  @override
  String toString() =>
      'No Gemini API key configured. Add one from AI Advisor > Settings.';
}
