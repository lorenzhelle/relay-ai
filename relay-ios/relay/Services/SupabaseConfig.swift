import Foundation

/// Supabase project credentials read from Info.plist (set via Config.xcconfig).
enum SupabaseConfig {
    /// Supabase project base URL. Set the `SUP_HOST` key in Config.xcconfig
    /// (host only, no https:// — xcconfig treats // as a comment).
    static let url: URL = {
        if let host = Bundle.main.object(forInfoDictionaryKey: "SUP_HOST") as? String,
           !host.hasPrefix("$("),
           !host.isEmpty,
           let url = URL(string: "https://\(host)") {
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
