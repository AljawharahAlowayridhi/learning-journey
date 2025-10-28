// (2) EditGoalView.swift
import SwiftUI

struct EditGoalView: View {
    @Environment(\.dismiss) private var dismiss

    // الحفظ عبر AppStorage
    @AppStorage("learning.topic") private var storedTopic: String = "Swift"
    @AppStorage("learning.timeframe") private var storedTimeframeRaw: String = "Week"
    // لبدء فترة جديدة وإشعار ActivityView
    @AppStorage("goal.periodStart") private var periodStartRaw: String = ""
    @AppStorage("goal.revision") private var goalRevision: Int = 0

    @State private var topicText: String = ""
    @State private var selectedTimeframe: String = "Week"
    @State private var showConfirm: Bool = false
    @FocusState private var focusTopic: Bool

    // ألوان
    private let orange       = Color(hex: 0xB85E2E)
    private let orangeStroke = Color(hex: 0xD48241)
    private let orangeLight  = Color(hex: 0xF2A256)

    private var hasChanges: Bool {
        topicText.trimmingCharacters(in: .whitespacesAndNewlines) != storedTopic ||
        selectedTimeframe != storedTimeframeRaw
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                // النموذج
                VStack(alignment: .leading, spacing: 16) {
                    Text("I want to learn")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .medium))

                    TextField("Type your goal", text: $topicText)
                        .focused($focusTopic)
                        .padding(.vertical, 8)
                        .foregroundColor(.white)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.white.opacity(0.25)),
                            alignment: .bottom
                        )

                    Text("I want to learn it in a")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .medium))

                    HStack(spacing: 12) {
                        ForEach(["Week", "Month", "Year"], id: \.self) { period in
                            Button(action: { selectedTimeframe = period }) {
                                Text(period)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(selectedTimeframe == period ? .white : .white.opacity(0.6))
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 22)
                                    .background(
                                        Capsule()
                                            .fill(selectedTimeframe == period ? orange : Color.white.opacity(0.1))
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }

            // كارت التأكيد
            if showConfirm {
                ZStack {
                    Color.black.opacity(0.45).ignoresSafeArea()

                    VStack(spacing: 16) {
                        Text("Update Learning goal")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        Text("If you update now, your streak will start over.")
                            .multilineTextAlignment(.center)
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.75))
                            .padding(.horizontal, 8)

                        HStack(spacing: 16) {
                            Button(action: { showConfirm = false }) {
                                Text("Dismiss")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Capsule().fill(Color.white.opacity(0.15)))
                            }

                            Button(action: updateGoal) {
                                Text("Update")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Capsule().fill(orangeLight))
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(20)
                    .background(Color(hex: 0x1A1A1A))
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    )
                    .padding(.horizontal, 28)
                }
                .transition(.opacity)
            }
        }
        .navigationTitle("Learning Goal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if hasChanges {
                    Button { showConfirm = true } label: {
                        solidCheckBadge()
                    }
                    .buttonStyle(.plain)
                } else {
                    solidCheckBadge(disabled: true)
                }
            }
        }
        .onAppear {
            topicText = storedTopic
            selectedTimeframe = storedTimeframeRaw
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusTopic = true
            }
        }
        .preferredColorScheme(.dark)
    }

    // حفظ التعديلات والرجوع
    private func updateGoal() {
        storedTopic = topicText.trimmingCharacters(in: .whitespacesAndNewlines)
        storedTimeframeRaw = selectedTimeframe

        // ابدأ فترة جديدة اليوم + أشّر لـ ActivityView
        periodStartRaw = Date().stripTime().key()
        goalRevision &+= 1

        showConfirm = false
        dismiss()
    }

    // زر الصح
    @ViewBuilder
    private func solidCheckBadge(disabled: Bool = false) -> some View {
        let fillTop    = disabled ? Color.white.opacity(0.14) : Color(hex: 0xC96E33)
        let fillBottom = disabled ? Color.white.opacity(0.10) : Color(hex: 0x8E451D)

        ZStack {
            Circle()
                .fill(LinearGradient(colors: [fillTop, fillBottom],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(colors: [
                                Color.white.opacity(disabled ? 0.10 : 0.55),
                                Color.white.opacity(0.00)
                            ], startPoint: .topLeading, endPoint: .center),
                            lineWidth: 3.0
                        )
                        .blur(radius: 0.6)
                        .opacity(disabled ? 0.7 : 1)
                )
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(colors: [
                                Color.black.opacity(0.35),
                                Color.black.opacity(0.0)
                            ], startPoint: .bottomTrailing, endPoint: .center),
                            lineWidth: 3.0
                        )
                        .blur(radius: 0.6)
                )
                .shadow(color: Color.black.opacity(0.22), radius: 4, x: 0, y: 2)
                .frame(width: 36, height: 36)
                .drawingGroup()

            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(disabled ? .white.opacity(0.35) : .white)
        }
    }
}

// ألوان من هيكس
private extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xff) / 255
        let g = Double((hex >> 08) & 0xff) / 255
        let b = Double((hex >> 00) & 0xff) / 255
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

// امتدادات تاريخ
private extension Date {
    func stripTime() -> Date { Calendar.current.startOfDay(for: self) }
    func key() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        f.locale = .init(identifier: "en_US_POSIX")
        return f.string(from: self)
    }
}

#Preview {
    NavigationStack { EditGoalView() }
}
