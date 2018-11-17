import 'dart:convert';

import 'package:scoped_model/scoped_model.dart';
import 'package:http/http.dart' as http;

import '../models/product.dart';
import '../models/user.dart';

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
      final http.Response res = await http.post('https://flutter-products-7c610.firebaseio.com/products.json',
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
    return http.put('https://flutter-products-7c610.firebaseio.com/products/${selectedProduct.id}.json',
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
    return http.delete('https://flutter-products-7c610.firebaseio.com/products/${deletedProductId}.json')
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

  Future<Null> fetchProducts() {
    _isLoading = true;
    notifyListeners();
    return http.get('https://flutter-products-7c610.firebaseio.com/products.json')
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
            userId: productData['userId']
          );
          fetchedProductList.add(product);
        });
        _products = fetchedProductList;
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

  void toggleProductFavoriteStatus() {
    final bool isCurrentlyFavorite = selectedProduct.isFavorite;
    final bool newFavoriteStatus = !isCurrentlyFavorite;
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

  void login(String email, String password) {
  _authenticatedUser = User(
      id: 'fafafafa',
      email: email,
      password: password
    );
  }
}

mixin UtilityModel on ConnectedProductsModel {
  bool get isLoading {
    return _isLoading;
  }
}