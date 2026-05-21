import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'supabase_config.dart';
import 'utils/constants.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/splash_screen.dart';

// Callback do WorkManager — executa em isolate separado quando app está fechado
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      await SyncService.sincronizarAgora();
    } catch (_) {}
    return true;
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  runApp(const SurveyApp());
}

class SurveyApp extends StatelessWidget {
  const SurveyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TECPOINT',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBgColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryColor,
          brightness: Brightness.dark,
          primary: kPrimaryColor,
          secondary: kPrimaryLight,
          surface: kSurfaceColor,
        ),
        // AppBar escuro com borda sutil
        appBarTheme: const AppBarTheme(
          backgroundColor: kSurfaceColor,
          foregroundColor: kTextColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: kTextColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: kTextColor),
        ),
        // Cards glassmorphism escuros
        cardTheme: CardThemeData(
          color: kCardColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: kBorderColor),
          ),
        ),
        // Botão principal verde
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          ),
        ),
        // Inputs escuros com borda sutil e foco verde
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0D1F10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          hintStyle: const TextStyle(color: kTextDim, fontSize: 14),
          labelStyle: const TextStyle(color: kTextColor3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: kBorderColor, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: kBorderColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: kColorCancelado, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(color: kColorCancelado, width: 1.5),
          ),
        ),
        // Chips com estilo escuro
        chipTheme: ChipThemeData(
          backgroundColor: kCardColor,
          selectedColor: kPrimaryColor.withOpacity(0.25),
          side: const BorderSide(color: kBorderColor),
          labelStyle: const TextStyle(color: kTextColor2, fontSize: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        ),
        // Divider sutil
        dividerTheme: const DividerThemeData(
          color: kBorderColor,
          thickness: 1,
        ),
        // Texto
        textTheme: const TextTheme(
          bodyLarge:   TextStyle(color: kTextColor),
          bodyMedium:  TextStyle(color: kTextColor2),
          bodySmall:   TextStyle(color: kTextColor3),
          titleLarge:  TextStyle(color: kTextColor,  fontWeight: FontWeight.w700),
          titleMedium: TextStyle(color: kTextColor,  fontWeight: FontWeight.w600),
          titleSmall:  TextStyle(color: kTextColor2, fontWeight: FontWeight.w600),
          labelLarge:  TextStyle(color: kTextColor,  fontWeight: FontWeight.w600),
          labelMedium: TextStyle(color: kTextColor2),
          labelSmall:  TextStyle(color: kTextColor3),
        ),
        // Popup menus escuros
        popupMenuTheme: const PopupMenuThemeData(
          color: kCardColor,
          textStyle: TextStyle(color: kTextColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            side: BorderSide(color: kBorderColor),
          ),
        ),
        // BottomNav escuro
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: kSurfaceColor,
          indicatorColor: kPrimaryColor.withOpacity(0.20),
          surfaceTintColor: Colors.transparent,
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(color: kTextColor3, fontSize: 11, fontWeight: FontWeight.w500),
          ),
          iconTheme: WidgetStatePropertyAll(
            IconThemeData(color: kTextColor3, size: 22),
          ),
        ),
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _inicializado  = false;
  bool _autenticado   = false;
  bool _splashDone    = false; // garante tempo mínimo de exibição da splash

  @override
  void initState() {
    super.initState();
    _inicializar();
    // Tempo mínimo para a animação da splash completar (2.6 s)
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _splashDone = true);
    });

    // Ouve eventos de auth do Supabase
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (!mounted) return;
      final event = data.event;

      if (event == AuthChangeEvent.signedOut) {
        // Só redireciona para login quando o logout foi EXPLÍCITO (usuário tocou "Sair").
        // O SDK emite signedOut também ao expirar o JWT (ex: internet voltou após
        // período offline e o token não pôde ser renovado). Nesses casos o usuário
        // NÃO deve ser expulso — o SyncService cuida de sincronizar em background.
        final deslogado = await AuthService.foiDeslogado();
        if (deslogado && mounted) {
          setState(() => _autenticado = false);
        }
      } else if (event == AuthChangeEvent.signedIn ||
                 event == AuthChangeEvent.tokenRefreshed) {
        if (mounted) setState(() => _autenticado = true);
      }
    });
  }

  Future<void> _inicializar() async {
    // 1. JWT válido em memória (caminho mais comum — usuário já logado)
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      if (mounted) setState(() { _autenticado = true; _inicializado = true; });
      return;
    }

    // 2. JWT ausente — verifica credenciais offline e conectividade
    final results = await Future.wait([
      AuthService.temCredenciaisOffline(),
      AuthService.foiDeslogado(),
      Connectivity().checkConnectivity(),
    ]);
    final temOffline  = results[0] as bool;
    final deslogado   = results[1] as bool;
    final conn        = results[2] as List<ConnectivityResult>;
    final offline     = conn.contains(ConnectivityResult.none);

    // Só bypassa o login se: tem credenciais + está offline + NÃO fez logout explícito
    if (temOffline && offline && !deslogado) {
      if (mounted) setState(() { _autenticado = true; _inicializado = true; });
      return;
    }

    // 3. Sem sessão e online → login obrigatório
    if (mounted) setState(() { _autenticado = false; _inicializado = true; });
  }

  @override
  Widget build(BuildContext context) {
    // Mostra splash enquanto auth não terminou OU animação não completou
    if (!_inicializado || !_splashDone) {
      return const SplashScreen();
    }

    return _autenticado ? const DashboardScreen() : const LoginScreen();
  }
}
