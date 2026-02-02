import Foundation
import Supabase

enum SupabaseClientError: LocalizedError {
    case missingConfig(String)

    var errorDescription: String? {
        switch self {
        case .missingConfig(let key):
            return "Missing Supabase config: \(key). Check Config.xcconfig and Info.plist."
        }
    }
}

struct SupabaseConfig {
    static var url: URL {
        guard let urlString = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
              !urlString.isEmpty,
              urlString != "YOUR_SUPABASE_URL_HERE",
              let url = URL(string: urlString) else {
            fatalError("SUPABASE_URL not configured in Config.xcconfig")
        }
        return url
    }

    static var anonKey: String {
        guard let key = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String,
              !key.isEmpty,
              key != "YOUR_SUPABASE_ANON_KEY_HERE" else {
            fatalError("SUPABASE_ANON_KEY not configured in Config.xcconfig")
        }
        return key
    }

    static var devPassword: String? {
        guard let pw = Bundle.main.infoDictionary?["DEV_SUPABASE_PASSWORD"] as? String,
              !pw.isEmpty,
              pw != "YOUR_DEV_PASSWORD_HERE" else {
            return nil
        }
        return pw
    }
}

let supabase: SupabaseClient = {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .iso8601

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601

    return SupabaseClient(
        supabaseURL: SupabaseConfig.url,
        supabaseKey: SupabaseConfig.anonKey,
        options: .init(
            db: .init(encoder: encoder, decoder: decoder)
        )
    )
}()
