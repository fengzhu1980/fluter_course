import 'package:flutter/material.dart';

import 'package:scoped_model/scoped_model.dart';

import './product_edit.dart';
import '../scoped-models/main.dart';

class ProductListPage extends StatefulWidget {
  final MainModel model;

  ProductListPage(this.model);

  @override
    State<StatefulWidget> createState() {
      return _ProductListPageState();
    }
}

class _ProductListPageState extends State<ProductListPage> {
  initState() {
    widget.model.fetchProducts(onlyForUser: true);
    super.initState();
  }
  
  Widget _buildEditButton(BuildContext context, int index, MainModel model) {
    return IconButton(
      icon: Icon(Icons.edit),
      onPressed: () {
        model.selectProduct(model.allproducts[index].id);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (BuildContext context) {
              return ProductEditPage();
            }
          )
        ).then((_) {
          model.selectProduct(null);
        });
      },
    );
  }

  @override
    Widget build(BuildContext context) {
      return ScopedModelDescendant<MainModel>(
      builder: (
        BuildContext context,
        Widget child,
        MainModel model
      ) {
        return ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            return Dismissible(
              key: Key(model.allproducts[index].title),
              onDismissed: (DismissDirection direction) {
                if (direction == DismissDirection.endToStart) {
                  model.selectProduct(model.allproducts[index].id);
                  model.deleteProduct();
                } else if (direction == DismissDirection.startToEnd) {
                  print('start to end');
                } else {
                  print('Other swiping');
                }
              },
              background: Container(color: Colors.red,),
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(model.allproducts[index].image)
                    ),
                    title: Text(model.allproducts[index].title),
                    subtitle: Text('\$${model.allproducts[index].price.toString()}'),
                    trailing: _buildEditButton(context, index, model),
                  ),
                  Divider()
                ],
              )
            );
          },
          itemCount: model.allproducts.length,
        );
      },
    );
  }
}