class KumaAnimeEnvironment {
  static const String simklClientId = String.fromEnvironment("SIMKL_CLIENT_ID");
  static const String simklClientSecret =
      String.fromEnvironment("SIMKL_CLIENT_SECRET");
  static const String commentumApiUrl =
      String.fromEnvironment("COMMENTUM_API_URL");
  static const String subIndoApiUrl = String.fromEnvironment(
    "SUBINDO_API_URL",
    defaultValue: "https://wajik-anime-api.vercel.app",
  );
}
