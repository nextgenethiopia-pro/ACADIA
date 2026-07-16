part of 'theme_bloc.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

class ThemeInitialized extends ThemeEvent {
  const ThemeInitialized();
}

class ThemeToggled extends ThemeEvent {
  const ThemeToggled();
}

class ThemeSet extends ThemeEvent {
  final bool isDark;

  const ThemeSet({required this.isDark});

  @override
  List<Object?> get props => [isDark];
}
