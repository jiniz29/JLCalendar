//
//  ViewController.swift
//  JLCalendarSampleApp
//
//  Created by jiniz.ll on 10/6/25.
//

import UIKit
import JLCalendar

class ViewController: UIViewController, JLCalendarViewDelegate, UITableViewDataSource {
    
    private let calendarView = JLCalendarView()
    private let tableView = UITableView()
    private let rows = (1...20).map { "Row \($0)" }
    
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

        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor.systemGray6

        view.addSubview(calendarView)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: calendarView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func calendarView(_ calendarView: JLCalendarView, didSelect date: Date) {
        print("선택된 날짜:", date)
    }

    func calendarView(_ calendarView: JLCalendarView, didChangeMonth month: Date) {
        // Optional: reload holidays for a specific year
        // calendarView.loadPublicHolidays(year: Calendar.current.component(.year, from: month))
    }

    func calendarView(_ calendarView: JLCalendarView, didChangeDisplayMode mode: JLCalendarDisplayMode) {
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }

    func calendarView(_ calendarView: JLCalendarView, didChangeHeight height: CGFloat) {
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ??
        UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.textLabel?.text = rows[indexPath.row]
        return cell
    }
}
