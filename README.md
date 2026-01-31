# JLCalendar

Lightweight calendar view for iOS with month/week modes, holiday highlighting, and localized header UI.

## Installation (Swift Package Manager)

Add the repository in Xcode: **File > Add Packages...**

## Usage

```swift
import JLCalendar

final class ViewController: UIViewController, JLCalendarViewDelegate {
    private let calendarView = JLCalendarView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        calendarView.delegate = self
        calendarView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(calendarView)
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            calendarView.heightAnchor.constraint(equalToConstant: 420)
        ])
    }

    func calendarView(_ calendarView: JLCalendarView, didSelect date: Date) {
        print("Selected date:", date)
    }
}
```

## Default Behaviors

The calendar automatically:
- selects today
- loads public holidays (by device region, fallback to KR)

You can disable these defaults:

```swift
calendarView.autoSelectToday = false
calendarView.autoLoadHolidays = false
```

## Customization

```swift
calendarView.displayMode = .week // .month / .week
calendarView.weekStart = .monday // .system / .sunday / .monday
calendarView.locale = .autoupdatingCurrent

// set a specific date programmatically
calendarView.setSelectedDate(Date())

// reload holidays for a specific year
calendarView.loadPublicHolidays(year: 2026)
```

## Notes

- Header UI (month title, month/week toggle, today button) is built into `JLCalendarView`.
- Swiping left/right changes month in month mode and week in week mode.
