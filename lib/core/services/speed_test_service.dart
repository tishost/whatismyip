import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

class SpeedTestService {
  static const String _testServer = 'https://www.google.com';
  
  // Test ping to a server
  static Future<double> testPing(String host) async {
    HttpClient? client;
    try {
      final stopwatch = Stopwatch()..start();
      client = HttpClient();
      
      try {
        final request = await client.getUrl(Uri.parse('$_testServer/favicon.ico'))
            .timeout(const Duration(seconds: 5));
        final response = await request.close()
            .timeout(const Duration(seconds: 5));
        await response.drain();
        stopwatch.stop();
        client.close();
        return stopwatch.elapsedMilliseconds.toDouble();
      } catch (e) {
        client.close();
        return -1;
      }
    } catch (e) {
      client?.close();
      return -1; // Error
    }
  }

  // Test download speed by downloading a file
  static Future<double> testDownloadSpeed({
    required Function(double) onProgress,
    int durationSeconds = 10,
  }) async {
    Dio? dio;
    try {
      dio = Dio();
      final stopwatch = Stopwatch()..start();
      int totalBytes = 0;
      final startTime = DateTime.now();

      // Use a reliable test file (Google's favicon is small, use a larger test file)
      // For better accuracy, we'll download multiple chunks
      const testUrls = [
        'https://www.google.com/favicon.ico',
        'https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png',
      ];

      for (final url in testUrls) {
        if (DateTime.now().difference(startTime).inSeconds >= durationSeconds) {
          break;
        }

        try {
          await dio.get<List<int>>(
            url,
            options: Options(
              responseType: ResponseType.bytes,
              receiveTimeout: const Duration(seconds: 30),
            ),
            onReceiveProgress: (received, total) {
              try {
                totalBytes += received;
                final elapsed = stopwatch.elapsedMilliseconds / 1000.0;
                if (elapsed > 0) {
                  final speedMbps = (totalBytes * 8) / (elapsed * 1000000); // Convert to Mbps
                  onProgress(speedMbps);
                }
              } catch (e) {
                // Ignore progress callback errors
              }
            },
          );
        } catch (e) {
          // Continue with next URL
          continue;
        }
      }

      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds / 1000.0;
      
      if (elapsed > 0 && totalBytes > 0) {
        // Calculate speed in Mbps (bits per second / 1,000,000)
        final speedMbps = (totalBytes * 8) / (elapsed * 1000000);
        return speedMbps;
      }
      
      return 0;
    } catch (e) {
      return -1; // Error
    } finally {
      dio?.close();
    }
  }

  // Test upload speed by uploading data
  static Future<double> testUploadSpeed({
    required Function(double) onProgress,
    int durationSeconds = 10,
  }) async {
    Dio? dio;
    try {
      dio = Dio();
      final stopwatch = Stopwatch()..start();
      int totalBytes = 0;
      final startTime = DateTime.now();

      // Generate test data to upload
      final testData = List.generate(1024 * 100, (i) => i % 256); // 100KB chunk
      
      // Use a test endpoint (we'll use httpbin.org for testing)
      const uploadUrl = 'https://httpbin.org/post';

      while (DateTime.now().difference(startTime).inSeconds < durationSeconds) {
        try {
          await dio.post(
            uploadUrl,
            data: testData,
            options: Options(
              sendTimeout: const Duration(seconds: 30),
            ),
            onSendProgress: (sent, total) {
              try {
                totalBytes += sent;
                final elapsed = stopwatch.elapsedMilliseconds / 1000.0;
                if (elapsed > 0) {
                  final speedMbps = (totalBytes * 8) / (elapsed * 1000000); // Convert to Mbps
                  onProgress(speedMbps);
                }
              } catch (e) {
                // Ignore progress callback errors
              }
            },
          );
        } catch (e) {
          // Continue trying
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }
      }

      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds / 1000.0;
      
      if (elapsed > 0 && totalBytes > 0) {
        // Calculate speed in Mbps
        final speedMbps = (totalBytes * 8) / (elapsed * 1000000);
        return speedMbps;
      }
      
      return 0;
    } catch (e) {
      return -1; // Error
    } finally {
      dio?.close();
    }
  }

  // Alternative: Simple download test using http package
  static Future<double> testDownloadSpeedSimple({
    required Function(double) onProgress,
    int durationSeconds = 10,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      int totalBytes = 0;
      final startTime = DateTime.now();

      // Use multiple small files for better accuracy
      final testUrls = [
        'https://www.google.com/favicon.ico',
        'https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png',
      ];

      while (DateTime.now().difference(startTime).inSeconds < durationSeconds) {
        for (final url in testUrls) {
          if (DateTime.now().difference(startTime).inSeconds >= durationSeconds) {
            break;
          }

          try {
            final response = await http.get(
              Uri.parse(url),
            ).timeout(const Duration(seconds: 10));

            if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
              totalBytes += response.bodyBytes.length;
              final elapsed = stopwatch.elapsedMilliseconds / 1000.0;
              if (elapsed > 0) {
                try {
                  final speedMbps = (totalBytes * 8) / (elapsed * 1000000);
                  onProgress(speedMbps);
                } catch (e) {
                  // Ignore progress callback errors
                }
              }
            }
          } catch (e) {
            // Continue
            continue;
          }
        }
      }

      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds / 1000.0;
      
      if (elapsed > 0 && totalBytes > 0) {
        final speedMbps = (totalBytes * 8) / (elapsed * 1000000);
        return speedMbps;
      }
      
      return 0;
    } catch (e) {
      return -1;
    }
  }
}

