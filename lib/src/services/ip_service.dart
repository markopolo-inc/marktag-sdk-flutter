import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:marktag/src/services/logger_service.dart';
import 'package:meta/meta.dart';

/// Represents IP information including IP address, location, and user agent.
class IPInfo {
  /// Creates an [IPInfo] instance.
  IPInfo({required this.ip, required this.loc, required this.uag});

  /// The public IP address.
  final String ip;

  /// The location code (e.g., country).
  final String loc;

  /// The user agent string.
  final String uag;
}

/// Parses the response from Cloudflare trace endpoint into a key-value map.
///
/// Example input:
///   ip=1.2.3.4\nloc=US\nuag=...\n
Map<String, String> parseResponse(String response) {
  final lines = response.split('\n');
  final result = <String, String>{};
  for (final line in lines) {
    final index = line.indexOf('=');
    if (index != -1) {
      final key = line.substring(0, index);
      final value = line.substring(index + 1);
      result[key] = value;
    }
  }
  return result;
}

/// Service for fetching and caching IP information from Cloudflare.
class IPService {
  /// Creates an [IPService] with an optional [http.Client] for testability.
  IPService({
    http.Client? httpClient,
    LoggerService? logger,
  }) : _httpClient = httpClient ?? http.Client(),
       _logger = logger ?? LoggerService(name: 'IPService');
  static IPInfo? _ipInfo;
  final http.Client _httpClient;
  final LoggerService _logger;

  /// Gets the IP information, fetching from the network if not cached.
  ///
  /// Throws a [StateError] if the information cannot be retrieved or parsed.
  Future<IPInfo> getIpInfo() async {
    if (_ipInfo != null) {
      _logger.debugLog(
        'Returning cached IP info. IP: ${_ipInfo!.ip},'
        ' LOC: ${_ipInfo!.loc}, UAG: ${_ipInfo!.uag}',
      );
      return _ipInfo!;
    }
    if (kIsWeb) {
      // Cloudflare's trace endpoint has no CORS headers, so use a
      // CORS-friendly equivalent in the browser.
      return _fetchFromIpapi();
    }

    _logger.debugLog('Fetching IP info from network.');
    final uri = Uri.parse('https://www.cloudflare.com/cdn-cgi/trace');
    final response = await _httpClient.get(uri);
    if (response.statusCode != 200) {
      _logger.debugLog(
        'Could not get IP info: HTTP ${response.statusCode}',
      );
      throw StateError('Could not get IP info: HTTP ${response.statusCode}');
    }
    final data = response.body;
    if (data.isEmpty) {
      _logger.debugLog('Could not get IP info: Empty response.');
      throw StateError('Could not get IP info: Empty response.');
    }
    final parsed = parseResponse(data);
    final ip = parsed['ip'];
    final loc = parsed['loc'];
    final uag = parsed['uag'];
    if (ip == null || loc == null || uag == null) {
      _logger.debugLog('Could not get IP info: Missing fields.');
      throw StateError('Could not get IP info: Missing fields.');
    }
    _ipInfo = IPInfo(ip: ip, loc: loc, uag: uag);
    _logger.debugLog(
      'IP info fetched. IP: ${_ipInfo!.ip},'
      ' LOC: ${_ipInfo!.loc}, UAG: ${_ipInfo!.uag}',
    );
    return _ipInfo!;
  }

  /// CORS-friendly IP/geo lookup for web. Returns empty strings on failure
  /// rather than throwing so server-side events can still go through.
  Future<IPInfo> _fetchFromIpapi() async {
    try {
      final uri = Uri.parse('https://ipapi.co/json/');
      final response = await _httpClient.get(uri);
      if (response.statusCode != 200) {
        _logger.debugLog('ipapi.co returned HTTP ${response.statusCode}');
        return IPInfo(ip: '', loc: '', uag: '');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final ip = (data['ip'] as String?) ?? '';
      final loc = (data['country_code'] as String?) ?? '';
      _ipInfo = IPInfo(ip: ip, loc: loc, uag: '');
      _logger.debugLog('IP info via ipapi.co. IP: $ip, LOC: $loc');
      return _ipInfo!;
    } on Object catch (e) {
      _logger.debugLog('ipapi.co fetch failed: $e');
      return IPInfo(ip: '', loc: '', uag: '');
    }
  }

  /// Resets the cached IP info. Only for testing purposes.
  @visibleForTesting
  static void resetCache() {
    _ipInfo = null;
  }
}
