import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'data/api.dart';
import 'data/app_state.dart';
import 'ui/screens/splash.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Rickpedia());
}

// Raíz: enchufa el cartero (Api) y la memoria (AppState),
// pone el tema oscuro y arranca en el Splash.
class Rickpedia extends StatelessWidget {
  const Rickpedia({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => Api(), dispose: (_, a) => a.close()),
        ChangeNotifierProvider(create: (_) => AppState()..load()),
      ],
      child: MaterialApp(
        title: 'Rickpedia',
        debugShowCheckedModeBanner: false,
        theme: appTheme(),
        home: const Splash(),
      ),
    );
  }
}
