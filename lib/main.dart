import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://pbnnebxirvunszeqmwbp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBibm5lYnhpcnZ1bnN6ZXFtd2JwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI3ODAyOTcsImV4cCI6MjA2ODM1NjI5N30.1SWkYxs76gSMreVfo9v116CpLP2HNykZ5u0f0Rq1HmI',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de Tareas',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.blue.shade900,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade900),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
