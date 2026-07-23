import Foundation

/// Konfigurace Supabase projektu Hokejbal (eu-central-1).
enum SupabaseConfig {
    static let projectURL = URL(string: "https://uqnptbznnbeldtuvywtt.supabase.co")!
    /// Anon / publishable klíč — bezpečný pro klienta (RLS: jen SELECT).
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVxbnB0YnpubmJlbGR0dXZ5d3R0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ2MzI0OTcsImV4cCI6MjEwMDIwODQ5N30.8JNL3wwYUtzhoXAzdn3QG5b00drbQrcXcS0JYDHIwjw"

    static var restURL: URL { projectURL.appendingPathComponent("rest/v1") }
}
