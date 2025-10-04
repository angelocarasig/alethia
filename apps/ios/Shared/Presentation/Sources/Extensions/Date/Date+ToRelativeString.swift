//
//  Date+ToRelativeString.swift
//  Presentation
//
//  Created by Angelo Carasig on 21/6/2025.
//

import Foundation

extension Date {
    func toRelativeString() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self, to: now)
        
        if let year = components.year, year > 0 {
            return year == 1 ? "1 year ago" : "\(year) years ago"
        } else if let month = components.month, month > 0 {
            return month == 1 ? "1 month ago" : "\(month) months ago"
        } else if let day = components.day, day > 0 {
            if day == 1 { return "Yesterday" }
            if day < 7 { return "\(day) days ago" }
            let weeks = day / 7
            return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
        } else if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
        } else if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1 minute ago" : "\(minute) minutes ago"
        } else if let second = components.second, second > 0 {
            return second == 1 ? "1 second ago" : "\(second) seconds ago"
        } else {
            return "Just now"
        }
    }
}
