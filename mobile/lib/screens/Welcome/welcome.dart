import 'package:flutter/material.dart';
import 'package:birdlens/themes/app_colors.dart';
import 'package:birdlens/widgets/widgets.dart';
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
    int currentPage=0;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors['primary'],
    child:SafeArea(
      child:Scaffold(
      backgroundColor: colors['background'],
      body: Container(
        margin: EdgeInsets.only(top:30),
      child:Stack(
      children:[
        PageView(
          controller: _pageController,
          onPageChanged: (index) {
          setState(() {currentPage = index;});},
          children:[
            WelcomePage(
              imgpath:"assets/images/red.png" , 
              title:"Welcome to BirdLens!",
              description: "Upload a photo and discover bird species using AI-powered recognition!.",
              buttonText: "Next",
              onTap: () {
              _pageController.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              );
              },
              ),
              WelcomePage(
              imgpath:"assets/images/woody.png" , 
              title:"Track Your Discoveries!",
              description: "Save favorites and view your identification history anytime.",
              buttonText: "Next",
              onTap: () {
              _pageController.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              );
              },
              ),
            WelcomePage(
              imgpath:"assets/images/peacock.png" , 
              title:"Ready to Explore?",
              description: "Join BirdLens and start discovering birds around you.",
              buttonText: "Get Started",
              onTap: () {
              Navigator.pushNamed(context, "/signIn");
              },
            ),
          ],
        ),
           Positioned(
                  bottom: 130,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3,
                    (index) => Container(
                     margin: const EdgeInsets.symmetric(horizontal: 4),
                     width: currentPage == index ? 20 : 8,
                     height: 8,
                    decoration: BoxDecoration(
                    color: currentPage == index ? colors['primary'] : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
        ),
      ),
    ),
  ),
)
      ]
      ),
      ),
    ),
    ),
    );
  }
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

