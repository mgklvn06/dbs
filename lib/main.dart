import 'package:dbs/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'firebase_options.dart';
import 'config/dependecy_injection.dart';
import 'app.dart';

void  main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initDependencies();

  runApp(
    BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: const MyApp(),
    ),
  );
}
