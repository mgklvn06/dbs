import 'package:dbs/config/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterPage extends StatelessWidget {
  RegisterPage({super.key});

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
        body: SafeArea(
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (state is AuthAuthenticated) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  Routes.authRedirect,
                  (route) => false,
                );
              }
            },
            builder: (context, state) {
              return Stack(
                children: [
                  _buildContent(context),
                  if (state is AuthLoading)
                    const _LoadingOverlay(),
                ],
              );
            },
          ),
        ),
      );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),

          // App identity
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Create your account',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Book appointments faster and easier',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Email
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),

          const SizedBox(height: 16),

          // Password
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),

          const SizedBox(height: 24),

          // Register button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                context.read<AuthBloc>().add(
                      RegisterRequested(
                        _emailController.text.trim(),
                        _passwordController.text,
                      ),
                    );
              },
              child: const Text('Create Account'),
            ),
          ),

          const SizedBox(height: 32),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Already have an account? "),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Sign in'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
