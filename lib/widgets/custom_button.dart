import 'package:flutter/material.dart';
import 'package:tealink/constants/colors.dart';

class CustemButton extends StatelessWidget {

  final String buttonName;
  final Color buttonColor;


  const CustemButton({super.key, required this.buttonName, required this.buttonColor});

  @override
  Widget build(BuildContext context) {
    return  Container(

      height: MediaQuery.of(context).size.height * 0.06,
     

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: buttonColor,
      ) ,
      child: Center(
        child: Text(
          buttonName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: kWhite,
          )
        ),
      ),
    );
  }
}