import 'package:flutter/material.dart';
import 'package:TeaLink/constants/colors.dart';

class FrontPage extends StatelessWidget {
  const FrontPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        
        body: 
      
             Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Center(
                  child: Text(
                    "Welcome",
                  style: TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: kMainColor,
                  ),),
                           ),
            const SizedBox(
              height: 5,
            ),
        
            Image.asset('assets/images/TeaLink.png',
            height: 400,
            width: 400,
            ),
            const SizedBox(
              height: 40,
            ),
               ],
             ),
        
            
            
      ),
    );
  }
}