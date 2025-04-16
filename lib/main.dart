import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medicare_admin_remaster/screen/login_page.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/domain/repositories/admin_repository.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/domain/usecases/fetch_all_admin.dart';
import 'package:medicare_admin_remaster/screen/subpages/admin_interface/presentation/bloc/admin/admin_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bloc/auth/auth_bloc.dart';

void main() async {
  
  await Supabase.initialize(
    url: 'https://hsdwccwygehmawjdyzkr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhzZHdjY3d5Z2VobWF3amR5emtyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjcwNTExNTMsImV4cCI6MjA0MjYyNzE1M30.B9pE60Fnv91y2QfMWHeHYqg7ol6YhHmuftz-X5msXwk',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => AdminRepository(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => AuthBloc()),
          BlocProvider(
            create: (context) => AdminBloc(
              fetchAllAdmin: FetchAllAdmin(
                adminEntriesRepository: context.read<AdminRepository>(),
              ),
            ),
          )
        ],
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Medicareplus Admin',
            theme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: const Color.fromARGB(255, 249, 249, 252),
            ),
            initialRoute: '/',
            routes: {
              '/': (context) => const LoginScreen(),
            }),
      ),
    );
  }
}
