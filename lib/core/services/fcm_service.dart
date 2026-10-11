import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'supabase_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb) return;
  await Firebase.initializeApp();
  debugPrint('FCM Background message: ${message.messageId} - ${message.notification?.title}');
}

class FcmService {
  static FirebaseMessaging? _messagingInstance;
  static FirebaseMessaging get _messaging => _messagingInstance ??= FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    // FCM Push Notification diinisialisasi pada platform mobile (Android & iOS).
    // Pada Web/Localhost, Firebase Cloud Messaging memerlukan VAPID Web Push cert terpisah.
    if (kIsWeb) {
      debugPrint('FCM: Berjalan di Web/Localhost. Push Notification FCM aktif otomatis pada instalasi Android APK.');
      return;
    }

    try {
      // 1. Inisialisasi Firebase Core
      await Firebase.initializeApp();

      // 2. Registrasi Background Message Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Request Permission Notifikasi (Wajib untuk Android 13+ & iOS)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('FCM Permission status: ${settings.authorizationStatus}');

      // 4. Inisialisasi Flutter Local Notifications untuk Foreground Alerts
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: DarwinInitializationSettings(),
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Local notification clicked: ${response.payload}');
        },
      );

      // Buat Notification Channel untuk Android
      const androidChannel = AndroidNotificationChannel(
        'high_importance_channel',
        'Notifikasi Perkuliahan & Kelas',
        description: 'Channel untuk pengumuman, tugas, presensi, dan iuran kas kelas.',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // 5. Listener Pesan Saat Aplikasi di Foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message received: ${message.notification?.title}');
        final notification = message.notification;
        final android = message.notification?.android;

        if (notification != null && android != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                androidChannel.id,
                androidChannel.name,
                channelDescription: androidChannel.description,
                icon: '@mipmap/ic_launcher',
                importance: Importance.high,
                priority: Priority.high,
              ),
            ),
            payload: message.data.toString(),
          );
        }
      });

      // 6. Listener saat Notifikasi Diklik oleh Pengguna
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Notification dibuka dari background: ${message.data}');
      });

      _isInitialized = true;
      debugPrint('FCM Service berhasil diinisialisasi untuk Android/iOS!');
    } catch (e) {
      debugPrint('FCM Service inisialisasi dilewati / error: $e');
    }
  }

  /// Sinkronisasi FCM Token perangkat ke Supabase agar server bisa kirim notifikasi tertarget
  static Future<String?> syncDeviceToken(String studentNim) async {
    // Di Web atau jika Firebase belum diinisialisasi, lewati dengan aman tanpa error
    if (kIsWeb || !_isInitialized) {
      return null;
    }

    try {
      final token = await _messaging.getToken();
      if (token == null) return null;

      debugPrint('FCM Device Token untuk NIM $studentNim: $token');

      // Simpan/Update token ke Supabase jika client aktif
      final client = SupabaseService.client;
      if (client != null && studentNim.isNotEmpty) {
        await client.from('user_push_tokens').upsert({
          'nim': studentNim,
          'token': token,
          'platform': defaultTargetPlatform.name,
          'updated_at': DateTime.now().toIso8601String(),
        });
        debugPrint('FCM Token tersimpan di Supabase.');
      }

      return token;
    } catch (e) {
      debugPrint('Gagal sinkronisasi token FCM: $e');
      return null;
    }
  }
}
