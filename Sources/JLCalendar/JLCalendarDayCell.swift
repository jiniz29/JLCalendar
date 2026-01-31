//
//  JLCalendarDayCell.swift
//  JLCalendar
//
//  Created by jiniz.ll on 10/6/25.
//

import UIKit

final class JLCalendarDayCell: UICollectionViewCell {
    static let identifier = "JLCalendarDayCell"
    
    private let dayLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let selectionView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.masksToBounds = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(selectionView)
        contentView.addSubview(dayLabel)
        let clearView = UIView()
        clearView.backgroundColor = .clear
        selectedBackgroundView = clearView
        backgroundView = clearView
        NSLayoutConstraint.activate([
            selectionView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            selectionView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            selectionView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.72),
            selectionView.heightAnchor.constraint(equalTo: selectionView.widthAnchor),

            dayLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dayLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        contentView.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        selectionView.layer.cornerRadius = selectionView.bounds.width / 2
    }

    func configure(date: Date, currentMonth: Date, appearance: JLCalendarAppearance, isSelected: Bool, isHoliday: Bool) {
        contentView.layoutIfNeeded()
        selectionView.layer.cornerRadius = selectionView.bounds.width / 2
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        dayLabel.text = "\(day)"
        
        let isInMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
        let isToday = calendar.isDateInToday(date)
        if isInMonth {
            if isToday {
                dayLabel.textColor = appearance.todayTextColor
            } else {
                dayLabel.textColor = isHoliday ? appearance.holidayTextColor : appearance.textColor
            }
        } else {
            dayLabel.textColor = appearance.inactiveTextColor
        }
        
        if isSelected {
            selectionView.isHidden = false
            selectionView.backgroundColor = appearance.selectedColor
            dayLabel.textColor = appearance.selectedTextColor
        } else {
            selectionView.isHidden = true
            selectionView.backgroundColor = .clear
        }
    }
}
