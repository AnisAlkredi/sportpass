import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/di/service_locator.dart';

Future<void> _loadEnv() async {
  // Web-safe env asset (no leading dot in filename).
  try {
    await dotenv.load(fileName: 'assets/env/app.env');
    return;
  } catch (_) {
    // Fallback for legacy local setups.
  }
  await dotenv.load(fileName: '.env');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Required for offline/dev environments to avoid runtime HTTP font fetch.
  GoogleFonts.config.allowRuntimeFetching = false;
  await _loadEnv();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  await setupServiceLocator();
  runApp(const SportPassApp());
}
