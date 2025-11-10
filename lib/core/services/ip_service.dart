import 'package:dio/dio.dart';
import '../../data/models/ip_info.dart';
import '../constants/app_constants.dart';

class IpService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: AppConstants.networkTimeout,
      receiveTimeout: AppConstants.networkTimeout,
      sendTimeout: AppConstants.networkTimeout,
    ),
  );
  String? _primaryApiEndpoint;

  IpService({String? apiEndpoint}) : _primaryApiEndpoint = apiEndpoint;

  Future<String?> getPublicIp() async {
    for (final endpoint in AppConstants.fallbackIpEndpoints) {
      try {
        final response = await _dio.get(endpoint, options: Options(
          receiveTimeout: AppConstants.networkReceiveTimeout,
        ));
        
        if (response.data is Map) {
          return response.data['ip'] ?? response.data['query'];
        } else if (response.data is String) {
          return response.data.trim();
        }
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  Future<IpInfo?> fetchIpInfo({String? ip}) async {
    // Try primary API first
    try {
      final endpoint = _primaryApiEndpoint ?? 
          '${AppConstants.defaultIpApiEndpoint}/${ip ?? ""}/json/';
      
      final response = await _dio.get(
        endpoint,
        options: Options(
          receiveTimeout: AppConstants.networkTimeout,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['error'] != null) {
          return await _fetchFromIpInfo(ip);
        }
        
        return IpInfo.fromJson(data);
      }
    } catch (e) {
      // Try fallback API
      return await _fetchFromIpInfo(ip);
    }
    return null;
  }

  Future<IpInfo?> _fetchFromIpInfo(String? ip) async {
    try {
      final endpoint = ip != null 
          ? 'https://ipinfo.io/$ip/json'
          : 'https://ipinfo.io/json';
      
      final response = await _dio.get(
        endpoint,
        options: Options(
          receiveTimeout: AppConstants.networkTimeout,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        double? lat, lon;
        if (data['loc'] != null) {
          final parts = data['loc'].toString().split(',');
          if (parts.length == 2) {
            lat = double.tryParse(parts[0]);
            lon = double.tryParse(parts[1]);
          }
        }
        
        return IpInfo(
          ipv4: data['ip'],
          city: data['city'],
          region: data['region'],
          country: data['country'],
          zip: data['postal'],
          latitude: lat,
          longitude: lon,
          isp: data['org'],
          timezone: data['timezone'],
          hostname: data['hostname'],
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<bool> checkVpnProxy() async {
    try {
      final ipInfo = await fetchIpInfo();
      if (ipInfo == null) return false;
      
      final isVpn = ipInfo.isVpn ?? false;
      final isProxy = ipInfo.isProxy ?? false;
      final isTor = ipInfo.isTor ?? false;
      
      return isVpn || isProxy || isTor;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkBlacklist(String ip) async {
    try {
      final response = await _dio.get(
        'https://api.abuseipdb.com/api/v2/check',
        queryParameters: {'ipAddress': ip, 'maxAgeInDays': 90},
        options: Options(
          headers: {
            'Key': '',
            'Accept': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        return data['data']['abuseConfidenceScore'] > 0;
      }
    } catch (e) {
      // API key not configured
    }
    return false;
  }
}

