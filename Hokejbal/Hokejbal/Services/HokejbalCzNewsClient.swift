import Foundation

/// Načte aktuální články přímo z homepage hokejbal.cz (včetně fotek).
enum HokejbalCzNewsClient {
    private static let homeURL = URL(string: "https://www.hokejbal.cz")!
    private static let imageBase = "https://www.hokejbal.cz/image?exact&topcut&w=800&h=500&file=photo/article/article_"

    static func fetch(limit: Int = 12) async throws -> [NewsArticle] {
        var request = URLRequest(url: homeURL)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1)
        else {
            throw URLError(.badServerResponse)
        }

        return parse(html: html, limit: limit)
    }

    static func parse(html: String, limit: Int) -> [NewsArticle] {
        // Preferuj odkaz s viditelným textem (titulek v <a>…</a>).
        let linkPattern = #"<a[^>]+href="(/clanek/(\d+)-([^"']+))"[^>]*>(.*?)</a>"#
        guard let linkRegex = try? NSRegularExpression(pattern: linkPattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else {
            return []
        }

        let ns = html as NSString
        let matches = linkRegex.matches(in: html, range: NSRange(location: 0, length: ns.length))

        var seen = Set<String>()
        var articles: [NewsArticle] = []
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "cs_CZ")
        dateFormatter.dateFormat = "d. MM. yyyy"

        for match in matches {
            guard match.numberOfRanges >= 5,
                  let idRange = Range(match.range(at: 2), in: html),
                  let slugRange = Range(match.range(at: 3), in: html),
                  let pathRange = Range(match.range(at: 1), in: html),
                  let innerRange = Range(match.range(at: 4), in: html)
            else { continue }

            let id = String(html[idRange])
            if seen.contains(id) { continue }

            let innerHTML = String(html[innerRange])
            let title = stripTags(innerHTML)
                .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            // Přeskoč čistě navigační / prázdné odkazy.
            guard title.count >= 20 else { continue }
            seen.insert(id)

            let slug = String(html[slugRange])
            let path = String(html[pathRange])
            let articleURL = "https://www.hokejbal.cz\(path)"
            let imageURL = "\(imageBase)\(id).jpg"

            let start = max(0, match.range.location - 600)
            let end = min(ns.length, match.range.location + match.range.length + 200)
            let chunk = ns.substring(with: NSRange(location: start, length: end - start))
            let plain = stripTags(chunk)
                .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)

            let category = detectCategory(in: plain) ?? "Novinky"
            let publishedAt = detectDate(in: plain, formatter: dateFormatter) ?? Date()

            articles.append(
                NewsArticle(
                    id: id,
                    title: title,
                    category: category,
                    publishedAt: publishedAt,
                    summary: title,
                    imageGradientIndex: articles.count % 5,
                    imageURL: imageURL,
                    articleURL: articleURL
                )
            )
            _ = slug

            if articles.count >= limit { break }
        }

        return articles
    }

    private static func stripTags(_ html: String) -> String {
        html.replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
    }

    private static let knownCategories = [
        "CTM a HCŽ", "Masters", "Mládež", "Turnaje", "Extraliga",
        "1. liga", "2. liga", "Reprezentace", "Liga žen", "Junioři", "Dorost"
    ]

    private static func detectCategory(in text: String) -> String? {
        for cat in knownCategories where text.contains(cat) {
            return cat
        }
        return nil
    }

    private static func detectDate(in text: String, formatter: DateFormatter) -> Date? {
        guard let regex = try? NSRegularExpression(pattern: #"(\d{1,2}\.\s*\d{1,2}\.\s*\d{4})"#),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text)
        else { return nil }
        let raw = String(text[range]).replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        if let d = formatter.date(from: raw) { return d }
        let alt = DateFormatter()
        alt.locale = Locale(identifier: "cs_CZ")
        alt.dateFormat = "d. M. yyyy"
        let cleaned = raw.replacingOccurrences(of: ". 0", with: ". ")
        return alt.date(from: cleaned) ?? alt.date(from: raw)
    }
}
