//
//  JLCalendarAppearance.swift
//  JLCalendar
//
//  Created by jiniz.ll on 10/6/25.
//

import UIKit

public struct JLCalendarAppearance : Sendable {
    public var todayColor: UIColor
    public var textColor: UIColor
    public var inactiveTextColor: UIColor
    public var weekdayTextColor: UIColor
    public var inactiveWeekdayTextColor: UIColor
    public var holidayTextColor: UIColor
    public var selectedColor: UIColor
    public var selectedTextColor: UIColor
    public var todayTextColor: UIColor
    
    public static let `default` = JLCalendarAppearance(
        todayColor: .systemBlue,
        textColor: .label,
        inactiveTextColor: .systemGray3,
        weekdayTextColor: .secondaryLabel,
        inactiveWeekdayTextColor: .systemGray4,
        holidayTextColor: .systemRed,
        selectedColor: .systemBlue,
        selectedTextColor: .white,
        todayTextColor: .systemBlue
    )
}
