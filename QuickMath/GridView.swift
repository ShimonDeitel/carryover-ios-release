import SwiftUI

/// Primary entry and action screen — the full task list with swipe actions and completion.
struct GridView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showCompletedSection = false
    @State private var newTaskText = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        ZStack {
            QMBackground()
            VStack(spacing: 0) {
                // Add task bar
                HStack(spacing: 10) {
                    TextField("What's left to do?", text: $newTaskText)
                        .focused($fieldFocused)
                        .submitLabel(.done)
                        .onSubmit { submitTask() }
                        .padding(.vertical, 11)
                        .padding(.horizontal, 14)
                        .background(Color.qmField, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Button(action: submitTask) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(
                                newTaskText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.secondary
                                : Color.qmAccent
                            )
                    }
                    .disabled(newTaskText.trimmingCharacters(in: .whitespaces).isEmpty)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)

                Divider()

                List {
                    // Carried section (top) — tasks with carryCount > 0
                    let carried = appModel.activeTasks.filter { $0.carryCount > 0 }
                    if !carried.isEmpty {
                        Section {
                            ForEach(carried) { task in
                                taskRow(task)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            appModel.completeTask(task)
                                        } label: {
                                            Label("Done", systemImage: "checkmark.circle.fill")
                                        }
                                        .tint(Color.qmCorrect)

                                        if store.isPro {
                                            Button(role: .destructive) {
                                                appModel.dropTask(task)
                                            } label: {
                                                Label("Drop", systemImage: "xmark.circle.fill")
                                            }
                                            .tint(Color.qmWrong)
                                        }
                                    }
                            }
                        } header: {
                            HStack {
                                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                                    .foregroundStyle(Color.qmAccent)
                                Text("Carried Forward")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.caption.weight(.semibold))
                            .textCase(nil)
                        }
                    }

                    // Today section — tasks added today with no carry
                    let todayItems = appModel.activeTasks.filter { $0.carryCount == 0 }
                    if !todayItems.isEmpty {
                        Section {
                            ForEach(todayItems) { task in
                                taskRow(task)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            appModel.completeTask(task)
                                        } label: {
                                            Label("Done", systemImage: "checkmark.circle.fill")
                                        }
                                        .tint(Color.qmCorrect)
                                    }
                            }
                        } header: {
                            Text("Today")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(nil)
                        }
                    }

                    // Completed section (collapsible)
                    if !appModel.completedTasks.isEmpty {
                        Section {
                            if showCompletedSection {
                                ForEach(appModel.completedTasks.prefix(20)) { task in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.qmCorrect)
                                        Text(task.title)
                                            .foregroundStyle(.secondary)
                                            .strikethrough()
                                        Spacer()
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button {
                                            appModel.uncompleteTask(task)
                                        } label: {
                                            Label("Undo", systemImage: "arrow.uturn.backward.circle")
                                        }
                                        .tint(Color.qmAccent)
                                    }
                                }
                            }
                        } header: {
                            Button {
                                withAnimation { showCompletedSection.toggle() }
                            } label: {
                                HStack {
                                    Text("Completed (\(appModel.completedTasks.count))")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .textCase(nil)
                                    Image(systemName: showCompletedSection ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .navigationTitle("Tasks")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func taskRow(_ task: CarryTask) -> some View {
        HStack(spacing: 12) {
            Button {
                appModel.completeTask(task)
                Haptics.success()
            } label: {
                Image(systemName: "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.qmAccent)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.body)
                    .foregroundStyle(.primary)
                if task.carryCount > 0 {
                    Text(task.ageDescription)
                        .font(.caption)
                        .foregroundStyle(task.carryCount >= 5 ? Color.qmWrong : Color.qmAccent)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func submitTask() {
        let trimmed = newTaskText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        appModel.addTask(title: trimmed)
        newTaskText = ""
        fieldFocused = false
    }
}
