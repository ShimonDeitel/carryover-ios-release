import SwiftUI
import Charts

/// Pro feature: age insights showing most-procrastinated tasks over time.
struct InsightsView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        // Summary tiles
                        HStack(spacing: 12) {
                            MetricTile(
                                value: "\(appModel.totalCarriedToday)",
                                label: "Carried Today"
                            )
                            MetricTile(
                                value: String(format: "%.1f", appModel.avgCarryCount),
                                label: "Avg Days"
                            )
                            MetricTile(
                                value: "\(appModel.topProcrastinated.count)",
                                label: "Still Open"
                            )
                        }
                        .padding(.horizontal)

                        // Most procrastinated chart
                        if !appModel.topProcrastinated.isEmpty {
                            procrastinatedCard
                        }

                        // Task age breakdown
                        ageBreakdownCard

                        // Bulk drop section (Pro)
                        if !appModel.topProcrastinated.isEmpty {
                            bulkActionsCard
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Age Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
        }
    }

    // MARK: - Charts Card

    private var procrastinatedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Most Procrastinated")
                .font(.headline)
                .foregroundStyle(.primary)

            let top5 = Array(appModel.topProcrastinated.prefix(5))
            Chart(top5) { task in
                BarMark(
                    x: .value("Days", task.carryCount),
                    y: .value("Task", shortenedTitle(task.title))
                )
                .foregroundStyle(
                    task.carryCount >= 7 ? Color.qmWrong :
                    task.carryCount >= 3 ? Color.qmAccent : Color.qmCorrect
                )
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text("\(task.carryCount)d")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: CGFloat(top5.count) * 44 + 20)
        }
        .qmCard()
        .padding(.horizontal)
    }

    // MARK: - Age breakdown

    private var ageBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Task Age Breakdown")
                .font(.headline)
                .foregroundStyle(.primary)

            let all = appModel.topProcrastinated
            let fresh = all.filter { $0.carryCount == 0 }.count
            let aging = all.filter { $0.carryCount >= 1 && $0.carryCount < 7 }.count
            let old = all.filter { $0.carryCount >= 7 }.count

            ForEach([
                ("Fresh (Today)", fresh, Color.qmCorrect),
                ("Aging (1-6d)", aging, Color.qmAccent),
                ("Old (7d+)", old, Color.qmWrong)
            ], id: \.0) { label, count, color in
                HStack {
                    Circle().fill(color).frame(width: 8, height: 8)
                    Text(label).font(.subheadline).foregroundStyle(.primary)
                    Spacer()
                    Text("\(count)").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                }
            }
        }
        .qmCard()
        .padding(.horizontal)
    }

    // MARK: - Bulk Actions (Pro)

    private var bulkActionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bulk Actions")
                .font(.headline)
                .foregroundStyle(.primary)

            Button {
                let oldTasks = appModel.topProcrastinated.filter { $0.carryCount >= 14 }
                oldTasks.forEach { appModel.dropTask($0) }
                Haptics.warning()
            } label: {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Drop tasks carried 14+ days")
                }
                .foregroundStyle(Color.qmWrong)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 4)
        }
        .qmCard()
        .padding(.horizontal)
    }

    private func shortenedTitle(_ title: String) -> String {
        title.count > 20 ? String(title.prefix(17)) + "..." : title
    }
}
