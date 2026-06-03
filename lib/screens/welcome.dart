import 'package:flutter/material.dart';

class WelcomeTo extends StatelessWidget {
  const WelcomeTo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],

      body: Stack(
        children: [

          // CONTENT
          Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [

                Image.asset(
                  'images/welcome.png',
                  width: 220,
                ),

                const SizedBox(height: 24),

                Text(
                  "WELCOME TO",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.blue[900],
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Student Task",
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.blue[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  "Kelola tugas sekolahmu\nlebih mudah dan cepat",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          // BUTTON BAWAH
          Positioned(
            bottom: 40,
            right: 20,

            child: Material(
              color: Colors.transparent,

              child: InkWell(

                borderRadius:
                    BorderRadius.circular(30),

                onTap: () {

                  Navigator.pushNamed(
                    context,
                    '/login',
                  );
                },

                child: Container(

                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(30),

                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),

                  child: Row(
                    mainAxisSize: MainAxisSize.min,

                    children: [

                      // DOTS
                      Row(
                        children: List.generate(
                          5,
                          (index) {

                            return Container(
                              margin:
                                  const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),

                              width: 6,
                              height: 6,

                              decoration: BoxDecoration(
                                color: index == 4
                                    ? Colors.grey[800]
                                    : Colors.grey[400],

                                shape: BoxShape.circle,
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 10),

                      // ARROW
                      Container(
                        padding:
                            const EdgeInsets.all(6),

                        decoration: BoxDecoration(
                          color: Colors.blue[300],
                          shape: BoxShape.circle,
                        ),

                        child: const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}