import '../error/app_exception.dart';

/// A lightweight functional result type returned by every repository method.
///
/// Repositories never throw to the presentation layer; they return [Ok] on
/// success or [Err] carrying a typed [AppException]. Presentation code switches
/// on the result instead of catching raw Firebase/Dio errors.
sealed class Result<T> {
  const Result();

  /// True when this is an [Ok].
  bool get isOk => this is Ok<T>;

  /// True when this is an [Err].
  bool get isErr => this is Err<T>;

  /// Returns the success value or null.
  T? get valueOrNull => this is Ok<T> ? (this as Ok<T>).value : null;

  /// Returns the error or null.
  AppException? get errorOrNull =>
      this is Err<T> ? (this as Err<T>).error : null;

  /// Pattern-match helper.
  R when<R>({
    required R Function(T value) ok,
    required R Function(AppException error) err,
  }) {
    final self = this;
    if (self is Ok<T>) return ok(self.value);
    return err((self as Err<T>).error);
  }
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.error);
  final AppException error;
}
