class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([super.message = 'Session expired. Please log in again.'])
      : super(statusCode: 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException([super.message = 'Access Denied: Insufficient permissions.'])
      : super(statusCode: 403);
}

class NotFoundException extends ApiException {
  NotFoundException([super.message = 'Requested resource was not found.'])
      : super(statusCode: 404);
}

class NetworkException extends ApiException {
  NetworkException([super.message = 'Network error. Please check your connection.']);
}
