import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../widgets/common.dart';
import 'charts_hub.dart';
import 'episodes.dart';
import 'favorites.dart';
import 'home.dart';

// El esqueleto: 4 tabs con swipe (PageView) + barra inferior.
// Para sustentar: el PageView y el Nav comparten el MISMO índice (_i).
// - Swipe -> onPageChanged actualiza _i y el Nav se pinta solo.
// - Tap en Nav -> animateToPage mueve el PageView con animación.
// Tabs: Characters (Home), Episodes, Charts y Favorites.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;
  late final PageController _pages;

  @override
  void initState() {
    super.initState();
    _pages = PageController();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  // Tap en el Nav: anima hasta esa pestaña.
  void _go(int i) {
    if (i == _i) return;
    setState(() => _i = i);
    _pages.animateToPage(
      i,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: PageView(
        controller: _pages,
        onPageChanged: (i) => setState(() => _i = i),
        children: const [Home(), Episodes(), ChartsHub(), Favorites()],
      ),
      bottomNavigationBar: Nav(index: _i, onTap: _go),
    );
  }
}
