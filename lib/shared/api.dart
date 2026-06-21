const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'prod');
const useSupabase = bool.fromEnvironment('USE_SUPABASE', defaultValue: true);
const includeSupabaseHeaders =
    bool.fromEnvironment('INCLUDE_SUPABASE_HEADERS', defaultValue: true);
const enableLocalAuthMock =
    bool.fromEnvironment('ENABLE_LOCAL_AUTH_MOCK', defaultValue: false);

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.app.medicareplus.com.ph',
);

const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://hsdwccwygehmawjdyzkr.supabase.co',
);

const supabaseKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhzZHdjY3d5Z2VobWF3amR5emtyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjcwNTExNTMsImV4cCI6MjA0MjYyNzE1M30.B9pE60Fnv91y2QfMWHeHYqg7ol6YhHmuftz-X5msXwk',
);

const apiUrl = '$apiBaseUrl/api/admin';

const localTestAdminEmail = String.fromEnvironment(
  'LOCAL_TEST_ADMIN_EMAIL',
  defaultValue: 'test.admin@medicare.local',
);

const localTestAdminPassword = String.fromEnvironment(
  'LOCAL_TEST_ADMIN_PASSWORD',
  defaultValue: 'Test123456',
);

const localTestAdminDepartmentId = int.fromEnvironment(
  'LOCAL_TEST_ADMIN_DEPARTMENT_ID',
  defaultValue: 1,
);

const ggxUrl = 'https://api.staging.quadx.xyz';
const secretKey = 'b446261ed0e6879f3b6f1adf4d582d4f';
const ggxApiKey = '187926583f08b52845';

String adminEndpoint(String path) {
  final normalized = path.startsWith('/') ? path.substring(1) : path;
  return '$apiUrl/$normalized';
}

String rootEndpoint(String path) {
  if (path.startsWith('/')) {
    return '$apiBaseUrl$path';
  }
  return '$apiBaseUrl/$path';
}

Map<String, String> buildApiHeaders({
  bool includeContentType = true,
  Map<String, String>? extra,
}) {
  final headers = <String, String>{};
  if (includeContentType) {
    headers['Content-Type'] = 'application/json';
  }
  if (includeSupabaseHeaders) {
    headers['supabase-url'] = supabaseUrl;
    headers['supabase-key'] = supabaseKey;
  }
  if (extra != null) {
    headers.addAll(extra);
  }
  return headers;
}
