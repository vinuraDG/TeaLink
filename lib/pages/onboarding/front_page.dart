import 'package:flutter/material.dart';
import 'package:tealink/constants/colors.dart';

class FrontPage extends StatelessWidget {
  const FrontPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Stack(

        children: [

          Positioned.fill(
            child: Image.asset(
              "assets/images/background.jpg", // Replace with your background image path
              fit: BoxFit.cover,
            ),
          ),

           Column(
             children: [
               Center(
                child: Text(
                  "Welcome",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: kWhite,
                ),),
                         ),
                         const SizedBox(
            height: 20,
          ),
      
          Image.asset("assets/images/TeaLink_R.png",
          height: 400,
          width: 400,),
             ],
           ),
      
          
          
        ],
      ),
    );
  }
}