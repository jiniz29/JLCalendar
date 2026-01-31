//
//  JLCalendarView.swift
//  JLCalendar
//
//  Created by jiniz.ll on 10/6/25.
//

import UIKit

public protocol JLCalendarViewDelegate: AnyObject {
    func calendarView(_ calendarView: JLCalendarView, didSelect date: Date)
    func calendarView(_ calendarView: JLCalendarView, didChangeMonth month: Date)
}

public enum JLCalendarWeekStart {
    case system
    case sunday
    case monday
    
    fileprivate var firstWeekday: Int? {
        switch self {
        case .system: return nil
        case .sunday: return 1
        case .monday: return 2
        }
    }
}

public enum JLCalendarDisplayMode {
    case month
    case week
}

public final class JLCalendarView: UIView {

    // MARK: - Public Properties
    public weak var delegate: JLCalendarViewDelegate?
    public var currentMonth: Date = Date() {
        didSet {
            reloadData()
            delegate?.calendarView(self, didChangeMonth: currentMonth)
        }
    }
    public var appearance: JLCalendarAppearance = .default {
        didSet {
            setupWeekdayLabels()
            reloadData()
        }
    }
    public var allowsSelection: Bool = true {
        didSet { collectionView.allowsSelection = allowsSelection }
    }
    public var holidayDates: Set<Date> = [] {
        didSet {
            holidaySet = Set(holidayDates.map { calendar.startOfDay(for: $0) })
            reloadData()
        }
    }
    public var holidayProvider: ((Date, Calendar, Locale) -> Bool)?
    public var locale: Locale = .autoupdatingCurrent {
        didSet {
            updateCalendar()
            setupWeekdayLabels()
            reloadData()
        }
    }
    public var weekStart: JLCalendarWeekStart = .system {
        didSet {
            updateCalendar()
            setupWeekdayLabels()
            reloadData()
        }
    }
    public var displayMode: JLCalendarDisplayMode = .month {
        didSet {
            if displayMode == .week, selectedDate == nil {
                selectedDate = calendar.startOfDay(for: Date())
            }
            if displayMode == .week, let selectedDate {
                currentMonth = normalizedMonth(selectedDate)
            }
            reloadData()
        }
    }
    
    // MARK: - Private
    private var days: [Date] = []
    public private(set) var selectedDate: Date?
    private var holidaySet: Set<Date> = []
    private let weekdayLabelHeight: CGFloat = 20
    private var calendar: Calendar = .autoupdatingCurrent
    private var effectiveLocale: Locale {
        if locale.identifier == Locale.autoupdatingCurrent.identifier,
           let preferred = Locale.preferredLanguages.first {
            return Locale(identifier: preferred)
        }
        return locale
    }
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 4
        layout.minimumInteritemSpacing = 4
        let width = UIScreen.main.bounds.width / 7 - 8
        layout.itemSize = CGSize(width: width, height: width)
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.dataSource = self
        view.delegate = self
        view.allowsSelection = true
        view.register(JLCalendarDayCell.self, forCellWithReuseIdentifier: JLCalendarDayCell.identifier)
        return view
    }()

    private lazy var weekdayStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var swipeLeft: UISwipeGestureRecognizer = {
        let gesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        gesture.direction = .left
        return gesture
    }()

    private lazy var swipeRight: UISwipeGestureRecognizer = {
        let gesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        gesture.direction = .right
        return gesture
    }()
    
    // MARK: - Init
    public override init(frame: CGRect) {
        super.init(frame: frame)
        updateCalendar()
        setupLayout()
        reloadData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    private func setupLayout() {
        addSubview(weekdayStack)
        addSubview(collectionView)
        collectionView.addGestureRecognizer(swipeLeft)
        collectionView.addGestureRecognizer(swipeRight)
        NSLayoutConstraint.activate([
            weekdayStack.topAnchor.constraint(equalTo: topAnchor),
            weekdayStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            weekdayStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            weekdayStack.heightAnchor.constraint(equalToConstant: weekdayLabelHeight),

            collectionView.topAnchor.constraint(equalTo: weekdayStack.bottomAnchor, constant: 4),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        setupWeekdayLabels()
    }

    private func setupWeekdayLabels() {
        weekdayStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let symbols = localizedWeekdaySymbols()
        let formatter = DateFormatter()
        for symbol in symbols {
            let label = UILabel()
            label.font = .systemFont(ofSize: 11, weight: .medium)
            label.textAlignment = .center
            label.textColor = appearance.weekdayTextColor
            label.text = symbol
            weekdayStack.addArrangedSubview(label)
        }
    }
    
    public func reloadData() {
        if displayMode == .month {
            days = JLCalendarManager.generateDays(for: currentMonth, calendar: calendar)
        } else {
            let baseDate = selectedDate ?? currentMonth
            days = JLCalendarManager.generateWeekDays(for: baseDate, calendar: calendar)
        }
        collectionView.reloadData()
    }

    public func setSelectedDate(_ date: Date?) {
        selectedDate = date.map { calendar.startOfDay(for: $0) }
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
    }

    public func setCurrentMonth(_ date: Date) {
        currentMonth = normalizedMonth(date)
    }

    public func loadPublicHolidays(year: Int? = nil, countryCode: String? = nil) {
        let targetYear = year ?? calendar.component(.year, from: Date())
        let regionCode = (countryCode
            ?? locale.regionCode
            ?? Locale.autoupdatingCurrent.regionCode
            ?? "KR").uppercased()
        JLCalendarHolidayService.fetchPublicHolidays(
            year: targetYear,
            countryCode: regionCode,
            locale: effectiveLocale
        ) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let dates):
                self.holidayDates = Set(dates)
            case .failure:
                break
            }
        }
    }
}

// MARK: - UICollectionViewDataSource
extension JLCalendarView: UICollectionViewDataSource, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return days.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: JLCalendarDayCell.identifier, for: indexPath) as? JLCalendarDayCell else {
            return UICollectionViewCell()
        }
        let date = days[indexPath.item]
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let isHoliday = holidayProvider?(date, calendar, locale) ?? holidaySet.contains(calendar.startOfDay(for: date))
        cell.configure(
            date: date,
            currentMonth: currentMonth,
            appearance: appearance,
            isSelected: isSelected,
            isHoliday: isHoliday
        )
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard allowsSelection else { return }
        selectedDate = calendar.startOfDay(for: days[indexPath.item])
        collectionView.reloadData()
        delegate?.calendarView(self, didSelect: days[indexPath.item])
    }

    private func updateCalendar() {
        var updated = Calendar.autoupdatingCurrent
        updated.locale = effectiveLocale
        if let firstWeekday = weekStart.firstWeekday {
            updated.firstWeekday = firstWeekday
        }
        calendar = updated
        holidaySet = Set(holidayDates.map { calendar.startOfDay(for: $0) })
        selectedDate = selectedDate.map { calendar.startOfDay(for: $0) }
    }

    private func localizedWeekdaySymbols() -> [String] {
        let formatter = DateFormatter()
        formatter.locale = effectiveLocale
        formatter.calendar = calendar
        let rawSymbols = formatter.shortStandaloneWeekdaySymbols ?? formatter.shortWeekdaySymbols ?? []
        guard rawSymbols.count == 7 else { return rawSymbols }
        let startIndex = max(0, min(rawSymbols.count - 1, calendar.firstWeekday - 1))
        return Array(rawSymbols[startIndex...] + rawSymbols[..<startIndex])
    }

    private func normalizedMonth(_ date: Date) -> Date {
        return calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        let offset = gesture.direction == .left ? 1 : -1
        if displayMode == .month {
            guard let newDate = calendar.date(byAdding: .month, value: offset, to: currentMonth) else { return }
            selectedDate = nil
            currentMonth = normalizedMonth(newDate)
        } else {
            let base = selectedDate ?? currentMonth
            guard let newDate = calendar.date(byAdding: .weekOfYear, value: offset, to: base) else { return }
            selectedDate = calendar.startOfDay(for: newDate)
            currentMonth = normalizedMonth(newDate)
        }
    }
}

public extension JLCalendarViewDelegate {
    func calendarView(_ calendarView: JLCalendarView, didChangeMonth month: Date) {}
}
