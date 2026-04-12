import Foundation

// MARK: - Google Translate Service
// 使用前：在 Google Cloud Console 启用 Cloud Translation API，并填入下方 apiKey
// 获取地址：https://console.cloud.google.com/apis/library/translate.googleapis.com

enum TranslationService {
    /// 在此填入你的 Google Translate API Key
    static var apiKey: String = ""

    /// 将文本翻译到 App 支持的所有语言，返回 [AppLanguage.rawValue: 翻译结果]
    static func translateToAllLanguages(
        text: String,
        from sourceLang: AppLanguage
    ) async -> [String: String] {
        // 无 key 时仅返回源语言，不报错
        guard !apiKey.isEmpty else { return [sourceLang.rawValue: text] }

        var results: [String: String] = [sourceLang.rawValue: text]
        let targets = AppLanguage.allCases.filter { $0 != sourceLang }

        await withTaskGroup(of: (String, String?).self) { group in
            for target in targets {
                group.addTask {
                    let translated = await translate(
                        text: text,
                        from: googleCode(sourceLang),
                        to: googleCode(target)
                    )
                    return (target.rawValue, translated)
                }
            }
            for await (key, value) in group {
                if let value { results[key] = value }
            }
        }
        return results
    }

    // MARK: - Private

    private static func googleCode(_ lang: AppLanguage) -> String {
        switch lang {
        case .simplifiedChinese:  return "zh-CN"
        case .traditionalChinese: return "zh-TW"
        case .english:            return "en"
        case .japanese:           return "ja"
        case .korean:             return "ko"
        }
    }

    private static func translate(text: String, from source: String, to target: String) async -> String? {
        guard let url = URL(string: "https://translation.googleapis.com/language/translate/v2?key=\(apiKey)") else {
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "q": text, "source": source, "target": target, "format": "text"
        ])
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json        = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataObj     = json["data"]         as? [String: Any],
              let list        = dataObj["translations"] as? [[String: Any]],
              let translated  = list.first?["translatedText"] as? String
        else { return nil }
        return translated
    }
}
