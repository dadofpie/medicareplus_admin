
//import 'package:dezu_time_keep/widgets/social_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:medicare_admin_remaster/bloc/auth/auth_bloc.dart';
import 'package:medicare_admin_remaster/screen/home_page.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final empIdController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
  }
  

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          // TODO: implement listener
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
              ),
            );
          }

          if (state is AuthSuccess) {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) =>  HomePage(),
                ),
                (route) => false);
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(
              // Center the spinner when loading
                    child: SpinKitCircle(
                      color: Color(0xff13322B), // Change the color as needed
                      size: 50.0, // Adjust size as needed
                    ),
                  );
          }
          return SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 150),
                  Image.asset(
                        'assets/Medicare.png',
                        height: 200,
                      ),
                      SizedBox(height: height*.09),
                      SizedBox(
                        width: width *.25,
                        child: TextField(
                          controller: empIdController,
                          cursorColor: const Color(0xFF13322B),
                          style: const TextStyle(
                            color:Color(0xFF13322B), // Change this to your desired text color
                            fontSize: 24,
                            fontFamily: "Poppins",
                          ),
                          decoration:  InputDecoration(
                            labelText: 'EMAIL',
                            labelStyle: TextStyle(
                              fontSize: 24,
                              fontFamily: "Poppins",
                              color: const Color(0xFF13322B).withOpacity(0.5),
                            ),
                            border: const UnderlineInputBorder(),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color:Color(0xFF13322B), // Change this for the focused state
                              ),
                            ),
                          ),
                          
                        ),
                      ),
                      SizedBox(height: height*.02),
                      SizedBox(
                        width: width*.25,
                        child: TextField(
                          controller: passwordController,
                          cursorColor: const Color(0xFF13322B),
                          obscureText: !_isPasswordVisible,
                          style: const TextStyle(
                            color: Color(0xFF13322B), // Change this to your desired text color
                            fontSize: 24,
                            fontFamily: "Poppins",
                          ),
                          decoration: InputDecoration(
                            labelText: 'PASSWORD',
                            labelStyle:  TextStyle(
                              fontSize: 24,
                              fontFamily: "Poppins",
                              color: const Color(0xFF13322B).withOpacity(0.5),
                            ),
                            border: const UnderlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: const Color(0xffD8DEE1),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color:Color(0xFF13322B), // Change this for the focused state
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: height*.02),
                      ElevatedButton(
                        onPressed: () {
                        context.read<AuthBloc>().add(
                              AuthLoginRequested(
                                email: empIdController.text.trim(),
                                password: passwordController.text.trim(),
                              ),
                            );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 40),
                          backgroundColor: const Color(0xff13322B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: const Text(
                          'SIGN IN',
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: "Poppins",
                            color: Colors.white,
                          ),
                        ),
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
