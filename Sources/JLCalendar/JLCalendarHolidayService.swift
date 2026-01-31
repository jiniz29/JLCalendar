//
//  JLCalendarHolidayService.swift
//  JLCalendar
//
//  Created by jiniz.ll on 1/31/26.
//

import Foundation

enum JLCalendarHolidayService {
    struct PublicHoliday: Decodable {
        let date: String
    }

    private struct CachePayload: Codable {
        let dates: [String]
        let updatedAt: TimeInterval
    }

    enum ServiceError: Error {
        case invalidURL
        case noData
    }

    static func fetchPublicHolidays(
        year: Int,
        countryCode: String,
        locale: Locale,
        completion: @MainActor @escaping (Result<[Date], Error>) -> Void
    ) {
        let cachedDates = loadCachedDates(year: year, countryCode: countryCode)
        if let cachedDates {
            Task { @MainActor in
                completion(.success(cachedDates))
            }
        }

        let urlString = "https://date.nager.at/api/v3/PublicHolidays/\(year)/\(countryCode)"
        guard let url = URL(string: urlString) else {
            Task { @MainActor in
                completion(.failure(ServiceError.invalidURL))
            }
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let error {
                if cachedDates == nil {
                    Task { @MainActor in
                        completion(.failure(error))
                    }
                }
                return
            }
            guard let data else {
                if cachedDates == nil {
                    Task { @MainActor in
                        completion(.failure(ServiceError.noData))
                    }
                }
                return
            }
            do {
                let decoded = try JSONDecoder().decode([PublicHoliday].self, from: data)
                let formatter = makeISODateFormatter()
                let dates = decoded.compactMap { formatter.date(from: $0.date) }
                saveCachedDates(strings: decoded.map { $0.date }, year: year, countryCode: countryCode)
                Task { @MainActor in
                    completion(.success(dates))
                }
            } catch {
                if cachedDates == nil {
                    Task { @MainActor in
                        completion(.failure(error))
                    }
                }
            }
        }
        task.resume()
    }

    private static func cacheKey(year: Int, countryCode: String) -> String {
        return "JLCalendar.PublicHolidays.\(countryCode.uppercased()).\(year)"
    }

    private static func makeISODateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    private static func loadCachedDates(year: Int, countryCode: String) -> [Date]? {
        let key = cacheKey(year: year, countryCode: countryCode)
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        guard let payload = try? JSONDecoder().decode(CachePayload.self, from: data) else { return nil }
        let formatter = makeISODateFormatter()
        let dates = payload.dates.compactMap { formatter.date(from: $0) }
        return dates.isEmpty ? nil : dates
    }

    private static func saveCachedDates(strings: [String], year: Int, countryCode: String) {
        let payload = CachePayload(dates: strings, updatedAt: Date().timeIntervalSince1970)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        let key = cacheKey(year: year, countryCode: countryCode)
        UserDefaults.standard.set(data, forKey: key)
    }
}
