import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:clipboard/clipboard.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/ip_info.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_text.dart';
import '../../core/utils/app_theme.dart';
import '../../core/constants/strings.dart';

class DetailScreen extends StatelessWidget {
  final IpInfo ipInfo;

  const DetailScreen({super.key, required this.ipInfo});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Navigate to home instead of popping
          context.go('/');
        }
      },
      child: Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground(),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildInfoSection(),
                      const SizedBox(height: 24),
                      if (ipInfo.hasLocation) _buildMapSection(),
                      const SizedBox(height: 24),
                      _buildActionButtons(context),
                      const SizedBox(height: 24), // Extra space for scrolling
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/'),
          ),
          const Expanded(
            child: GradientText(
              'IP Details',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ipInfo.ipv4 != null) _buildInfoRow('IPv4', ipInfo.ipv4!),
          if (ipInfo.ipv6 != null) _buildInfoRow('IPv6', ipInfo.ipv6!),
          _buildInfoRow('ISP', ipInfo.isp ?? 'Unknown'),
          if (ipInfo.asn != null) _buildInfoRow('ASN', ipInfo.asn!),
          if (ipInfo.organization != null)
            _buildInfoRow('Organization', ipInfo.organization!),
          _buildInfoRow('Country', ipInfo.country ?? 'Unknown'),
          if (ipInfo.countryCode != null)
            _buildInfoRow('Country Code', ipInfo.countryCode!),
          if (ipInfo.region != null) _buildInfoRow('Region', ipInfo.region!),
          if (ipInfo.city != null) _buildInfoRow('City', ipInfo.city!),
          if (ipInfo.zip != null) _buildInfoRow('ZIP Code', ipInfo.zip!),
          if (ipInfo.timezone != null)
            _buildInfoRow('Timezone', ipInfo.timezone!),
          if (ipInfo.hostname != null)
            _buildInfoRow('Hostname', ipInfo.hostname!),
          if (ipInfo.latitude != null && ipInfo.longitude != null)
            _buildInfoRow(
              'Coordinates',
              '${ipInfo.latitude}, ${ipInfo.longitude}',
            ),
          const SizedBox(height: 12),
          _buildInfoRow('VPN', ipInfo.isVpn == true ? 'Yes' : 'No'),
          _buildInfoRow('Proxy', ipInfo.isProxy == true ? 'Yes' : 'No'),
          if (ipInfo.isTor == true) _buildInfoRow('TOR', 'Yes'),
          if (ipInfo.timestamp != null)
            _buildInfoRow(
              'Last Updated',
              _formatDateTime(ipInfo.timestamp!),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return GlassCard(
      height: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(ipInfo.latitude!, ipInfo.longitude!),
            zoom: 12,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('ip_location'),
              position: LatLng(ipInfo.latitude!, ipInfo.longitude!),
              infoWindow: InfoWindow(
                title: ipInfo.displayLocation,
                snippet: ipInfo.displayLocation,
              ),
            ),
          },
          mapType: MapType.normal,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text(AppStrings.copy),
            onPressed: () {
              final text = _buildShareableText();
              FlutterClipboard.copy(text).then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('IP info copied to clipboard!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.share),
            label: const Text(AppStrings.share),
            onPressed: () {
              final text = _buildShareableText();
              Share.share(text);
            },
          ),
        ),
      ],
    );
  }

  String _buildShareableText() {
    final buffer = StringBuffer();
    buffer.writeln('IP Information:');
    if (ipInfo.ipv4 != null) buffer.writeln('IPv4: ${ipInfo.ipv4}');
    if (ipInfo.ipv6 != null) buffer.writeln('IPv6: ${ipInfo.ipv6}');
    if (ipInfo.isp != null) buffer.writeln('ISP: ${ipInfo.isp}');
    if (ipInfo.country != null) buffer.writeln('Country: ${ipInfo.country}');
    if (ipInfo.city != null) buffer.writeln('City: ${ipInfo.city}');
    return buffer.toString();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
