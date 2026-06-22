import SwiftUI
import SwiftData

// MARK: - SwiftData Models

@Model
final class CarryTask {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdDate: Date
    var completedDate: Date?
    var carryCount: Int
    var dropped: Bool

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.createdDate = Date()
        self.completedDate = nil
        self.carryCount = 0
        self.dropped = false
    }

    var isComplete: Bool { completedDate != nil }
    var isActive: Bool { !dropped && !isComplete }
    var ageDescription: String {
        if carryCount == 0 { return "Today" }
        if carryCount == 1 { return "1 day carried" }
        return "\(carryCount) days carried"
    }
}

@Model
final class DailyRollover {
    @Attribute(.unique) var id: UUID
    var date: Date
    var carriedTaskIDs: [UUID]

    init(date: Date, carriedTaskIDs: [UUID]) {
        self.id = UUID()
        self.date = date
        self.carriedTaskIDs = carriedTaskIDs
    }
}

@Model
final class AppSetting {
    @Attribute(.unique) var id: UUID
    var rolloverHour: Int
    var theme: String

    init(rolloverHour: Int = 7, theme: String = "system") {
        self.id = UUID()
        self.rolloverHour = rolloverHour
        self.theme = theme
    }
}

// MARK: - AppModel

@MainActor
final class AppModel: ObservableObject {
    let container: ModelContainer
    weak var store: Store?

    @Published private(set) var activeTasks: [CarryTask] = []
    @Published private(set) var completedTasks: [CarryTask] = []
    @Published private(set) var droppedTasks: [CarryTask] = []

    init(container: ModelContainer) {
        self.container = container
        reload()
        performRolloverIfNeeded()
    }

    static func makeContainer() -> ModelContainer {
        let schema = Schema([CarryTask.self, DailyRollover.self, AppSetting.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return (try? ModelContainer(for: schema, configurations: [fallback]))!
        }
    }

    func reload() {
        let ctx = container.mainContext
        let allTasks = (try? ctx.fetch(FetchDescriptor<CarryTask>())) ?? []
        activeTasks = allTasks
            .filter { $0.isActive }
            .sorted { $0.carryCount > $1.carryCount }
        completedTasks = allTasks
            .filter { $0.isComplete }
            .sorted { ($0.completedDate ?? .distantPast) > ($1.completedDate ?? .distantPast) }
        droppedTasks = allTasks
            .filter { $0.dropped && !$0.isComplete }
            .sorted { $0.createdDate > $1.createdDate }
    }

    func refresh() { reload() }

    // MARK: - Task Operations

    func addTask(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let task = CarryTask(title: trimmed)
        container.mainContext.insert(task)
        try? container.mainContext.save()
        reload()
        Haptics.success()
    }

    func completeTask(_ task: CarryTask) {
        task.completedDate = Date()
        try? container.mainContext.save()
        reload()
        Haptics.success()
    }

    func uncompleteTask(_ task: CarryTask) {
        task.completedDate = nil
        try? container.mainContext.save()
        reload()
    }

    func dropTask(_ task: CarryTask) {
        task.dropped = true
        try? container.mainContext.save()
        reload()
        Haptics.warning()
    }

    func restoreTask(_ task: CarryTask) {
        task.dropped = false
        try? container.mainContext.save()
        reload()
    }

    func deleteTask(_ task: CarryTask) {
        container.mainContext.delete(task)
        try? container.mainContext.save()
        reload()
    }

    // MARK: - Rollover Logic

    private func performRolloverIfNeeded() {
        let ctx = container.mainContext
        let today = Calendar.current.startOfDay(for: Date())

        let rollovers = (try? ctx.fetch(FetchDescriptor<DailyRollover>())) ?? []
        let todayRollover = rollovers.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
        guard todayRollover == nil else { return }

        let allTasks = (try? ctx.fetch(FetchDescriptor<CarryTask>())) ?? []
        let carried = allTasks.filter { $0.isActive }
        for t in carried { t.carryCount += 1 }

        let rollover = DailyRollover(date: today, carriedTaskIDs: carried.map { $0.id })
        ctx.insert(rollover)
        try? ctx.save()
        reload()
    }

    // MARK: - Insights (Pro)

    var topProcrastinated: [CarryTask] {
        let all = (try? container.mainContext.fetch(FetchDescriptor<CarryTask>())) ?? []
        return all.filter { !$0.isComplete }.sorted { $0.carryCount > $1.carryCount }
    }

    var totalCarriedToday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let rollovers = (try? container.mainContext.fetch(FetchDescriptor<DailyRollover>())) ?? []
        return rollovers.first { Calendar.current.isDate($0.date, inSameDayAs: today) }?.carriedTaskIDs.count ?? 0
    }

    var avgCarryCount: Double {
        let all = (try? container.mainContext.fetch(FetchDescriptor<CarryTask>())) ?? []
        guard !all.isEmpty else { return 0 }
        return Double(all.reduce(0) { $0 + $1.carryCount }) / Double(all.count)
    }

    var longestStreakTaskTitle: String? {
        topProcrastinated.first?.title
    }

    // MARK: - Delete All

    func deleteAllData() {
        let ctx = container.mainContext
        let tasks = (try? ctx.fetch(FetchDescriptor<CarryTask>())) ?? []
        tasks.forEach { ctx.delete($0) }
        let rollovers = (try? ctx.fetch(FetchDescriptor<DailyRollover>())) ?? []
        rollovers.forEach { ctx.delete($0) }
        let settings = (try? ctx.fetch(FetchDescriptor<AppSetting>())) ?? []
        settings.forEach { ctx.delete($0) }
        try? ctx.save()
        reload()
    }
}
