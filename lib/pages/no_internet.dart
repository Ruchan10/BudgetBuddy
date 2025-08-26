import 'package:budgget_buddy/core/context_extension.dart';
import 'package:budgget_buddy/core/listen_internet.dart';
import 'package:budgget_buddy/core/routes.dart';
import 'package:budgget_buddy/core/snackbar.dart';
import 'package:flutter/material.dart';

class NoInternetPage extends StatelessWidget {
  const NoInternetPage({super.key});

  @override
  Widget build(BuildContext context) {
    void navigateToSplash() {
      Navigator.popAndPushNamed(context, AppRoute.splashRoute);
    }

    void showSnackbar() {
      showSnackBar(
        context: context,
        message: 'No internet connection',
        color: Colors.red,
      );
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.widthDivisor(22)), 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: context.widthDivisor(5),
                color: Colors.redAccent,
              ),
              SizedBox(height: context.widthDivisor(45)),
              Text(
                'No Internet Connection',
                style: TextStyle(
                  fontSize: context.widthDivisor(24),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: context.widthDivisor(57),
              ),
              Text(
                'Please check your network settings and try again',
                style: TextStyle(
                  fontSize: context.widthDivisor(45),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.widthDivisor(30)), 
              SizedBox(
                width: context.widthPercent(50),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(
                        vertical: context.widthDivisor(57)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        context.widthDivisor(76),
                      ),
                    ),
                  ),
                  onPressed: () async {
                    bool hasInternet = await NetworkService.checkNetwork();
                    if (hasInternet) {
                      navigateToSplash();
                    } else {
                      showSnackbar();
                    }
                  },
                  child: Text(
                    'RETRY CONNECTION',
                    style: TextStyle(
                      fontSize: context.widthDivisor(45),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
