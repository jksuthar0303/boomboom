enum ApiStatus { loading, success, error, empty }

class ApiResponse<T> {
  final ApiStatus status;
  final T? data;
  final String? message;

  ApiResponse({
    required this.status,
    this.data,
    this.message,
  });

  factory ApiResponse.loading({String? message}) => ApiResponse(
        status: ApiStatus.loading,
        message: message,
      );

  factory ApiResponse.success(T data, {String? message}) => ApiResponse(
        status: ApiStatus.success,
        data: data,
        message: message,
      );

  factory ApiResponse.error(String message) => ApiResponse(
        status: ApiStatus.error,
        message: message,
      );

  factory ApiResponse.empty() => ApiResponse(
        status: ApiStatus.empty,
      );

  bool get isLoading => status == ApiStatus.loading;
  bool get isSuccess => status == ApiStatus.success;
  bool get isError => status == ApiStatus.error;
  bool get isEmpty => status == ApiStatus.empty;

  @override
  String toString() {
    return 'ApiResponse(status: $status, message: $message, data: $data)';
  }
}
