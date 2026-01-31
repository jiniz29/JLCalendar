//
//  ViewController.swift
//  JLCalendarSampleApp
//
//  Created by jiniz.ll on 10/6/25.
//

import UIKit
import JLCalendar

class ViewController: UIViewController, JLCalendarViewDelegate {
    
    private let calendarView = JLCalendarView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        calendarView.delegate = self
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        // Optional: disable auto behaviors if desired
        // calendarView.autoSelectToday = false
        // calendarView.autoLoadHolidays = false
        //
        // Optional: set a specific date programmatically
        // calendarView.setSelectedDate(Date(timeIntervalSince1970: 0))

        view.addSubview(calendarView)

        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            calendarView.heightAnchor.constraint(equalToConstant: 420)
        ])
    }
    
    func calendarView(_ calendarView: JLCalendarView, didSelect date: Date) {
        print("선택된 날짜:", date)
    }

    func calendarView(_ calendarView: JLCalendarView, didChangeMonth month: Date) {
        // Optional: reload holidays for a specific year
        // calendarView.loadPublicHolidays(year: Calendar.current.component(.year, from: month))
    }
}
