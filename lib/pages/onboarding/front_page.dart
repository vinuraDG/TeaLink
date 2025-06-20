import 'package:flutter/material.dart';
import 'package:tealink/constants/colors.dart';

class FrontPage extends StatelessWidget {
  const FrontPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage('assets/images/background.jpg'),
        fit: BoxFit.cover,)
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
                    color: kWhite,
                  ),),
                           ),
            const SizedBox(
              height: 5,
            ),
        
            Image.asset('assets/images/TeaLink_R.png',
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