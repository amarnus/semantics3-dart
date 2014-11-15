library semantics3_exceptions;

import 'dart:convert' show JSON;

class ProductsException implements Exception {

  final String message;
  final int code;
  
  ProductsException(this.message, this.code);
  
  int getCode() => this.code;
  Map getMessage() => JSON.decode(this.message);
}

class BadRequestException extends ProductsException {

  BadRequestException(String message, int code) : super(message, code);
}

class UnauthorizedException extends ProductsException {

  UnauthorizedException(String message, int code) : super(message, code);

}

class NotFoundException extends ProductsException {

  NotFoundException(String message, int code) : super(message, code);

}

class TooManyRequestsException extends ProductsException {

  TooManyRequestsException(String message, int code) : super(message, code);

}

class ServerException extends ProductsException {

  ServerException(String message, int code) : super(message, code);

}