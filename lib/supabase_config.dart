import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = 'https://qoxuxvnatvwnxfhxufew.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFveHV4dm5hdHZ3bnhmaHh1ZmV3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5MDQ0NDQsImV4cCI6MjA5NDQ4MDQ0NH0.8hN-EhltMCHrfe-KC8UwSFv_-P1Fjt1t2HHlv22aK60';

SupabaseClient get supabase => Supabase.instance.client;
