import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/presentation/bloc/admin/admin_bloc.dart';
import 'package:medicare_admin_remaster/shared/api.dart';
import 'package:medicare_admin_remaster/shared/list.dart';
import 'package:medicare_admin_remaster/widget/custom_textform_field.dart';
import 'package:http/http.dart' as http;
import 'package:medicare_admin_remaster/widget/list_dropdown.dart';

class AddAdminDialog extends StatefulWidget {
  const AddAdminDialog({super.key});

  @override
  State<AddAdminDialog> createState() => _AddAdminDialogState();
}

class _AddAdminDialogState extends State<AddAdminDialog> {

  final TextEditingController fnameController = TextEditingController();
  final TextEditingController mnameController = TextEditingController();
  final TextEditingController lnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController contactNoController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  bool _isLoading=false;
  String? selectedRole;
  String label='Select Role';
  final _formKey = GlobalKey<FormState>();

void _showMessage(String message, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
              side: const BorderSide(color: Color(0xff13322b), width: 2)),
          title: Center(
              child: Text(
            title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xff13322b)),
          )),
          content: Text(message,
              style: const TextStyle(fontSize: 16, color: Color(0xff13322b))),
          actions: <Widget>[
            TextButton(
              child: const Text("OK",
                  style: TextStyle(fontSize: 16, color: Color(0xff13322b))),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
          backgroundColor: Colors.white,
          content: SizedBox(
              width: 800,
              height: 350,
              child:_isLoading
                ? const Center(child: SpinKitCircle(color: Color(0xff13322b), size: 50.0)): Form(
                  key: _formKey,
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Add Admin',
                        style: TextStyle(
                          color: Color(0xff13322b),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20), // Space above the title
                  
                            // Personal Details Title
                            Container(
                              alignment:
                                  Alignment.centerLeft, // Align to the left
                              child: const Text(
                                "Name and Contact Information", // Title for the radio buttons
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff13322b), // Set title color
                                ),
                                textAlign:
                                    TextAlign.left, // Align text to the left
                              ),
                            ),
                            const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextFormField(
                            label:const Row(
                                          children: [
                                            Text('First Name', style: TextStyle(color: Colors.black)),
                                            Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                          ],
                                        ),
                            labelStyle: const TextStyle(
                              color: Color(0xff13322b),
                              fontSize: 14,
                            ),
                            controller: fnameController,
                            isNumeric: false,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'First name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomTextFormField(
                            label:const Row(
                                          children: [
                                            Text('Middle Name', style: TextStyle(color: Colors.black)),
                                            Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                          ],
                                        ),
                            labelStyle: const TextStyle(
                              color: Color(0xff13322b),
                              fontSize: 14,
                            ),
                            controller: mnameController,
                            isNumeric: false,
                            validator: (value) {
                              /*if (value == null || value.isEmpty) {
                                return 'Middle name is required';
                              }*/
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomTextFormField(
                            label:const Row(
                                          children: [
                                            Text('Last Name', style: TextStyle(color: Colors.black)),
                                            Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                          ],
                                        ),
                            labelStyle: const TextStyle(
                              color: Color(0xff13322b),
                              fontSize: 14,
                            ),
                            controller: lnameController,
                            isNumeric: false,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Last name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextFormField(
                            label:const Row(
                                          children: [
                                            Text('Email Address', style: TextStyle(color: Colors.black)),
                                            Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                          ],
                                        ),
                            labelStyle: const TextStyle(
                              color: Color(0xff13322b),
                              fontSize: 14,
                            ),
                            controller: emailController,
                            isNumeric: false,
                            isEmail: true,
                            validator: (value) {
                              final regExp = RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                              );
                              if (value == null || value.isEmpty) {
                                return 'Email address is required';
                              } else if (value.length < 6) {
                                return 'Email address must be at least 6 characters long';
                              } else if (!value.endsWith('.com')) {
                                return 'Email address must end with ".com"';
                              } else if (!regExp.hasMatch(value)) {
                                return 'Please input a valid email';
                              } 
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomTextFormField(
                            label:const Row(
                                          children: [
                                            Text('Password', style: TextStyle(color: Colors.black)),
                                            Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                          ],
                                        ),
                            labelStyle: const TextStyle(
                              color: Color(0xff13322b),
                              fontSize: 14,
                            ),
                            controller: passwordController,
                            isNumeric: false,
                            isEmail: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }else if(passwordController.text.length<6){
                                return 'Password must be 6 in length';
                              }
                              return null;
                            },
                            isObscure: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomTextFormField(
                            label:const Row(
                                          children: [
                                            Text('Contact No', style: TextStyle(color: Colors.black)),
                                            Text(' *', style: TextStyle(color: Colors.red)), // Asterisk in red
                                          ],
                                        ),
                            labelStyle: const TextStyle(
                              color: Color(0xff13322b),
                              fontSize: 14,
                            ),
                            controller: contactNoController,
                            isNumeric: true,
                            validator: (value) {
                              final regExp = RegExp(r'^\d+$');
                              if (value == null || value.isEmpty) {
                                return 'Contact number is required';
                              }else if (value.isNotEmpty &&
                                  !regExp.hasMatch(value)) {
                                return 'Please enter a valid number';
                              }else if(value.length<11){
                                return 'Contact number must be 11 digits';
                              }
                              return null;
                            },
                            maxLength: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: CustomListDropdownFormField(
                            label: label,
                            labelStyle: const TextStyle(
                              color: Color(0xff13322b),
                            ),
                            items: adminTypeItems,
                            controller: roleController,
                            onChanged: (selectedItem) {
                              //_showMessage("Role is required", 'Error');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 200, // Set your desired width
                      height: 40, // Set your desired height
                      child: ElevatedButton(
                        onPressed: () async {
                          if(roleController.text.isEmpty){
                            setState(() {
                              label='Please select role type';
                            });
                          }
                          if (!_formKey.currentState!.validate())return;
                          
                          if(fnameController.text.isNotEmpty && lnameController.text.isNotEmpty && emailController.text.isNotEmpty && passwordController.text.isNotEmpty && roleController.text.isNotEmpty){
                            
                            setState(() {
                              _isLoading=true;
                            });
                            String url = 'https://medicareplus-api.vercel.app/api/admin/add_admin'; // Replace with your actual API URL
                            final Map<String, String> headers = {
                              'supabase-url': supabaseUrl, // Replace with your Supabase URL
                              'supabase-key': supabaseKey, // Replace with your Supabase Key
                              'Content-Type': 'application/json',
                            };
                  
                            final Map<String, dynamic> body = {
                              'admin_type': roleController.text,
                              'fname': fnameController.text,
                              'mname': mnameController.text,
                              'lname': lnameController.text,
                              'email': emailController.text,
                              'password': passwordController.text,
                              'contact_no': contactNoController.text,
                              'department_id':roleController.text
                              // Add any other fields as necessary
                            };
                  
                            try {
                              final response = await http.post(
                                Uri.parse(url),
                                headers: headers,
                                body: jsonEncode(body),
                              );
                  
                              if (response.statusCode == 200) {
                                final data = jsonDecode(response.body);
                                // Handle success (e.g., show a success message)
                                Navigator.of(context).popUntil((route) => route.isFirst);
                                _showMessage('New user added','Successfully Added');
                                roleController.text='';
                                fnameController.text='';
                                mnameController.text='';
                                lnameController.text='';
                                emailController.text='';
                                passwordController.text='';
                                contactNoController.text='';
                                roleController.text='';
                                _isLoading=false;
                                context.read<AdminBloc>().add(FetchAdminAccountsEvent());
                              } else {
                                final errorData = jsonDecode(response.body);
                                // Handle error (e.g., show an error message)
                                _isLoading=false;
                                _showMessage('User not added on database','Error in creation');
                              }
                            } catch (e) {
                              // Handle unexpected errors
                              _isLoading=false;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('An error occurred: $e')),
                              );
                            }
                  
                          }
                                                },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)),
                          backgroundColor: const Color(0xff13322b),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        child: const Text('Add Admin', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                                ),
                )));
  }
}