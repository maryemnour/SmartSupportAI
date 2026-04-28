class AppConfig {
  AppConfig._();
  static const String supabaseUrl      = 'https://tuhlbdxrmtluwrxsbtct.supabase.co';
  static const String supabaseAnonKey  = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR1aGxiZHhybXRsdXdyeHNidGN0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwMTU5NDUsImV4cCI6MjA4ODU5MTk0NX0.krJR766NAPYQmckHEds_zSDZ_h5KrncSvJ9bKXIfuqY';

  // ML API URL — overridable at build time via:
  //   flutter build web --dart-define=ML_API_URL=https://your-ml-api.onrender.com
  // Default = Render service from render.yaml (name: smartsupport-ml-api).
  // For local dev: flutter run --dart-define=ML_API_URL=http://localhost:8000
  static const String mlApiUrl = String.fromEnvironment(
    'ML_API_URL',
    defaultValue: 'https://smartsupport-ml-api.onrender.com',
  );

  static const String defaultCompanyId = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
}
