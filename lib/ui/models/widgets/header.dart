import 'package:kumaanime/core/app/runtimeDatas.dart';
import 'package:kumaanime/ui/pages/search.dart';
import 'package:flutter/material.dart';

Container buildHeader(String title, BuildContext context, {void Function()? afterNavigation}) {
  return Container(
    padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: appTheme.textMainColor,
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const Search())).then((val) {
              if (afterNavigation != null) afterNavigation();
            });
          },
          icon: Icon(
            Icons.search_rounded,
            color: appTheme.textMainColor,
            size: 32,
          ),
        ),
      ],
    ),
  );
}

