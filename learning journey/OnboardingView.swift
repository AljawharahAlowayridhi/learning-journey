

// (1) OnboardingView.swift
import SwiftUI

struct OnboardingView: View {
    @State private var learningTopic: String = "Swift"
    @State private var timeFrame: TimeFrame = .week
    @State private var navigateToActivity = false   // 👈 حالة التنقل

    // 👇 AppStorage — نفس المفاتيح المستخدمة في ActivityView
    @AppStorage("learning.topic") private var storedTopic: String = "Swift"
    @AppStorage("learning.timeframe") private var storedTimeframeRaw: String = "Week"
    @AppStorage("goal.periodStart") private var periodStartRaw: String = ""
    @AppStorage("goal.revision") private var goalRevision: Int = 0
    @AppStorage("progress.map") private var progressRaw: String = "{}" // لا نصفر القديم

    // 👇 مفتاح إرجاع واجهة Activity لليوم/الأسبوع المناسب
    @AppStorage("ui.returnDate") private var uiReturnDateRaw: String = ""

    enum TimeFrame: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer().frame(height: 56)

                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.04))
                            .frame(width: 132, height: 132)
                            .shadow(color: Color.black.opacity(0.8), radius: 22, x: 0, y: 10)
                            .glassStroke()
                        
                        Image(systemName: "flame.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    .padding(.bottom, 28)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hello Learner")
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundColor(.white)
                        Text("This app will help you learn everyday!")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.65))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 28)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("I want to learn")
                            .foregroundColor(.white.opacity(0.88))
                            .font(.system(size: 20, weight: .semibold))
                        
                        ZStack(alignment: .leading) {
                            if learningTopic.isEmpty {
                                Text("Swift")
                                    .foregroundColor(.white.opacity(0.65))
                            }
                            TextField("", text: $learningTopic)
                                .foregroundColor(.white)
                                .font(.system(size: 18))
                        }
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 28)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("I want to learn it in a")
                            .foregroundColor(.white.opacity(0.88))
                            .font(.system(size: 20, weight: .semibold))
                        
                        HStack(spacing: 16) {
                            ForEach(TimeFrame.allCases) { frame in
                                Button {
                                    withAnimation(.spring()) {
                                        timeFrame = frame
                                    }
                                } label: {
                                    Text(frame.rawValue)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 22)
                                        .background(
                                            Capsule()
                                                .fill(Color.white.opacity(0.06))
                                                .glassStroke()
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(
                                                    timeFrame == frame
                                                    ? Color.orange
                                                    : Color.white.opacity(0.18),
                                                    lineWidth: 1
                                                )
                                        )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 32)

                    Spacer()

                    // ✅ زر Start learning يكتب إلى AppStorage ثم ينتقل
                    Button {
                        let topic = learningTopic.trimmingCharacters(in: .whitespacesAndNewlines)
                        storedTopic = topic.isEmpty ? "Swift" : topic
                        storedTimeframeRaw = timeFrame.rawValue

                        // ابدأ فترة الهدف من اليوم
                        let today = Date().stripTime()
                        let todayKey = today.key()
                        periodStartRaw = todayKey

                        // تأكد أن progress.map مهيأة (لا نمسح الموجود)
                        if progressRaw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            progressRaw = "{}"
                        }

                        // حدّد أقرب يوم "غير مُسجّل" بين periodStart..اليوم لفتح Activity عليه
                        uiReturnDateRaw = nextUnloggedDateKey(from: today) ?? todayKey

                        // إشارة بدء/تحديث هدف → ActivityView يفعّل الأزرار فورًا ويقرأ ui.returnDate
                        goalRevision &+= 1

                        navigateToActivity = true
                    } label: {
                        Text("Start learning")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                ZStack {
                                    // اللون الأساسي البرتقالي
                                    Capsule()
                                        .fill(Color(hex: 0xB85E2E))
                                    // طبقة زجاجية شفافة فوق اللون
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                        .opacity(0.35)
                                    // حافة زجاجية خفيفة (انعكاس)
                                    Capsule()
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [
                                                    .white.opacity(0.45),
                                                    .white.opacity(0.15),
                                                    Color(hex: 0xD48241).opacity(0.5)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.4
                                        )
                                }
                            )
                            .shadow(color: Color(hex: 0xB85E2E).opacity(0.5), radius: 12, x: 0, y: 6)
                    }
                    .padding(.horizontal, 80)
                    .padding(.bottom, 40)

                    // 👇 Navigation destination
                    NavigationLink("", destination: ActivityView(), isActive: $navigateToActivity)
                        .hidden()
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

// نفس الامتدادات السابقة
private extension View {
    func glassStroke(highlight: Color = .white.opacity(0.5)) -> some View {
        modifier(GlassStroke(highlight: highlight))
    }
}

private struct GlassStroke: ViewModifier {
    var highlight: Color = .white.opacity(0.5)
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 100, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.55), .white.opacity(0.12), highlight.opacity(0.45), .white.opacity(0.12)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
    }
}

// MARK: - Helpers
private extension Date {
    func stripTime() -> Date { Calendar.current.startOfDay(for: self) }
    func key() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        f.locale = .init(identifier: "en_US_POSIX")
        return f.string(from: self)
    }
}

// MARK: - Progress helpers (لا نستخدم DayStatus هنا)
private extension OnboardingView {
    /// يعيد أول تاريخ بلا Log/Freeze من start .. اليوم. إن لم يوجد يرجع اليوم.
    func nextUnloggedDateKey(from start: Date) -> String? {
        // فك JSON كـ [String: String]
        let dict: [String: String] = {
            if let data = progressRaw.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                return obj
            }
            return [:]
        }()

        var d = start.stripTime()
        let end = Date().stripTime()
        while d <= end {
            let k = d.key()
            let v = dict[k] ?? "none"
            if v == "none" { return k }
            d = Calendar.current.date(byAdding: .day, value: 1, to: d)!.stripTime()
        }
        return end.key()
    }
}

// MARK: - Color hex initializer
private extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b).opacity(alpha)
    }
}

// MARK: - Preview
#Preview {
    OnboardingView()
}
