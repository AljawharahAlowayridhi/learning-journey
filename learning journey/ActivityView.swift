// (3) ActivityView.swift
import SwiftUI

// MARK: - Status
enum DayStatus: String, Codable { case none, learned, frozen }

// MARK: - ActivityView
struct ActivityView: View {
    // 👇 نقطة ارتكاز لفتح الشاشة على يوم معيّن (اختياري)
    let initialDate: Date? = nil

    // حفظ تقدم الأيام (String JSON)
    @AppStorage("progress.map") private var progressRaw: String = "{}"

    // إعدادات الهدف المختار
    @AppStorage("learning.topic") private var storedTopic: String = "Swift"
    @AppStorage("learning.timeframe") private var storedTimeframeRaw: String = "Week"

    // بداية الفترة الحالية (يُحدّث عند Update أو "Set same goal" أو من Onboarding)
    @AppStorage("goal.periodStart") private var periodStartRaw: String = ""
    // إشارة تحديث الهدف (من EditGoalView أو OnboardingView)
    @AppStorage("goal.revision") private var goalRevision: Int = 0

    // حالة العرض
    @State private var weekStart: Date = Date().startOfWeek()
    @State private var selectedDate: Date = Date().stripTime()
    @State private var monthPickerShown = false
    @State private var pickedMonth = Calendar.current.component(.month, from: Date())
    @State private var pickedYear  = Calendar.current.component(.year,  from: Date())

    // إخفاء Well done مؤقتًا بعد Update حتى أول Log
    @State private var awaitingFirstLog: Bool = false

    // ألوان التصميم
    private let orange       = Color(hex: 0xB85E2E)
    private let orangeStroke = Color(hex: 0xD48241)
    private let orangeDim    = Color(hex: 0x6F3A1D)
    private let blueSolid    = Color(hex: 0x2F6F7A)
    private let blueDim      = Color(hex: 0x244652)
    private let chipBrown    = Color(hex: 0x4A3625)
    private let chipBlue     = Color(hex: 0x244652)
    private let cardBG       = Color(hex: 0x141414)
    private let cardStroke   = Color.white.opacity(0.12)

    // قاموس الحالات المخزّن (قراءة فقط)
    private var progress: [String: DayStatus] {
        (try? JSONDecoder().decode([String: DayStatus].self, from: Data(progressRaw.utf8))) ?? [:]
    }

    // كتابة الحفظ
    private func writeProgress(_ map: [String: DayStatus]) {
        if let data = try? JSONEncoder().encode(map),
           let s = String(data: data, encoding: .utf8) {
            progressRaw = s
        }
    }

    // parsing periodStartRaw
    private var periodStart: Date {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = .init(identifier: "en_US_POSIX")
        if let d = f.date(from: periodStartRaw),
           d <= Date().stripTime().addingTimeInterval(60*60*24*4000) {
            return d.stripTime()
        }
        // أول تشغيل: عيّن الفترة من اليوم
        let today = Date().stripTime()
        periodStartRaw = today.key()
        return today
    }

    // ====== حساب نهاية الفترة الحالية حسب المدة ======
    private var periodEndExclusive: Date {
        let cal = Calendar.current
        switch storedTimeframeRaw {
        case "Month": return cal.date(byAdding: .month, value: 1, to: periodStart)!.stripTime()
        case "Year":  return cal.date(byAdding: .year,  value: 1, to: periodStart)!.stripTime()
        default:      return cal.date(byAdding: .day,   value: 7, to: periodStart)!.stripTime()
        }
    }

    // أيام الأسبوع الظاهرة
    private var weekDays: [Date] {
        (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: weekStart) }
    }

    // حدّ التجميد أسبوعياً = 2
    private var freezesUsedThisWeek: Int {
        weekDays.filter { (progress[$0.key()] ?? .none) == .frozen }.count
    }
    private let maxFreezesPerWeek = 2
    private var freezeDisabled: Bool { freezesUsedThisWeek >= maxFreezesPerWeek }

    // عدادات الأسبوع المعروض
    private var countsThisWeek: (learned: Int, frozen: Int) {
        var l = 0, f = 0
        for d in weekDays {
            switch progress[d.key()] ?? .none {
            case .learned: l += 1
            case .frozen:  f += 1
            default: break
            }
        }
        return (l,f)
    }

    // حالة زر الدائرة الكبير
    private var statusForBigButton: DayStatus {
        let s = progress[selectedDate.key()] ?? .none
        if freezeDisabled && s != .learned { return .none }
        return s
    }

    // ====== منطق انتهاء "الفترة المعروضة" لأجل الاختبار السابق ======
    private var displayedPeriodStart: Date {
        let cal = Calendar.current
        switch storedTimeframeRaw {
        case "Month":
            return cal.date(from: DateComponents(year: pickedYear, month: pickedMonth, day: 1))!.stripTime()
        case "Year":
            return cal.date(from: DateComponents(year: pickedYear, month: 1, day: 1))!.stripTime()
        default:
            return weekStart.stripTime()
        }
    }
    private var displayedPeriodEndExclusive: Date {
        let cal = Calendar.current
        switch storedTimeframeRaw {
        case "Month": return cal.date(byAdding: .month, value: 1, to: displayedPeriodStart)!.stripTime()
        case "Year":  return cal.date(byAdding: .year,  value: 1, to: displayedPeriodStart)!.stripTime()
        default:      return cal.date(byAdding: .day,   value: 7, to: displayedPeriodStart)!.stripTime()
        }
    }
    private var isDisplayedPeriodCompleted: Bool {
        Date().stripTime() >= displayedPeriodEndExclusive
    }
    private var isShowingCurrentPeriod: Bool {
        Calendar.current.isDate(displayedPeriodStart, inSameDayAs: periodStart)
    }

    // ✅ أقرب يوم غير مسجّل داخل «الفترة الحالية» (Week/Month/Year)
    private func nearestUnloggedInCurrentPeriod() -> Date {
        let cal = Calendar.current
        var d = periodStart
        while d < periodEndExclusive {
            if (progress[d.key()] ?? .none) == .none { return d }
            d = cal.date(byAdding: .day, value: 1, to: d)!.stripTime()
        }
        return periodStart
    }

    var body: some View {
        ZStack { Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        card
                        if isDisplayedPeriodCompleted && !(awaitingFirstLog && isShowingCurrentPeriod) {
                            wellDoneView
                        } else {
                            bigButton
                            freezeButton
                            usageText
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            }
        }
        .sheet(isPresented: $monthPickerShown) { monthYearPicker }
        .preferredColorScheme(.dark)

        // 👇 تثبيت المؤشر عند الفتح
        .onAppear {
            let anchor = initialDate ?? Date().stripTime()
            selectedDate = anchor
            weekStart    = anchor.startOfWeek()
            pickedMonth  = Calendar.current.component(.month, from: anchor)
            pickedYear   = Calendar.current.component(.year,  from: anchor)
        }

        // تزامن Wheel مع تغيّر الأسبوع
        .onChange(of: weekStart) { newStart in
            pickedMonth = Calendar.current.component(.month, from: newStart)
            pickedYear  = Calendar.current.component(.year,  from: newStart)
        }

        // استقبال تحديث الهدف من Edit/Onboarding
        .onChange(of: goalRevision) { _ in
            awaitingFirstLog = true
            let target = nearestUnloggedInCurrentPeriod()
            selectedDate = target
            weekStart    = target.startOfWeek()
            pickedMonth  = Calendar.current.component(.month, from: target)
            pickedYear   = Calendar.current.component(.year,  from: target)
        }
    }
}

// MARK: - Header
extension ActivityView {
    private var header: some View {
        HStack {
            Text("Activity")
                .font(.system(size: 32, weight: .heavy))
                .foregroundColor(.white)
            Spacer()
            HStack(spacing: 12) {
                NavigationLink(destination: CalendarView()) {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 36, height: 36)
                        .overlay(Image(systemName: "calendar").foregroundColor(.white))
                }
                NavigationLink(destination: EditGoalView()) {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 36, height: 36)
                        .overlay(Image(systemName: "pencil.and.outline").foregroundColor(.white))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

// MARK: - Card (Month + Week + Chips)
extension ActivityView {
    private var card: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Month header + arrows
            HStack(spacing: 8) {
                Button {
                    pickedMonth = Calendar.current.component(.month, from: weekStart)
                    pickedYear  = Calendar.current.component(.year,  from: weekStart)
                    monthPickerShown = true
                } label: {
                    HStack(spacing: 6) {
                        Text(headerMonthYearString)
                            .foregroundColor(.white.opacity(0.95))
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(orange)
                    }
                }

                Spacer()

                HStack(spacing: 14) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            weekStart = Calendar.current.date(byAdding: .day, value: -7, to: weekStart)!
                            selectedDate = weekStart
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(orange)
                            .font(.system(size: 15, weight: .bold))
                    }
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            weekStart = Calendar.current.date(byAdding: .day, value: 7, to: weekStart)!
                            selectedDate = weekStart
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .foregroundColor(orange)
                            .font(.system(size: 15, weight: .bold))
                    }
                }
            }

            // Weekday labels
            HStack {
                ForEach(weekDays, id: \.self) { d in
                    Text(d.weekdayShort())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.55))
                        .frame(maxWidth: .infinity)
                }
            }

            // Days row
            HStack {
                ForEach(weekDays, id: \.self) { d in
                    dayCell(for: d)
                        .frame(maxWidth: .infinity)
                }
            }

            Divider().overlay(Color.white.opacity(0.08))

            Text("Learning \(storedTopic)")
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))

            HStack(spacing: 12) {
                chip(bg: chipBrown, icon: "flame.fill",
                     value: countsThisWeek.learned, title: "Days Learned")
                chip(bg: chipBlue, icon: "cube.fill",
                     value: countsThisWeek.frozen, title: "Day Freezed")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBG)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(cardStroke, lineWidth: 1)
                )
        )
    }

    // عنوان الشهر/السنة من weekStart (حتى يتغيّر مع الأسهم)
    private var headerMonthYearString: String { weekStart.monthYearString() }

    private func chip(bg: Color, icon: String, value: Int, title: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(Color.black.opacity(0.35))
                Image(systemName: icon).foregroundColor(.white)
            }
            .frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 0) {
                Text("\(value)").foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
                Text(title).foregroundColor(.white)
                    .font(.system(size: 12, weight: .medium))
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous).fill(bg)
        )
    }

    private func dayCell(for date: Date) -> some View {
        let key = date.key()
        let status = progress[key] ?? .none

        let today   = Date().stripTime()
        let isToday = Calendar.current.isDate(date, inSameDayAs: today)
        let isPast  = date < today
        let isFuture = date > today

        let fill: Color? = {
            switch status {
            case .learned:
                if isToday { return orange }
                if isPast  { return orangeDim }
                if isFuture { return orangeDim }
                return nil
            case .frozen:
                if isToday { return blueSolid }
                if isPast  { return blueDim }
                if isFuture { return blueDim }
                return nil
            case .none:
                return nil
            }
        }()

        return ZStack {
            if let f = fill {
                Circle()
                    .fill(f)
                    .frame(width: 38, height: 38)
                    .overlay(Circle().stroke(Color.black.opacity(0.25), lineWidth: 0.5))
            } else if selectedDate == date {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    .frame(width: 38, height: 38)
            }

            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(height: 40)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedDate = date
            }
        }
    }
}

// MARK: - Big Button + Freeze Button + WellDone
extension ActivityView {
    private var bigButton: some View {
        let uiStatus = statusForBigButton
        return Button {
            setStatus(.learned, for: selectedDate)
        } label: {
            ZStack {
                Circle()
                    .fill(bigFill(for: uiStatus))
                    .frame(width: 300, height: 300)
                    .overlay(Circle().stroke(borderColor(for: uiStatus), lineWidth: 1))
                Text(bigTitle(for: uiStatus))
                    .multilineTextAlignment(.center)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(textColor(for: uiStatus))
            }
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
    }

    private func bigFill(for status: DayStatus) -> Color {
        switch status {
        case .none:    return orange
        case .learned: return orangeDim
        case .frozen:  return blueDim
        }
    }
    private func textColor(for status: DayStatus) -> Color {
        switch status {
        case .none:    return .white
        case .learned: return orange
        case .frozen:  return blueSolid
        }
    }
    private func borderColor(for status: DayStatus) -> Color {
        switch status {
        case .none:    return orangeStroke.opacity(0.7)
        case .learned: return Color.white.opacity(0.12)
        case .frozen:  return blueSolid.opacity(0.7)
        }
    }
    private func bigTitle(for status: DayStatus) -> String {
        switch status {
        case .none:    return "Log as\nLearned"
        case .learned: return "Learned\nToday"
        case .frozen:  return "Day\nFreezed"
        }
    }

    private var freezeButton: some View {
        Button {
            if !freezeDisabled { setStatus(.frozen, for: selectedDate) }
        } label: {
            Text("Log as Freezed")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(freezeDisabled ? 0.45 : 1))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(freezeDisabled ? Color.black.opacity(0.35) : blueSolid)
                        .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
                )
        }
        .disabled(freezeDisabled)
        .padding(.horizontal, 36)
        .padding(.top, 6)
    }

    private var usageText: some View {
        Text("\(min(freezesUsedThisWeek, maxFreezesPerWeek)) out of \(maxFreezesPerWeek) Freezes used")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white.opacity(0.5))
            .frame(maxWidth: .infinity)
    }

    private var wellDoneView: some View {
        VStack(spacing: 18) {
            Image(systemName: "hands.clap.fill")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(orange)

            Text("Well done!")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Text("Goal completed! Start learning again or set a new learning goal.")
                .multilineTextAlignment(.center)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 24)

            NavigationLink(destination: EditGoalView()) {
                Text("Set new learning goal")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 22)
                    .background(
                        Capsule()
                            .fill(orange)
                            .overlay(Capsule().stroke(orangeStroke.opacity(0.8), lineWidth: 1))
                    )
            }

            Button(action: startSameGoalAgain) {
                Text("Set same learning goal and duration")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(orange)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private func startSameGoalAgain() {
        let today = Date().stripTime()
        periodStartRaw = today.key()
        awaitingFirstLog = true
        selectedDate = today
        weekStart = today.startOfWeek()
        goalRevision &+= 1
        pickedMonth = Calendar.current.component(.month, from: today)
        pickedYear  = Calendar.current.component(.year,  from: today)
    }
}

// MARK: - Month/Year Picker (Wheel)
extension ActivityView {
    private var monthYearPicker: some View {
        let months = Calendar.current.monthSymbols

        return VStack(spacing: 16) {
            HStack {
                Text("\(months[pickedMonth-1]) \(pickedYear)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(orange)
                Spacer()
                Button {
                    if let first = Calendar.current.date(from: DateComponents(year: pickedYear, month: pickedMonth, day: 1)) {
                        weekStart    = first.startOfWeek()
                        selectedDate = first
                    }
                    monthPickerShown = false
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(RoundedRectangle(cornerRadius: 10).fill(orange))
                }
            }
            .padding(.horizontal, 6)

            ZStack {
                HStack(spacing: 20) {
                    Picker("", selection: $pickedMonth) {
                        ForEach(1...12, id: \.self) { m in
                            Text(months[m-1]).tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .clipped()

                    Picker("", selection: $pickedYear) {
                        ForEach(2000...2100, id: \.self) { y in
                            Text("\(y)").tag(y)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .clipped()
                }
                .labelsHidden()
                .frame(height: 190)
                .colorScheme(.dark)

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.10))
                    .frame(height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 6)
        }
        .padding(20)
        .background(Color.black.ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Mutations
extension ActivityView {
    private func setStatus(_ newStatus: DayStatus, for date: Date) {
        var map = progress
        map[date.key()] = newStatus
        writeProgress(map)
        // أول Log بعد تحديث الهدف → ارجع العرض للوضع الطبيعي للفترة الحالية فقط
        if isShowingCurrentPeriod { awaitingFirstLog = false }
    }
}

// MARK: - Helpers
private extension Date {
    func stripTime() -> Date { Calendar.current.startOfDay(for: self) }
    func startOfWeek() -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return cal.date(from: comps)!.stripTime()
    }
    func monthYearString() -> String {
        let f = DateFormatter(); f.dateFormat = "LLLL yyyy"; return f.string(from: self)
    }
    func weekdayShort() -> String {
        let f = DateFormatter(); f.dateFormat = "EEE"; return f.string(from: self).uppercased()
    }
    func key() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        f.locale = .init(identifier: "en_US_POSIX")
        return f.string(from: self)
    }
}

private extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xff) / 255
        let g = Double((hex >> 08) & 0xff) / 255
        let b = Double((hex >> 00) & 0xff) / 255
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

#Preview {
    NavigationStack { ActivityView() }
}
