import SwiftUI

struct HomeView: View {
    var forceScreen: String? = nil

    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showInsights = false
    @State private var newTaskText = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        // Metrics row
                        HStack(spacing: 12) {
                            MetricTile(
                                value: "\(appModel.activeTasks.count)",
                                label: "Open"
                            )
                            MetricTile(
                                value: "\(appModel.totalCarriedToday)",
                                label: "Carried Today"
                            )
                            MetricTile(
                                value: "\(appModel.completedTasks.count)",
                                label: "Done"
                            )
                        }
                        .padding(.horizontal)

                        // Add task field
                        HStack(spacing: 10) {
                            TextField("Add a loose end...", text: $newTaskText)
                                .focused($fieldFocused)
                                .submitLabel(.done)
                                .onSubmit { submitTask() }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 14)
                                .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                            Button(action: submitTask) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(Color.qmAccent)
                            }
                            .disabled(newTaskText.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding(.horizontal)

                        // Pro insights tile
                        Button {
                            if store.isPro { showInsights = true }
                            else { showPaywall = true }
                        } label: {
                            HStack {
                                Image(systemName: store.isPro ? "chart.bar.fill" : "lock.fill")
                                    .foregroundStyle(Color.qmAccent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Age Insights")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text(store.isPro ? "View your most-procrastinated tasks" : "Unlock with Carryover Pro")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .qmCard()
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)

                        // Task list
                        if appModel.activeTasks.isEmpty {
                            emptyState
                        } else {
                            taskList
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Carryover")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.qmAccent)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(appModel)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showInsights) {
                InsightsView()
                    .environmentObject(appModel)
                    .environmentObject(store)
            }
            .onAppear {
                handleForceScreen()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 44))
                .foregroundStyle(Color.qmCorrect)
            Text("Nothing left behind")
                .font(.headline)
                .foregroundStyle(.primary)
            Text("Add a task and Carryover will bring it forward each morning until you finish it.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private var taskList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Open Tasks")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                ForEach(appModel.activeTasks) { task in
                    TaskRow(task: task)
                        .environmentObject(appModel)
                        .environmentObject(store)
                }
            }
            .background(Color.qmCard)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal)
        }
    }

    private func submitTask() {
        let trimmed = newTaskText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        appModel.addTask(title: trimmed)
        newTaskText = ""
        fieldFocused = false
    }

    private func handleForceScreen() {
        guard let screen = forceScreen else { return }
        switch screen {
        case "settings": showSettings = true
        case "paywall": showPaywall = true
        case "insights": showInsights = true
        default: break
        }
    }
}

// MARK: - TaskRow

private struct TaskRow: View {
    let task: CarryTask
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    var body: some View {
        HStack(spacing: 14) {
            Button {
                appModel.completeTask(task)
            } label: {
                Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(task.isComplete ? Color.qmCorrect : Color.qmAccent)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .strikethrough(task.isComplete)
                if task.carryCount > 0 {
                    Text(task.ageDescription)
                        .font(.caption)
                        .foregroundStyle(task.carryCount >= 3 ? Color.qmWrong : Color.qmAccent)
                }
            }
            Spacer()

            if store.isPro {
                Menu {
                    Button("Drop Task", role: .destructive) {
                        appModel.dropTask(task)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        Divider().padding(.leading, 52)
    }
}
