import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/blocs/auth/auth_bloc.dart';
import 'core/blocs/theme/theme_bloc.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';

class AcadiaApp extends StatelessWidget {
  const AcadiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(
          create: (context) => ThemeBloc()..add(const ThemeInitialized()),
        ),
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc()..add(const AuthCheckRequested()),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            title: 'ACADIA',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeState is ThemeDark ? ThemeMode.dark : ThemeMode.light,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
