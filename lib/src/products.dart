library semantics3_products;

import 'dart:async';
import 'dart:convert' show JSON;
import 'package:http/http.dart' as http;
import 'package:oauth1/oauth1.dart' as oauth1;
import 'exceptions.dart';

// TODO Add a clone() method. Can only clone during STATE_BUILD.
// Cloning allows using a base query, variations of which may be 
// executed in parallel. By default, a single instance of 
// semantics3.Products will only allow executing a single query at a time.
// TODO Allow setting a timeout as one of the options.
class Products {
  
  final String _apiKey;
  final String _apiSecret;
  final Map _options = {};
  
  static final CLIENT_VERSION = '0.1.0';
  static final SERVER_VERSION = 'v1';
  static final API_BASE = 'https://api.semantics3.com/' + SERVER_VERSION;
  
  static const ENDPOINT_PRODUCTS = '/products';
  static const ENDPOINT_CATEGORIES = '/categories';
  static const ENDPOINT_OFFERS = '/offers';
  
  static const STATE_BUILD = 1;
  static const STATE_EXECUTE = 2;
  static const STATE_FETCH = 3;
  
  var _client;
  int state = STATE_BUILD;
  String endpoint = '';
  Map _query = {};
  String _result = null;
  
  Products(this._apiKey, this._apiSecret) {
    _client = new oauth1.Client(
        oauth1.SignatureMethods.HMAC_SHA1,
        new oauth1.ClientCredentials(this._apiKey, this._apiSecret),
        null
    );
  }
  
  void _clear() {
    this.state = STATE_BUILD;
    this.endpoint = null;
    this._query = {};
    this._result = null;
  }
  
  /**
   * Given a HTTP response, returns an appropriate Exception instance.
   */
  Exception _getException(http.Response res) {
    switch (res.statusCode) {
      case 400:
        return new BadRequestException(res.body, res.statusCode);
      case 401:
        return new UnauthorizedException(res.body, res.statusCode);
      case 404:
        return new NotFoundException(res.body, res.statusCode);
      case 429:
        return new TooManyRequestsException(res.body, res.statusCode);
      case 500:
        return new ServerException(res.body, res.statusCode);
      default:
        // TODO Do a 5xx regex check and conclude as ServerException too.
        return new Exception('Unknown exception.');
    }
  }
  
  /**
   * Ensure that we are in the right state to be building a query.
   * 
   * If not, cleanup if possible or complain.
   */
  void _ensureBuildState() {
    if (this.state == STATE_FETCH) {
      this._clear();
    }
    else if (this.state == STATE_EXECUTE) {
      // TODO Throw an error or "wait" until the current query
      // finishes and then redo this function.
    }
  }
 
  /**
   * During the lifetime of a single query, we'd want to preserve the
   * target endpoint.
   */
  void _ensureEndpointPreserved([String targetEndpoint]) {
    if (this.endpoint.isNotEmpty) {
      var throwException = false;
      if (targetEndpoint.isEmpty) {
        throwException = true;
      }
      else {
        throwException = (this.endpoint != targetEndpoint);
      }
      if (throwException) {
        throw new StateError(
            'Cannot reset endpoint in the middle of a query.'
        );
      }
    }
  }
  
  Future<List> _getEntities(String endpoint) {
    this._ensureEndpointPreserved(endpoint);
    this.endpoint = endpoint;
    var completer = new Completer();
    getResults()
      .then((result) {
        completer.complete(result['results']);
      })
      .catchError((err) {
        completer.completeError(err);
      });
    return completer.future;
  }
  
  Products _entityField(String endpoint, String key, dynamic value) {
    this._ensureBuildState();
    this._ensureEndpointPreserved(endpoint);
    this._query[key] = value;
    this.endpoint = endpoint;
    return this;
  }
  
  Products productsField(String key, dynamic value) =>
      _entityField(ENDPOINT_PRODUCTS, key, value);
  Products categoriesField(String key, dynamic value) =>
      _entityField(ENDPOINT_CATEGORIES, key, value);
  Products offersField(String key, dynamic value) =>
      _entityField(ENDPOINT_OFFERS, key, value);
  
  Map getQuery() {
    return this._query;
  }
  
  String getQueryJson() {
    return JSON.encode(this._query);
  }
  
  Future<String> runQuery() {
    if (this.state != STATE_BUILD) {
      throw new StateError(
          'Cannot run query from an invalid state: ' + 
              this.state.toString()
      );
    }
    if (this.endpoint.isEmpty) {
      throw new StateError(
          'Cannot run query without an endpoint set. ' +
          'Call one of the *_field() API methods first.'
      );
    }
    String url = API_BASE + this.endpoint;
    if (this._query.isNotEmpty) {
      url += '?q=';
      url += Uri.encodeQueryComponent(JSON.encode(this._query));
    }
    var completer = new Completer();
    Map<String, String> headers = {
      'Accept': '*/*',
      'Connection': 'close',
      'User-Agent': 'Semantics3 Dart Lib/' + CLIENT_VERSION
    };
    this._client.get(url, headers: headers)
      .then((res) {
        this.state = STATE_FETCH;
        if (res.statusCode != 200) {
          completer.completeError(this._getException(res));
        }
        else {
          this._result = res.body;
          completer.complete(this._result);
        }
      })
      .catchError((err) {
          this.state = STATE_FETCH;
          completer.completeError(err);
      });
    return completer.future;
  }
 
  
  Future<List> getProducts() => _getEntities(ENDPOINT_PRODUCTS);
  Future<List> getCategories() => _getEntities(ENDPOINT_CATEGORIES);
  Future<List> getOffers() => _getEntities(ENDPOINT_OFFERS);
  
  /**
   * Alias of [getResults].
   */
  Future<Map> getResult() => getResults();
  
  /**
   * Alias of [getResultsJson].
   */
  Future<String> getResultJson() => getResultsJson();
  
  Future<Map> getResults() {
    var completer = new Completer();
    getResultsJson()
      .then((result) {
        completer.complete(JSON.decode(result));
      })
      .catchError((err) {
        completer.completeError(err);
      });
    return completer.future;
  }
  
  Future<String> getResultsJson() {
    if (this.state == STATE_FETCH) {
      return new Future.value(this._result);
    }
    else {
      return this.runQuery();
    }
  }

}