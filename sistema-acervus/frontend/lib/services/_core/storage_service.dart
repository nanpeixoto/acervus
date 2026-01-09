import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;

  // Inicializar
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Garantir que está inicializado
  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<bool> saveTokenRaw(String token) async {
    return setString('auth_token', token);
  }

  static Future<bool> saveUserData(Map<String, dynamic> userData) async {
    return setJson('user_data', userData);
  }

  static Future<void> clearAllData() async {
    final prefs = await _instance;
    await prefs.clear();
  }

  // STRING METHODS
  static Future<bool> setString(String key, String value) async {
    final prefs = await _instance;
    return prefs.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    final prefs = await _instance;
    return prefs.getString(key);
  }

  // INT METHODS
  static Future<bool> setInt(String key, int value) async {
    final prefs = await _instance;
    return prefs.setInt(key, value);
  }

  static Future<int?> getInt(String key) async {
    final prefs = await _instance;
    return prefs.getInt(key);
  }

  // DOUBLE METHODS
  static Future<bool> setDouble(String key, double value) async {
    final prefs = await _instance;
    return prefs.setDouble(key, value);
  }

  static Future<double?> getDouble(String key) async {
    final prefs = await _instance;
    return prefs.getDouble(key);
  }

  // BOOL METHODS
  static Future<bool> setBool(String key, bool value) async {
    final prefs = await _instance;
    return prefs.setBool(key, value);
  }

  static Future<bool?> getBool(String key) async {
    final prefs = await _instance;
    return prefs.getBool(key);
  }

  // LIST METHODS
  static Future<bool> setStringList(String key, List<String> value) async {
    final prefs = await _instance;
    return prefs.setStringList(key, value);
  }

  static Future<List<String>?> getStringList(String key) async {
    final prefs = await _instance;
    return prefs.getStringList(key);
  }

  // JSON METHODS
  static Future<bool> setJson(String key, Map<String, dynamic> value) async {
    final jsonString = jsonEncode(value);
    return setString(key, jsonString);
  }

  static Future<Map<String, dynamic>?> getJson(String key) async {
    final jsonString = await getString(key);
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // REMOVE METHODS
  static Future<bool> remove(String key) async {
    final prefs = await _instance;
    return prefs.remove(key);
  }

  static Future<bool> clear() async {
    final prefs = await _instance;
    return prefs.clear();
  }

  // CHECK IF KEY EXISTS
  static Future<bool> containsKey(String key) async {
    final prefs = await _instance;
    return prefs.containsKey(key);
  }

  // GET ALL KEYS
  static Future<Set<String>> getAllKeys() async {
    final prefs = await _instance;
    return prefs.getKeys();
  }

  // AUTH SPECIFIC METHODS
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';

  // Token methods
  static Future<bool> setToken(String token) async {
    return setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    return getString(_tokenKey);
  }

  static Future<bool> removeToken() async {
    return remove(_tokenKey);
  }

  // Refresh token methods
  static Future<bool> setRefreshToken(String refreshToken) async {
    return setString(_refreshTokenKey, refreshToken);
  }

  static Future<String?> getRefreshToken() async {
    return getString(_refreshTokenKey);
  }

  static Future<bool> removeRefreshToken() async {
    return remove(_refreshTokenKey);
  }

  // User data methods
  static Future<bool> setUserData(Map<String, dynamic> userData) async {
    return setJson(_userDataKey, userData);
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    return getJson(_userDataKey);
  }

  static Future<bool> removeUserData() async {
    return remove(_userDataKey);
  }

  // THEME SPECIFIC METHODS
  static const String _themeKey = 'theme_mode';
  static const String _highContrastKey = 'high_contrast';
  static const String _fontSizeKey = 'font_size';

  static Future<bool> setThemeMode(int mode) async {
    return setInt(_themeKey, mode);
  }

  static Future<int?> getThemeMode() async {
    return getInt(_themeKey);
  }

  static Future<bool> setHighContrast(bool value) async {
    return setBool(_highContrastKey, value);
  }

  static Future<bool?> getHighContrast() async {
    return getBool(_highContrastKey);
  }

  static Future<bool> setFontSize(double size) async {
    return setDouble(_fontSizeKey, size);
  }

  static Future<double?> getFontSize() async {
    return getDouble(_fontSizeKey);
  }

  // CACHE METHODS
  static const String _cachePrefix = 'cache_';
  static const String _cacheTimestampPrefix = 'cache_ts_';

  static Future<bool> setCache(String key, dynamic value,
      {Duration? expiry}) async {
    final cacheKey = '$_cachePrefix$key';
    final timestampKey = '$_cacheTimestampPrefix$key';

    // Salvar timestamp se tiver expiração
    if (expiry != null) {
      final expiryTime = DateTime.now().add(expiry).millisecondsSinceEpoch;
      await setInt(timestampKey, expiryTime);
    }

    // Salvar dados baseado no tipo
    if (value is String) {
      return setString(cacheKey, value);
    } else if (value is int) {
      return setInt(cacheKey, value);
    } else if (value is double) {
      return setDouble(cacheKey, value);
    } else if (value is bool) {
      return setBool(cacheKey, value);
    } else if (value is List<String>) {
      return setStringList(cacheKey, value);
    } else if (value is Map<String, dynamic>) {
      return setJson(cacheKey, value);
    } else {
      // Tentar serializar como JSON
      return setJson(cacheKey, {'data': value});
    }
  }

  static Future<T?> getCache<T>(String key) async {
    final cacheKey = '$_cachePrefix$key';
    final timestampKey = '$_cacheTimestampPrefix$key';

    // Verificar se expirou
    final timestamp = await getInt(timestampKey);
    if (timestamp != null) {
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().isAfter(expiryTime)) {
        // Cache expirado, remover
        await remove(cacheKey);
        await remove(timestampKey);
        return null;
      }
    }

    // Tentar obter baseado no tipo
    if (T == String) {
      return await getString(cacheKey) as T?;
    } else if (T == int) {
      return await getInt(cacheKey) as T?;
    } else if (T == double) {
      return await getDouble(cacheKey) as T?;
    } else if (T == bool) {
      return await getBool(cacheKey) as T?;
    } else if (T == List<String>) {
      return await getStringList(cacheKey) as T?;
    } else {
      // Tentar como JSON
      final json = await getJson(cacheKey);
      if (json != null) {
        if (json.containsKey('data')) {
          return json['data'] as T?;
        }
        return json as T?;
      }
      return null;
    }
  }

  static Future<bool> removeCache(String key) async {
    final cacheKey = '$_cachePrefix$key';
    final timestampKey = '$_cacheTimestampPrefix$key';

    await remove(timestampKey);
    return remove(cacheKey);
  }

  static Future<void> clearCache() async {
    final keys = await getAllKeys();
    final cacheKeys = keys
        .where((key) =>
            key.startsWith(_cachePrefix) ||
            key.startsWith(_cacheTimestampPrefix))
        .toList();

    for (final key in cacheKeys) {
      await remove(key);
    }
  }

  // APP SETTINGS METHODS
  static const String _onboardingKey = 'onboarding_completed';
  static const String _languageKey = 'app_language';
  static const String _notificationsKey = 'notifications_enabled';

  static Future<bool> setOnboardingCompleted(bool completed) async {
    return setBool(_onboardingKey, completed);
  }

  static Future<bool?> getOnboardingCompleted() async {
    return getBool(_onboardingKey);
  }

  static Future<bool> setLanguage(String language) async {
    return setString(_languageKey, language);
  }

  static Future<String?> getLanguage() async {
    return getString(_languageKey);
  }

  static Future<bool> setNotificationsEnabled(bool enabled) async {
    return setBool(_notificationsKey, enabled);
  }

  static Future<bool?> getNotificationsEnabled() async {
    return getBool(_notificationsKey);
  }

  // UTILITY METHODS
  static Future<void> clearUserSession() async {
    await removeToken();
    await removeRefreshToken();
    await removeUserData();
  }

  static Future<void> clearAppData() async {
    await clear();
  }

  static Future<Map<String, dynamic>> getStorageInfo() async {
    final keys = await getAllKeys();
    final prefs = await _instance;

    int totalKeys = keys.length;
    int authKeys = 0;
    int cacheKeys = 0;
    int settingsKeys = 0;

    for (final key in keys) {
      if (key.startsWith(_cachePrefix) ||
          key.startsWith(_cacheTimestampPrefix)) {
        cacheKeys++;
      } else if ([_tokenKey, _refreshTokenKey, _userDataKey].contains(key)) {
        authKeys++;
      } else {
        settingsKeys++;
      }
    }

    return {
      'totalKeys': totalKeys,
      'authKeys': authKeys,
      'cacheKeys': cacheKeys,
      'settingsKeys': settingsKeys,
      'allKeys': keys.toList(),
    };
  }

  // DEBUG METHODS (apenas para desenvolvimento)
  static Future<void> printAllData() async {
    if (const bool.fromEnvironment('dart.vm.product')) {
      return; // Não executar em produção
    }

    final keys = await getAllKeys();
    final prefs = await _instance;

    print('=== STORAGE DATA ===');
    for (final key in keys) {
      final value = prefs.get(key);
      print('$key: $value');
    }
    print('===================');
  }

  /// Salva o token de autenticação
  /// Wrapper para o método setToken existente
  static Future<bool> saveToken(String token) async {
    return setToken(token);
  }

  /// Salva os dados do usuário
  /// Wrapper para o método setUserData existente
  /// Aceita um Map<String, dynamic> (resultado do toJson())
  static Future<bool> saveUserDataWrapper(Map<String, dynamic> userData) async {
    return setUserData(userData);
  }

  /// Limpa todos os dados do storage
  /// Wrapper para o método clear existente
  static Future<bool> clearAll() async {
    return clear();
  }

// MÉTODOS COMPLEMENTARES (opcionais)
// ==================================

  /// Verifica se existe um token salvo
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Verifica se existem dados do usuário salvos
  static Future<bool> hasUserData() async {
    final userData = await getUserData();
    return userData != null && userData.isNotEmpty;
  }

  /// Verifica se o usuário está autenticado (tem token e dados)
  static Future<bool> isAuthenticated() async {
    final hasTokenResult = await hasToken();
    final hasUserDataResult = await hasUserData();
    return hasTokenResult && hasUserDataResult;
  }

  /// Limpa apenas os dados de autenticação (token e dados do usuário)
  /// Mantém outras configurações como tema, cache, etc.
  static Future<void> clearAuthData() async {
    await removeToken();
    await removeRefreshToken();
    await removeUserData();
  }

  /// Obtém o token salvo (alias para getToken)
  static Future<String?> loadToken() async {
    return getToken();
  }

  /// Obtém os dados do usuário salvos (alias para getUserData)
  static Future<Map<String, dynamic>?> loadUserData() async {
    return getUserData();
  }
}
