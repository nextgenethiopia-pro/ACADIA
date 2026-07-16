import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const String _themeKey = 'is_dark_mode';

  ThemeBloc() : super(ThemeLight()) {
    on<ThemeInitialized>(_onThemeInitialized);
    on<ThemeToggled>(_onThemeToggled);
    on<ThemeSet>(_onThemeSet);
  }

  Future<void> _onThemeInitialized(
    ThemeInitialized event,
    Emitter<ThemeState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? false;
    emit(isDark ? ThemeDark() : ThemeLight());
  }

  Future<void> _onThemeToggled(
    ThemeToggled event,
    Emitter<ThemeState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final isCurrentlyDark = state is ThemeDark;
    await prefs.setBool(_themeKey, !isCurrentlyDark);
    emit(isCurrentlyDark ? ThemeLight() : ThemeDark());
  }

  Future<void> _onThemeSet(
    ThemeSet event,
    Emitter<ThemeState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, event.isDark);
    emit(event.isDark ? ThemeDark() : ThemeLight());
  }
}
