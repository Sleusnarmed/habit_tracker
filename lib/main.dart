import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:habit_tracker/app/navigation/main_nav.dart';
import 'package:habit_tracker/providers/task_provider.dart';
import 'package:habit_tracker/services/firebase_service.dart';
import 'package:habit_tracker/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configuración de UI del sistema
  await _configureSystemUI();

  try {
    // Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Verificar conexión con Firestore
    await _testFirestoreConnection();
    
    runApp(const HabitTrackerApp());
  } catch (e) {
    runApp(FirebaseErrorWidget(error: e.toString()));
  }
}

Future<void> _configureSystemUI() async {
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
}

Future<void> _testFirestoreConnection() async {
  try {
    await FirebaseFirestore.instance.collection('tasks').limit(1).get();
  } catch (e) {
    throw Exception('Error al conectar con Firestore: $e');
  }
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Proveedor del servicio Firebase
        Provider<FirebaseService>(
          create: (_) => FirebaseService(),
        ),
        // Proveedor del TaskProvider que usa FirebaseService
        ChangeNotifierProvider<TaskProvider>(
          create: (context) => TaskProvider(
            firebaseService: context.read<FirebaseService>(),
          ),
          lazy: false, // Inicializar inmediatamente
        ),
      ],
      child: MaterialApp(
        title: 'Habit Tracker',
        debugShowCheckedModeBanner: false,
        theme: _buildAppTheme(),
        home: const MainNavigationWrapper(),
      ),
    );
  }

  ThemeData _buildAppTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

class FirebaseErrorWidget extends StatelessWidget {
  final String error;

  const FirebaseErrorWidget({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, 
                  size: 64, 
                  color: Colors.redAccent
                ),
                const SizedBox(height: 20),
                Text(
                  'Error de Conexión',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                FilledButton.tonal(
                  onPressed: () => main(),
                  child: const Text('Reintentar Conexión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}