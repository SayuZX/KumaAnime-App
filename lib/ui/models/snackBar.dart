import "dart:io";

import "package:kumaanime/main.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

void floatingSnackBar(String message, {int? duration, bool waitForPreviousToFinish = false}) {
  final isWindows = Platform.isWindows;
  if (!waitForPreviousToFinish) KumaAnime.snackbarKey.currentState?.removeCurrentSnackBar();
  KumaAnime.snackbarKey.currentState?.showSnackBar(
      SnackBar(
        content: Center(
          child: Text(message, style: TextStyle(fontFamily: "NotoSans", color: Colors.white, fontSize: 14)),
        ),
        duration: Duration(seconds: duration != null ? duration : 3),
        backgroundColor: Color.fromARGB(244, 61, 61, 61),
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.down,
        margin: isWindows ? null : EdgeInsets.only(bottom: 40, left: 20, right: 20),
        width: isWindows ? MediaQuery.of(KumaAnime.snackbarKey.currentState!.context).size.width / 5 : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
}

void showToast(String message) async {
  final platform = MethodChannel('kumaanime.app/utils');
  await platform.invokeMethod("showToast", {'message': message});
}