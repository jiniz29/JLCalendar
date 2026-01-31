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
    func calendarView(_ calendarView: JLCalendarView, didChangeDisplayMode mode: JLCalendarDisplayMode)
    func calendarView(_ calendarView: JLCalendarView, didChangeHeight height: CGFloat)
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
            updateHeaderText()
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
    public var autoSelectToday: Bool = true
    public var autoLoadHolidays: Bool = true
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
            updateHeaderText()
            updateHeaderSelection()
            reloadData()
            delegate?.calendarView(self, didChangeDisplayMode: displayMode)
        }
    }
    
    // MARK: - Private
    private var days: [Date] = []
    public private(set) var selectedDate: Date?
    private var holidaySet: Set<Date> = []
    private let headerHeight: CGFloat = 32
    private let weekdayLabelHeight: CGFloat = 20
    private let headerBottomSpacing: CGFloat = 4
    private let weekdayBottomSpacing: CGFloat = 4
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

    private let headerView = UIView()
    private let monthLabel = UILabel()
    private let displayModeControl = UISegmentedControl(items: [])
    private let todayButton = UIButton(type: .system)

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
        updateHeightIfNeeded()
        if autoSelectToday {
            setSelectedDate(Date())
        }
        if autoLoadHolidays {
            loadPublicHolidays()
        }
        reloadData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    private func setupLayout() {
        setupHeader()
        addSubview(headerView)
        addSubview(weekdayStack)
        addSubview(collectionView)
        collectionView.addGestureRecognizer(swipeLeft)
        collectionView.addGestureRecognizer(swipeRight)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: headerHeight),

            weekdayStack.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: headerBottomSpacing),
            weekdayStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            weekdayStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            weekdayStack.heightAnchor.constraint(equalToConstant: weekdayLabelHeight),

            collectionView.topAnchor.constraint(equalTo: weekdayStack.bottomAnchor, constant: weekdayBottomSpacing),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        setupWeekdayLabels()
        updateHeaderText()
        updateHeaderSelection()
    }

    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false

        monthLabel.font = .boldSystemFont(ofSize: 20)
        monthLabel.textAlignment = .center
        monthLabel.translatesAutoresizingMaskIntoConstraints = false
        monthLabel.isUserInteractionEnabled = true
        monthLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showDatePicker)))

        displayModeControl.translatesAutoresizingMaskIntoConstraints = false
        displayModeControl.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 12, weight: .medium)], for: .normal)
        displayModeControl.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 12, weight: .semibold)], for: .selected)
        displayModeControl.addTarget(self, action: #selector(displayModeChanged), for: .valueChanged)

        todayButton.translatesAutoresizingMaskIntoConstraints = false
        todayButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        todayButton.addTarget(self, action: #selector(goToToday), for: .touchUpInside)

        headerView.addSubview(displayModeControl)
        headerView.addSubview(monthLabel)
        headerView.addSubview(todayButton)

        NSLayoutConstraint.activate([
            displayModeControl.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            displayModeControl.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            displayModeControl.heightAnchor.constraint(equalToConstant: 28),

            todayButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            todayButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            todayButton.heightAnchor.constraint(equalToConstant: 28),

            monthLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            monthLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
    }

    public override var intrinsicContentSize: CGSize {
        let width = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width
        return CGSize(width: UIView.noIntrinsicMetric, height: preferredHeight(for: width))
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
        invalidateIntrinsicContentSize()
        updateHeightIfNeeded()
    }

    public func setSelectedDate(_ date: Date?) {
        selectedDate = date.map { calendar.startOfDay(for: $0) }
        updateHeaderText()
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
        collectionView.layoutIfNeeded()
        invalidateIntrinsicContentSize()
        updateHeightIfNeeded()
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

    private func updateHeaderText() {
        let formatter = DateFormatter()
        formatter.locale = effectiveLocale
        formatter.calendar = calendar
        formatter.setLocalizedDateFormatFromTemplate("yMMMM")
        let dateForTitle = displayMode == .week ? (selectedDate ?? currentMonth) : currentMonth
        monthLabel.text = formatter.string(from: dateForTitle)

        let titles = localizedHeaderTitles()
        if displayModeControl.numberOfSegments == 0 {
            displayModeControl.insertSegment(withTitle: titles.month, at: 0, animated: false)
            displayModeControl.insertSegment(withTitle: titles.week, at: 1, animated: false)
        } else {
            displayModeControl.setTitle(titles.month, forSegmentAt: 0)
            displayModeControl.setTitle(titles.week, forSegmentAt: 1)
        }
        todayButton.setTitle(titles.today, for: .normal)
    }

    private func updateHeaderSelection() {
        displayModeControl.selectedSegmentIndex = displayMode == .week ? 1 : 0
    }

    @objc private func displayModeChanged() {
        displayMode = displayModeControl.selectedSegmentIndex == 1 ? .week : .month
    }

    @objc private func goToToday() {
        let today = Date()
        setCurrentMonth(today)
        setSelectedDate(today)
    }

    @objc private func showDatePicker() {
        guard let viewController = findViewController() else { return }
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.locale = effectiveLocale
        picker.calendar = calendar
        picker.date = selectedDate ?? currentMonth

        let title = localizedHeaderTitles().pickerTitle
        let alert = UIAlertController(title: title, message: "\n\n\n\n\n\n\n\n", preferredStyle: .actionSheet)
        alert.view.addSubview(picker)
        picker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            picker.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
            picker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 16)
        ])

        alert.addAction(UIAlertAction(title: localizedHeaderTitles().cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: localizedHeaderTitles().confirm, style: .default, handler: { [weak self] _ in
            guard let self else { return }
            setCurrentMonth(picker.date)
            setSelectedDate(picker.date)
        }))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = self
            popover.sourceRect = CGRect(x: bounds.midX, y: headerHeight, width: 1, height: 1)
        }
        viewController.present(alert, animated: true)
    }

    private func localizedHeaderTitles() -> (month: String, week: String, today: String, pickerTitle: String, confirm: String, cancel: String) {
        let language = effectiveLocale.languageCode ?? "en"
        if language == "ko" {
            return ("월간", "주간", "오늘", "날짜 선택", "선택", "취소")
        }
        return ("Month", "Week", "Today", "Select Date", "Select", "Cancel")
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
        updateHeaderText()
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
        updateHeaderText()
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

    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let vc = current as? UIViewController { return vc }
            responder = current.next
        }
        return nil
    }

    public func preferredHeight(for width: CGFloat) -> CGFloat {
        let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        let totalSpacing = (layout?.minimumInteritemSpacing ?? 0) * 6
        let itemWidth = (width - totalSpacing) / 7
        let rows = displayMode == .week ? 1 : max(1, Int(ceil(Double(days.count) / 7.0)))
        let rowSpacing = layout?.minimumLineSpacing ?? 0
        let gridHeight = (CGFloat(rows) * itemWidth) + (CGFloat(max(0, rows - 1)) * rowSpacing)
        return headerHeight + headerBottomSpacing + weekdayLabelHeight + weekdayBottomSpacing + gridHeight
    }

    private func updateHeightIfNeeded() {
        let width = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width
        let newHeight = preferredHeight(for: width)
        delegate?.calendarView(self, didChangeHeight: newHeight)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()
        updateHeightIfNeeded()
    }
}

public extension JLCalendarViewDelegate {
    func calendarView(_ calendarView: JLCalendarView, didChangeMonth month: Date) {}
    func calendarView(_ calendarView: JLCalendarView, didChangeDisplayMode mode: JLCalendarDisplayMode) {}
    func calendarView(_ calendarView: JLCalendarView, didChangeHeight height: CGFloat) {}
}
