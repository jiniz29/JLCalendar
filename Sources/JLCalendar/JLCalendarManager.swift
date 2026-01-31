//
//  JLCalendarManager.swift
//  JLCalendar
//
//  Created by jiniz.ll on 10/6/25.
//

import Foundation

enum JLCalendarManager {
    static func generateDays(for month: Date, calendar: Calendar) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let lastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end.addingTimeInterval(-1))
        else { return [] }

        var days: [Date] = []
        var date = firstWeek.start
        while date < lastWeek.end {
            days.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        return days
    }

    static func generateWeekDays(for date: Date, calendar: Calendar) -> [Date] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }
        var days: [Date] = []
        var cursor = weekInterval.start
        while cursor < weekInterval.end {
            days.append(cursor)
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor)!
        }
        return days
    }
}
