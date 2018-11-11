import 'dart:async';

import 'package:flutter/material.dart';

class ProductPage extends StatelessWidget {
  final String _title;
  final String _imageUrl;
  final String _description;
  final double _price;

  ProductPage(this._title, this._imageUrl, this._description, this._price);

  _showWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Are you sure?'),
        content: Text('This action cannot be undone!'),
        actions: <Widget>[
          FlatButton(child: Text('DISCARD'), onPressed: () {
            Navigator.pop(context);
          },),
          FlatButton(child: Text('CONTINUE'), onPressed: () {
            Navigator.pop(context);
            Navigator.pop(context, true);
          },),
        ],
      );
    });
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        print('Back button pressed.');
        Navigator.pop(context, false);
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Image.asset(_imageUrl),
            // Title and price
            Container(
              padding: EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    _title,
                    style: TextStyle(
                      fontSize: 30.0,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(
                    width: 8.0,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(5.0)
                    ),
                    child: Text(
                      '\$${_price.toString()}',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
            // Address
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.5),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey,
                  width: 1.0
                ),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Text('Union Square, San Francisco'),
            ),
            // Description
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.5),
              child: Text(
                _description,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.normal,
                  fontFamily: 'Oswald'
                ),
              ),
            ),
            Container(
              child: RaisedButton(
                color: Theme.of(context).accentColor,
                child: Text('DELETE'),
                onPressed: () => _showWarningDialog(context),
              ),
            )
          ],
        )
      ),
    );
  }
}
