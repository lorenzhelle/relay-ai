import Foundation

/// Supabase project credentials read from Info.plist (set via Config.xcconfig).
enum SupabaseConfig {
    /// Supabase project base URL. Set the `SUP_URL` key in Config.xcconfig.
    static let url: URL = {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "SUP_URL") as? String,
           let url = URL(string: raw),
           !raw.hasPrefix("$(") {
            return url
        }
        return URL(string: "https://your-project.supabase.co")!
    }()

    /// Supabase publishable / anon key. Set the `SUP_ANON_KEY` key in Config.xcconfig.
    /// Needed both for Edge Functions and the Realtime WebSocket.
    static let anonKey: String = {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "SUP_ANON_KEY") as? String,
           !raw.hasPrefix("$(") {
            return raw
        }
        return ""
    }()
}
