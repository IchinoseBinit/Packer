class AsyncState<T> {
  final bool isLoading;
  final T? data;
  final String? error;

  const AsyncState._({
    this.isLoading = false,
    this.data,
    this.error,
  });

  factory AsyncState.idle() => const AsyncState._();
  factory AsyncState.loading() => const AsyncState._(isLoading: true);
  factory AsyncState.success(T data) => AsyncState._(data: data);
  factory AsyncState.error(String error) => AsyncState._(error: error);

  bool get hasError => error != null;
  bool get hasData => data != null;

  //  add when method for pattern matching
  R when<R>({
    required R Function() idle,
    required R Function() loading,
    required R Function(T data) success,
    required R Function(String error) error,
  }) {
    if (isLoading) {
      return loading();
    } else if (hasError) {
      return error(this.error!);
    } else if (hasData) {
      return success(this.data!);
    } else {
      return idle();
    }
  }
}
