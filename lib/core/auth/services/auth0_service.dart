import 'package:auth0_flutter/auth0_flutter.dart';

class Auth0Service {
  // Using the domain provided by the user.
  static const _domain = 'dev-ywrjgp3xrbo1nafe.us.auth0.com';
  // PLACEHOLDER: Replace with actual Client ID from Auth0 Dashboard
  static const _clientId = '<YOUR_AUTH0_CLIENT_ID>';

  late final Auth0 _auth0;

  Auth0Service() {
    _auth0 = Auth0(_domain, _clientId);
  }

  Future<Credentials> login() async {
    return await _auth0.webAuthentication(scheme: 'https').login();
  }

  Future<void> logout() async {
    await _auth0.webAuthentication(scheme: 'https').logout();
  }

  Future<UserProfile> getUserProfile(String accessToken) async {
    return await _auth0.api.userProfile(accessToken: accessToken);
  }
}
