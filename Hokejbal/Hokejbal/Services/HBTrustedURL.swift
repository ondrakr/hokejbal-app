import Foundation

/// Bezpečné otevírání / fetch URL — jen https a důvěryhodní hostitelé.
enum HBTrustedURL {
    /// Hostitelé povolené pro Link / open (streamy, partneři).
    private static let openHosts: Set<String> = [
        "hokejbal.cz",
        "www.hokejbal.cz",
        "cmshb.cz",
        "www.cmshb.cz",
        "youtube.com",
        "www.youtube.com",
        "m.youtube.com",
        "youtu.be",
        "ceskatelevize.cz",
        "www.ceskatelevize.cz",
        "isbhf.com",
        "www.isbhf.com",
        "supabase.co"
    ]

    /// Hostitelé povolené pro stažení HTML těla článku.
    private static let fetchHosts: Set<String> = [
        "hokejbal.cz",
        "www.hokejbal.cz"
    ]

    static func openable(_ raw: String?) -> URL? {
        guard let url = normalizedHTTPS(raw), let host = url.host?.lowercased() else { return nil }
        guard isHost(host, allowed: openHosts) else { return nil }
        return url
    }

    static func fetchable(_ raw: String?) -> URL? {
        guard let url = normalizedHTTPS(raw), let host = url.host?.lowercased() else { return nil }
        guard isHost(host, allowed: fetchHosts) else { return nil }
        return url
    }

    /// Sanitizace ID pro PostgREST filtry (bez čárek, závorek, teček v operátorech).
    static func sanitizeFilterId(_ id: String) -> String? {
        let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 128 else { return nil }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        guard trimmed.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return nil }
        return trimmed
    }

    private static func normalizedHTTPS(_ raw: String?) -> URL? {
        guard var s = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        if s.hasPrefix("//") { s = "https:" + s }
        guard let url = URL(string: s), let scheme = url.scheme?.lowercased(), scheme == "https" else { return nil }
        return url
    }

    private static func isHost(_ host: String, allowed: Set<String>) -> Bool {
        if allowed.contains(host) { return true }
        // Subdomény supabase storage apod.
        return allowed.contains { host == $0 || host.hasSuffix("." + $0) }
    }
}
