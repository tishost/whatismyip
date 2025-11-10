class IpInfo {
  final String? ipv4;
  final String? ipv6;
  final String? isp;
  final String? asn;
  final String? country;
  final String? countryCode;
  final String? city;
  final String? region;
  final String? zip;
  final double? latitude;
  final double? longitude;
  final String? timezone;
  final bool? isVpn;
  final bool? isProxy;
  final bool? isTor;
  final String? hostname;
  final String? organization;
  final DateTime? timestamp;
  final int? abuseConfidenceScore;
  final bool? isBlacklisted;
  final String? threatType;

  IpInfo({
    this.ipv4,
    this.ipv6,
    this.isp,
    this.asn,
    this.country,
    this.countryCode,
    this.city,
    this.region,
    this.zip,
    this.latitude,
    this.longitude,
    this.timezone,
    this.isVpn,
    this.isProxy,
    this.isTor,
    this.hostname,
    this.organization,
    DateTime? timestamp,
    this.abuseConfidenceScore,
    this.isBlacklisted,
    this.threatType,
  }) : timestamp = timestamp ?? DateTime.now();

  factory IpInfo.fromJson(Map<String, dynamic> json) {
    return IpInfo(
      ipv4: json['ip'] ?? json['ipv4'] ?? json['query'],
      ipv6: json['ipv6'],
      isp: json['isp'] ?? json['org'],
      asn: json['asn'] ?? json['as'],
      country: json['country'] ?? json['countryName'],
      countryCode: json['countryCode'] ?? json['country_code'],
      city: json['city'],
      region: json['region'] ?? json['regionName'],
      zip: json['zip'] ?? json['postal'],
      latitude: json['lat'] != null ? double.tryParse(json['lat'].toString()) : json['latitude'],
      longitude: json['lon'] != null ? double.tryParse(json['lon'].toString()) : json['longitude'],
      timezone: json['timezone'],
      isVpn: json['vpn'] ?? json['isVpn'] ?? json['security']?['vpn'] ?? false,
      isProxy: json['proxy'] ?? json['isProxy'] ?? json['security']?['proxy'] ?? false,
      isTor: json['tor'] ?? json['isTor'] ?? json['security']?['tor'] ?? false,
      hostname: json['hostname'],
      organization: json['org'] ?? json['organization'],
      abuseConfidenceScore: json['abuseConfidenceScore'] ?? json['abuse']?['confidence_score'],
      isBlacklisted: json['isBlacklisted'] ?? json['abuse']?['is_blacklisted'],
      threatType: json['threatType'] ?? json['threat_type'],
      timestamp: json['timestamp'] != null 
          ? DateTime.tryParse(json['timestamp'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ipv4': ipv4,
      'ipv6': ipv6,
      'isp': isp,
      'asn': asn,
      'country': country,
      'countryCode': countryCode,
      'city': city,
      'region': region,
      'zip': zip,
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
      'isVpn': isVpn,
      'isProxy': isProxy,
      'isTor': isTor,
      'hostname': hostname,
      'organization': organization,
      'timestamp': timestamp?.toIso8601String(),
      'abuseConfidenceScore': abuseConfidenceScore,
      'isBlacklisted': isBlacklisted,
      'threatType': threatType,
    };
  }

  String get displayLocation {
    final parts = <String>[];
    if (city != null) parts.add(city!);
    if (region != null) parts.add(region!);
    if (country != null) parts.add(country!);
    return parts.isEmpty ? 'Unknown' : parts.join(', ');
  }

  bool get hasLocation => latitude != null && longitude != null;
}

