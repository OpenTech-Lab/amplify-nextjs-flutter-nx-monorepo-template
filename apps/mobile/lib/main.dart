import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amplify Auth Sample',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
      home: const AuthSamplePage(),
    );
  }
}

class AuthSamplePage extends StatefulWidget {
  const AuthSamplePage({super.key});

  @override
  State<AuthSamplePage> createState() => _AuthSamplePageState();
}

class _AuthSamplePageState extends State<AuthSamplePage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  bool _busy = false;
  bool _configured = false;
  bool _needsConfirmation = false;
  bool _signedIn = false;
  String _status = 'Initializing Amplify...';

  @override
  void initState() {
    super.initState();
    _configureAmplify();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _configureAmplify() async {
    try {
      if (!Amplify.isConfigured) {
        final config = await rootBundle.loadString('amplify_outputs.json');
        await Amplify.addPlugin(AmplifyAuthCognito());
        await Amplify.configure(config);
      }

      final session = await Amplify.Auth.fetchAuthSession();
      setState(() {
        _configured = true;
        _signedIn = session.isSignedIn;
        _status = 'Amplify configured.';
      });
    } catch (error) {
      setState(() {
        _configured = false;
        _status = 'Amplify config failed: $error';
      });
    }
  }

  Future<void> _signUp() async {
    setState(() {
      _busy = true;
      _status = '';
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: email,
          },
        ),
      );

      setState(() {
        _needsConfirmation =
            result.nextStep.signUpStep == AuthSignUpStep.confirmSignUp;
        _status = _needsConfirmation
            ? 'Sign-up complete. Check your email for a confirmation code.'
            : 'Sign-up complete. You can sign in.';
      });
    } catch (error) {
      setState(() {
        _status = 'Sign-up failed: $error';
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _confirmSignUp() async {
    setState(() {
      _busy = true;
      _status = '';
    });

    try {
      await Amplify.Auth.confirmSignUp(
        username: _emailController.text.trim(),
        confirmationCode: _codeController.text.trim(),
      );

      setState(() {
        _needsConfirmation = false;
        _status = 'Account confirmed. Sign in now.';
      });
    } catch (error) {
      setState(() {
        _status = 'Confirm sign-up failed: $error';
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _status = '';
    });

    try {
      final result = await Amplify.Auth.signIn(
        username: _emailController.text.trim(),
        password: _passwordController.text,
      );

      setState(() {
        _signedIn = result.isSignedIn;
        _status = result.isSignedIn
            ? 'Signed in successfully.'
            : 'Sign-in next step: ${result.nextStep.signInStep.name}';
      });
    } catch (error) {
      setState(() {
        _status = 'Sign-in failed: $error';
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _busy = true;
      _status = '';
    });

    try {
      await Amplify.Auth.signOut();
      setState(() {
        _signedIn = false;
        _status = 'Signed out.';
      });
    } catch (error) {
      setState(() {
        _status = 'Sign-out failed: $error';
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Amplify Gen 2 Auth Sample')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            if (_needsConfirmation) ...[
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Confirmation code'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _busy || !_configured ? null : _confirmSignUp,
                child: const Text('Confirm sign up'),
              ),
            ] else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _busy || !_configured ? null : _signUp,
                    child: const Text('Sign up'),
                  ),
                  ElevatedButton(
                    onPressed: _busy || !_configured ? null : _signIn,
                    child: const Text('Sign in'),
                  ),
                  OutlinedButton(
                    onPressed: _busy || !_configured || !_signedIn ? null : _signOut,
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text('Signed in: ${_signedIn ? 'yes' : 'no'}'),
            const SizedBox(height: 8),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
