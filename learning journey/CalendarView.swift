//
//  CalendarView.swift
//  learning journey
//
//  Created by aljawharah alowayridhi on 30/04/1447 AH.
//
import SwiftUI

struct CalendarView: View {
    // نفس التخزين المستخدم في ActivityView
    @AppStorage("progress.map") private var progressRaw: String = "{}"
    
    // ألوان مطابقة لتصميمك
    private let orange    = Color(hex: 0xB85E2E)
    private let orangeDim = Color(hex: 0x6F3A1D)
    private let blueDim   = Color(hex: 0x244652)
    private let cardStroke = Color.white.opacity(0.1)
    
    // قراءة التقدم (بدون setter)
    private var progress: [String: DayStatus] {
        (try? JSONDecoder().decode([String: DayStatus].self, from: Data(progressRaw.utf8))) ?? [:]
    }
    
    // نبني قائمة الشهور: من أول شهر فيه بيانات إلى الشهر الحالي (أحدث أولاً)
    private var months: [Date] {
        let allDates = progress.keys.compactMap { $0.asDate() }
        let earliest = allDates.min() ?? Date()
        let start = earliest.firstDayOfMonth()
        let end = Date().firstDayOfMonth()
        var cursor = end
        var arr: [Date] = []
        while cursor >= start {
            arr.append(cursor)
            cursor = Calendar.current.date(byAdding: .month, value: -1, to: cursor)!
        }
        if arr.isEmpty { arr = [Date().firstDayOfMonth()] } // على الأقل شهر واحد
        return arr
    }
    
    var body: some View {
        ZStack { Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    ForEach(months, id: \.self) { month in
                        monthSection(for: month)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("All activities")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Month section
    private func monthSection(for month: Date) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(month.monthYearString())
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))
                .padding(.leading, 4)
            
            // عناوين أيام الأسبوع
            HStack {
                ForEach(0..<7, id: \.self) { i in
                    Text(Calendar.current.shortWeekdaySymbols[i].uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.55))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // شبكة الأيام بمحاذاة بداية الشهر
            let grid = monthGrid(month: month)
            VStack(spacing: 10) {
                ForEach(0..<grid.rows, id: \.self) { r in
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { c in
                            let index = r * 7 + c
                            let date = (index < grid.cells.count) ? grid.cells[index] : nil
                            dayCell(date)
                                .frame(maxWidth: .infinity, minHeight: 34)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            
            Divider().overlay(cardStroke)
        }
    }
    
    // MARK: - Day cell (تلوين فقط حسب الحالة)
    @ViewBuilder
    private func dayCell(_ date: Date?) -> some View {
        if let d = date {
            let key = d.key()
            let status = progress[key] ?? .none
            let isToday = Calendar.current.isDateInToday(d)
            // ألوان التعبئة
            let fill: Color? = isToday ? orange
                        : (status == .learned ? orangeDim : (status == .frozen ? blueDim : nil))
            
            ZStack {
                if let f = fill {
                    Circle().fill(f).frame(width: 34, height: 34)
                }
                Text("\(Calendar.current.component(.day, from: d))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(height: 38)
        } else {
            // خانة فارغة قبل بداية الشهر
            Color.clear.frame(height: 38)
        }
    }
    
    // MARK: - Build month grid
    private func monthGrid(month: Date) -> (cells: [Date?], rows: Int) {
        let cal = Calendar.current
        let start = month.firstDayOfMonth()
        let range = cal.range(of: .day, in: .month, for: start)!
        let firstWeekday = cal.component(.weekday, from: start) // 1..7 (Sun..Sat)
        let leading = (firstWeekday - cal.firstWeekday + 7) % 7
        
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for day in range {
            if let d = cal.date(byAdding: .day, value: day - 1, to: start) {
                cells.append(d)
            }
        }
        // اكتمال الصف الأخير إلى مضاعفات 7
        while cells.count % 7 != 0 { cells.append(nil) }
        let rows = cells.count / 7
        return (cells, rows)
    }
}

// MARK: - Helpers (نفس المستخدمة عندك)
private extension Date {
    func firstDayOfMonth() -> Date {
        let comps = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: comps)!.stripTime()
    }
    func stripTime() -> Date { Calendar.current.startOfDay(for: self) }
    func monthYearString() -> String {
        let f = DateFormatter(); f.dateFormat = "LLLL yyyy"; return f.string(from: self)
    }
    func key() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = .init(identifier: "en_US_POSIX")
        return f.string(from: self)
    }
}
private extension String {
    func asDate() -> Date? {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = .init(identifier: "en_US_POSIX")
        return f.date(from: self)
    }
}
private extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self = Color(.sRGB,
                     red: Double((hex >> 16) & 0xff) / 255,
                     green: Double((hex >> 08) & 0xff) / 255,
                     blue: Double((hex >> 00) & 0xff) / 255,
                     opacity: alpha)
    }
}
