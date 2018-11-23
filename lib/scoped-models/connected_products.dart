import 'dart:convert';
import 'dart:async';

import 'package:scoped_model/scoped_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/subjects.dart';

import '../models/product.dart';
import '../models/user.dart';
import '../models/auth.dart';

mixin ConnectedProductsModel on Model {
  List<Product> _products = [];
  String _selProductId;
  User _authenticatedUser;
  bool _isLoading = false;
}

// ProductModel class
mixin ProductsModel on ConnectedProductsModel {
  bool _showFavoirtes = false;

  List<Product> get allproducts {
    return List.from(_products);
  }

  // Get all favorites products
  List<Product> get displayedProducts {
    if (_showFavoirtes) {
      return _products.where(
        (Product product) => product.isFavorite
      ).toList();
    }
    return List.from(_products);
  }

  bool get displayFavoritesOnly {
    return _showFavoirtes;
  }

  int get selectedProductIndex {
    return _products.indexWhere(
      (Product product) {
        return product.id == _selProductId;
      }
    );
  }

  String get selectedProductId {
    return _selProductId;
  }

  Product get selectedProduct {
    if (selectedProductId == null) {
      return null;
    }
    return _products.firstWhere((Product product) {
      return product.id == _selProductId;
    });
  }

  /* Add product */
  Future<bool> addProduct(
    String title,
    String description,
    String image,
    double price,
  ) async {
    _isLoading = true;
    notifyListeners();
    final Map<String, dynamic> productData = {
      'title': title,
      'description': description,
      'image': 'https://sallysbakingaddiction.com/wp-content/uploads/2017/06/chocolate-buttercream-recipe-2.jpg',
      'price': price,
      'userEmail': _authenticatedUser.email,
      'userId': _authenticatedUser.id

    };
    try {
      final http.Response res = await http.post('https://flutter-products-7c610.firebaseio.com/products.json?auth=${_authenticatedUser.token}',
        body: json.encode(productData));
      if (res.statusCode != 200 && res.statusCode != 201) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final Map<String, dynamic> responseData = json.decode(res.body);
      final Product newProduct = Product(
        id: responseData['name'],
        title: title,
        description: description,
        price: price,
        image: image,
        userEmail: _authenticatedUser.email,
        userId: _authenticatedUser.id
      );
      _products.add(newProduct);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(
    String title,
    String description,
    String image,
    double price,
  ) {
    _isLoading = true;
    notifyListeners();
    final Map<String, dynamic> updateData = {
      'title': title,
      'description': description,
      'image': 'https://sallysbakingaddiction.com/wp-content/uploads/2017/06/chocolate-buttercream-recipe-2.jpg',
      'price': price,
      'userEmail': selectedProduct.userEmail,
      'userId': selectedProduct.userId
    };
    return http.put('https://flutter-products-7c610.firebaseio.com/products/${selectedProduct.id}.json?auth=${_authenticatedUser.token}',
      body: json.encode(updateData))
      .then((http.Response response) {
        final Product updatedProduct = Product(
          id: selectedProduct.id,
          title: title,
          description: description,
          price: price,
          image: image,
          userEmail: selectedProduct.userEmail,
          userId: selectedProduct.userId);
        _products[selectedProductIndex] = updatedProduct;
        _isLoading = false;
        notifyListeners();
        return true;
      })
      .catchError((error) {
        _isLoading = false;
        notifyListeners();
        return false;
      });
    
  }

  Future<bool> deleteProduct() {
    _isLoading = true;
    final deletedProductId = selectedProduct.id;
    // final int selectedProductIndex = _products.indexWhere(
    //   (Product product) {
    //     return product.id == _selProductId;
    //   });
    _products.removeAt(selectedProductIndex);
    _selProductId = null;
    notifyListeners();
    return http.delete('https://flutter-products-7c610.firebaseio.com/products/${deletedProductId}.json?auth=${_authenticatedUser.token}')
      .then((http.Response response) {
        _isLoading = false;
        notifyListeners();
        return true;
      })
      .catchError((error) {
        _isLoading = false;
        notifyListeners();
        return false;
      });
  }

  Future<Null> fetchProducts({onlyForUser = false}) {
    _isLoading = true;
    notifyListeners();
    return http.get('https://flutter-products-7c610.firebaseio.com/products.json?auth=${_authenticatedUser.token}')
      .then<Null>((http.Response response) {
        final List<Product> fetchedProductList = [];
        final Map<String, dynamic> productListData = json.decode(response.body);
        if (productListData == null) {
          _isLoading = false;
          notifyListeners();
          return;
        }
        productListData.forEach((String productId, dynamic productData) {
          final Product product = Product(
            id: productId,
            title: productData['title'],
            description: productData['description'],
            image: productData['image'],
            price: productData['price'],
            userEmail: productData['userEmail'],
            userId: productData['userId'],
            isFavorite:
              productData['wishlistUsers'] == null
                ? false : (productData['wishlistUsers'] as Map<String, dynamic>)
                  .containsKey(_authenticatedUser.id)
          );
          fetchedProductList.add(product);
        });
        // Only show products which belong to this user
        _products = onlyForUser ? fetchedProductList.where((Product product) {
          return product.userId == _authenticatedUser.id;
        }).toList() : fetchedProductList;
        _isLoading = false;
        notifyListeners();
        _selProductId = null;
      })
      .catchError((error) {
        _isLoading = false;
        notifyListeners();
        return false;
      });
  }

  void toggleProductFavoriteStatus() async {
    final bool isCurrentlyFavorite = selectedProduct.isFavorite;
    final bool newFavoriteStatus = !isCurrentlyFavorite;
    // Update local product first
    final Product updatedProduct = Product(
      id: selectedProduct.id,
      title: selectedProduct.title,
      description: selectedProduct.description,
      price: selectedProduct.price,
      image: selectedProduct.image,
      userEmail: selectedProduct.userEmail,
      userId: selectedProduct.userId,
      isFavorite: newFavoriteStatus,
    );
    _products[selectedProductIndex] = updatedProduct;
    // call this function to change this product
    notifyListeners();
    http.Response response;
    if (newFavoriteStatus) {
      response = await http.put('https://flutter-products-7c610.firebaseio.com/products/${selectedProduct.id}/wishlistUsers/${_authenticatedUser.id}.json?auth=${_authenticatedUser.token}',
        body: json.encode(true)
      );
    } else {
      response = await http.delete('https://flutter-products-7c610.firebaseio.com/products/${selectedProduct.id}/wishlistUsers/${_authenticatedUser.id}.json?auth=${_authenticatedUser.token}',
      );
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      // Something wrong
      // Update again
      final Product updatedProduct = Product(
        id: selectedProduct.id,
        title: selectedProduct.title,
        description: selectedProduct.description,
        price: selectedProduct.price,
        image: selectedProduct.image,
        userEmail: selectedProduct.userEmail,
        userId: selectedProduct.userId,
        isFavorite: !newFavoriteStatus,
      );
      _products[selectedProductIndex] = updatedProduct;
      // call this function to change this product
      notifyListeners();
    }
  }

  void selectProduct(String productId) {
    _selProductId = productId;
    if (productId != null) {
      notifyListeners();
    }
  }

  void toggleDisplayMode() {
    _showFavoirtes = !_showFavoirtes;
    notifyListeners();
  }
}

// UserModel class
mixin UserModel on ConnectedProductsModel {
  Timer _authTimer;
  PublishSubject<bool> _userSubject = PublishSubject();

  User get user {
    return _authenticatedUser;
  }

  PublishSubject<bool> get userSubject {
    return _userSubject;
  }

  Future<Map<String, dynamic>> authenticate(String email, String password, [AuthMode mode = AuthMode.Login]) async {
    _isLoading = true;
    notifyListeners();
    final Map<String, dynamic> authData = {
      'email': email,
      'password': password,
      'returnSecureToken': true
    };
    http.Response response;
    if (mode == AuthMode.Login) {
      response = await http.post('https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=AIzaSyDUdw3McLLDCMbOTLHkeoJaIVhpsHsmcjI',
        body: json.encode(authData),
        headers: {'Content-Type': 'application/json'},
      );
    } else {
      response = await http.post(
        'https://www.googleapis.com/identitytoolkit/v3/relyingparty/signupNewUser?key=AIzaSyDUdw3McLLDCMbOTLHkeoJaIVhpsHsmcjI',
        body: json.encode(authData),
        headers: {'Content-Type': 'application/json'}
      );
    }
    final Map<String, dynamic> responseData = json.decode(response.body);
    bool hasError = true;
    String message = 'Something went wrong.';
    if (responseData.containsKey('idToken')) {
      hasError = false;
      message = 'Authentication succeeded.';
      _authenticatedUser = User(
        id: responseData['localId'],
        email: email, token:
        responseData['idToken']
      );
      setAuthTimeout(int.parse(responseData['expiresIn']));
      _userSubject.add(true);
      final DateTime now = DateTime.now();
      final DateTime expiryTime = now.add(Duration(seconds: int.parse(responseData['expiresIn'])));
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('token', responseData['idToken']);
      prefs.setString('userEmail', email);
      prefs.setString('userId', responseData['localId']);
      prefs.setString('expiryTime', expiryTime.toIso8601String());
    } else if (responseData['error']['message'] == 'EMAIL_NOT_FOUND') {
      message = 'This email was not found.';
    } else if (responseData['error']['message'] == 'INVALID_PASSWORD') {
      message = 'This password is invalid.';
    } else if (responseData['error']['message'] == 'EMAIL_EXISTS') {
      message = 'This email already exists.';
    }
    _isLoading = false;
    notifyListeners();
    return {'success': !hasError, 'message': message};
  }

  void autoAuthenticate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String token = prefs.getString('token');
    final String expiryTimeString = prefs.getString('expiryTime');
    if (token != null) {
      final DateTime now = DateTime.now();
      final parsedExpiryTime = DateTime.parse(expiryTimeString);
      if (parsedExpiryTime.isBefore(now)) {
        _authenticatedUser = null;
        notifyListeners();
        return;
      }
      final String userEmail = prefs.getString('userEmail');
      final String userId = prefs.getString('userId');
      final int tokenLifespan = parsedExpiryTime.difference(now).inSeconds;
      _authenticatedUser = User(
        id: userId,
        email: userEmail,
        token: token
      );
      _userSubject.add(true);
      setAuthTimeout(tokenLifespan);
      notifyListeners();
    }
  }

  void logout() async {
    _authenticatedUser = null;
    _authTimer.cancel();
    _userSubject.add(false);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('token');
    prefs.remove('userEmail');
    prefs.remove('userId');
  }

  void setAuthTimeout(int time) {
    _authTimer = Timer(
      Duration(seconds: time),
      () {
        logout();
      }
    );
  }
}

mixin UtilityModel on ConnectedProductsModel {
  bool get isLoading {
    return _isLoading;
  }
}