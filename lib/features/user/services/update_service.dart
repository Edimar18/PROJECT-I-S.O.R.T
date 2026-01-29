import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current versions - CHANGE THESE MANUALLY when you update
  static const int CURRENT_APP_VERSION = 1;
  static const int CURRENT_MODEL_VERSION = 1;

  // SharedPreferences keys
  static const String MODEL_VERSION_KEY = 'model_version';

  Future<Map<String, dynamic>> checkForUpdates() async {
    try {
      // Get current model version from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final currentModelVersion = prefs.getInt(MODEL_VERSION_KEY) ?? CURRENT_MODEL_VERSION;

      // Fetch update info from Firestore
      final modelDoc = await _firestore.collection('updates').doc('model').get();
      final appDoc = await _firestore.collection('updates').doc('app').get();

      if (!modelDoc.exists || !appDoc.exists) {
        return {
          'hasUpdate': false,
          'message': 'No update information available',
        };
      }

      final modelData = modelDoc.data() as Map<String, dynamic>;
      final appData = appDoc.data() as Map<String, dynamic>;

      final int latestModelVersion = modelData['version'] ?? 1;
      final int latestAppVersion = appData['version'] ?? 1;

      final bool hasModelUpdate = latestModelVersion > currentModelVersion;
      final bool hasAppUpdate = latestAppVersion > CURRENT_APP_VERSION;

      return {
        'hasUpdate': hasModelUpdate || hasAppUpdate,
        'hasModelUpdate': hasModelUpdate,
        'hasAppUpdate': hasAppUpdate,
        'modelData': modelData,
        'appData': appData,
        'currentModelVersion': currentModelVersion,
        'currentAppVersion': CURRENT_APP_VERSION,
        'latestModelVersion': latestModelVersion,
        'latestAppVersion': latestAppVersion,
      };
    } catch (e) {
      print('Error checking for updates: $e');
      return {
        'hasUpdate': false,
        'error': e.toString(),
      };
    }
  }

  Future<bool> downloadAndUpdateModel(
      String downloadUrl,
      int newVersion,
      Function(double) onProgress,
      ) async {
    try {
      // Download the new model
      final response = await http.get(Uri.parse(downloadUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to download model');
      }

      // Get app directory
      final appDir = await getApplicationDocumentsDirectory();
      final modelPath = '${appDir.path}/model.tflite';

      // Save the new model
      final file = File(modelPath);
      await file.writeAsBytes(response.bodyBytes);

      // Update version in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(MODEL_VERSION_KEY, newVersion);

      print('Model updated successfully to version $newVersion');
      return true;
    } catch (e) {
      print('Error updating model: $e');
      return false;
    }
  }

  Future<bool> downloadAndInstallApp(
      String downloadUrl,
      Function(double) onProgress,
      ) async {
    try {
      // Request install permission
      if (Platform.isAndroid) {
        final status = await Permission.requestInstallPackages.request();
        if (!status.isGranted) {
          throw Exception('Install permission denied');
        }
      }

      // Download the APK
      final response = await http.get(
        Uri.parse(downloadUrl),
        headers: {'Accept': 'application/vnd.android.package-archive'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to download APK');
      }

      // Get external storage directory (more reliable for APK installation)
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Could not access storage');
      }

      final apkPath = '${directory.path}/i_sort_update.apk';

      // Save APK
      final file = File(apkPath);
      await file.writeAsBytes(response.bodyBytes);

      // Open APK for installation (Android only)
      if (Platform.isAndroid) {
        final result = await OpenFilex.open(apkPath);

        if (result.type == ResultType.done) {
          return true;
        } else {
          throw Exception('Failed to open APK: ${result.message}');
        }
      }

      return false;
    } catch (e) {
      print('Error installing app: $e');
      return false;
    }
  }

  Future<String> getModelPath() async {
    final prefs = await SharedPreferences.getInstance();
    final modelVersion = prefs.getInt(MODEL_VERSION_KEY);

    if (modelVersion != null && modelVersion > CURRENT_MODEL_VERSION) {
      // Use downloaded model
      final appDir = await getApplicationDocumentsDirectory();
      return '${appDir.path}/model.tflite';
    } else {
      // Use bundled model from assets
      return 'assets/models/model.tflite';
    }
  }
}