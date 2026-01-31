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
    private let monthLabel = UILabel()
    private let displayModeControl = UISegmentedControl(items: ["월간", "주간"])
    private var calendarHeightConstraint: NSLayoutConstraint?
    private let todayButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        monthLabel.font = .boldSystemFont(ofSize: 20)
        monthLabel.textAlignment = .center
        monthLabel.text = formattedDate(calendarView.currentMonth)
        monthLabel.translatesAutoresizingMaskIntoConstraints = false
        monthLabel.isUserInteractionEnabled = true
        monthLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showDatePicker)))

        displayModeControl.selectedSegmentIndex = 0
        displayModeControl.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 12, weight: .medium)], for: .normal)
        displayModeControl.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 12, weight: .semibold)], for: .selected)
        displayModeControl.addTarget(self, action: #selector(displayModeChanged), for: .valueChanged)
        displayModeControl.translatesAutoresizingMaskIntoConstraints = false

        todayButton.setTitle("오늘", for: .normal)
        todayButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        todayButton.addTarget(self, action: #selector(goToToday), for: .touchUpInside)
        todayButton.translatesAutoresizingMaskIntoConstraints = false

        calendarView.delegate = self
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarView.loadPublicHolidays()
        let today = Date()
        calendarView.setSelectedDate(today)
        
        view.addSubview(monthLabel)
        view.addSubview(displayModeControl)
        view.addSubview(todayButton)
        view.addSubview(calendarView)
        
        calendarHeightConstraint = calendarView.heightAnchor.constraint(equalToConstant: 380)
        calendarHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            monthLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            monthLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            displayModeControl.centerYAnchor.constraint(equalTo: monthLabel.centerYAnchor),
            displayModeControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            displayModeControl.heightAnchor.constraint(equalToConstant: 28),
            todayButton.centerYAnchor.constraint(equalTo: monthLabel.centerYAnchor),
            todayButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            todayButton.heightAnchor.constraint(equalToConstant: 28),
            
            calendarView.topAnchor.constraint(equalTo: monthLabel.bottomAnchor, constant: 16),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }
    
    func calendarView(_ calendarView: JLCalendarView, didSelect date: Date) {
        print("선택된 날짜:", date)
        monthLabel.text = formattedDate(date)
    }

    func calendarView(_ calendarView: JLCalendarView, didChangeMonth month: Date) {
        monthLabel.text = formattedDate(month)
        calendarView.loadPublicHolidays(year: Calendar.current.component(.year, from: month))
    }
    
    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = preferredLocale()
        f.calendar = Calendar.autoupdatingCurrent
        f.setLocalizedDateFormatFromTemplate("yMMMM")
        return f.string(from: date)
    }

    @objc private func showDatePicker() {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.locale = preferredLocale()
        picker.calendar = Calendar.autoupdatingCurrent
        picker.date = calendarView.selectedDate ?? calendarView.currentMonth

        let alert = UIAlertController(title: "날짜 선택", message: "\n\n\n\n\n\n\n\n", preferredStyle: .actionSheet)
        alert.view.addSubview(picker)
        picker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            picker.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            picker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 16)
        ])

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "선택", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            self.calendarView.setCurrentMonth(picker.date)
            self.calendarView.setSelectedDate(picker.date)
        }))

        present(alert, animated: true)
    }

    @objc private func displayModeChanged() {
        let isWeek = displayModeControl.selectedSegmentIndex == 1
        calendarView.displayMode = isWeek ? .week : .month
        calendarHeightConstraint?.constant = isWeek ? 120 : 380
    }

    @objc private func goToToday() {
        let today = Date()
        calendarView.setCurrentMonth(today)
        calendarView.setSelectedDate(today)
        monthLabel.text = formattedDate(today)
    }

    private func preferredLocale() -> Locale {
        if let preferred = Locale.preferredLanguages.first {
            return Locale(identifier: preferred)
        }
        return Locale.autoupdatingCurrent
    }

}
