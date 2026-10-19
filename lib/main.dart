import 'package:flutter/material.dart';
import 'theme.dart';
import 'nav.dart';
import 'services/data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dataService.init();
  runApp(const MarchSafeApp());
}

class MarchSafeApp extends StatelessWidget {
  const MarchSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MarchSafe',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: child!,
          ),
        );
      },
    );
  }
}
