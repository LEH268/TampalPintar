// See README.md "Configure the codebase" for where these two values come from.
const kSupabaseUrl = 'https://YOUR_PROJECT_REF.supabase.co';
const kSupabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
const kWakeThreshold = 0.28;
const kWakeDebounce = Duration(seconds: 3);
const kGpsFixTimeout = Duration(seconds: 8);
const kDashcamConnectedWindow = Duration(seconds: 10);
const kDashcamPollInterval = Duration(seconds: 5);
const kPhotoPollInterval = Duration(milliseconds: 1500);
const kPhotoPollTimeout = Duration(seconds: 15);
const kPinRefetchInterval = Duration(seconds: 15);
