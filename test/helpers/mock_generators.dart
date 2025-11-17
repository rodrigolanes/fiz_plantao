import 'package:fizplantao/models/plantao.dart';
import 'package:hive/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:uuid/uuid.dart';

// Mock generators for testing
// Note: Interfaces from service files (ISyncService, IAuthService, ICalendarService,
// ISupabaseClient, IConnectivity, etc.) are mocked manually in test files using
// `class MockIInterface extends Mock implements IInterface {}`

@GenerateMocks([
  Box<Plantao>,

  // Utilities
  Uuid,
])
void main() {}
