import 'package:flutter/material.dart';

class AuthPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _AuthPageState();
  }
}

class _AuthPageState extends State<AuthPage> {
  String _emailValue;
  String _passwordValue;
  bool _acceptTerms = false;

  DecorationImage _buildBackgroundImage() {
    return DecorationImage(
        fit: BoxFit.cover,
        colorFilter:
            ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.dstATop),
        image: AssetImage('assets/background.jpg'));
  }

  Widget _buildEmailTextField() {
    return TextField(
      decoration: InputDecoration(
          labelText: 'E-mail', filled: true, fillColor: Colors.white),
      keyboardType: TextInputType.emailAddress,
      onChanged: (String value) {
        setState(() {
          _emailValue = value;
        });
      },
    );
  }

  Widget _buildPasswordTextField() {
    return TextField(
      obscureText: true,
      decoration: InputDecoration(
          labelText: 'Password', filled: true, fillColor: Colors.white),
      onChanged: (String value) {
        setState(() {
          _passwordValue = value;
        });
      },
    );
  }

  Widget _buildAcceptSwitch() {
    return SwitchListTile(
      value: _acceptTerms,
      onChanged: (bool value) {
        setState(() {
          _acceptTerms = value;
        });
      },
      title: Text('Accept Terms'),
    );
  }

  void _submitForm() {
    print(_emailValue);
    print(_passwordValue);
    Navigator.pushReplacementNamed(context, '/products');
  }

  @override
  Widget build(BuildContext context) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    final double targetWidth = deviceWidth > 550.0 ? 500.0 : deviceWidth * 0.95;
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: _buildBackgroundImage(),
        ),
        padding: EdgeInsets.all(15.0),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: targetWidth,
              child: Column(
                children: <Widget>[
                  _buildEmailTextField(),
                  SizedBox(
                    height: 10.0,
                  ),
                  _buildPasswordTextField(),
                  _buildAcceptSwitch(),
                  SizedBox(
                    height: 10.0,
                  ),
                  RaisedButton(
                    textColor: Colors.white,
                    child: Text('LOGIN'),
                    onPressed: _submitForm,
                  ),
                ]
              )
            ),
          )
        ),
      ),
    );
  }
}
