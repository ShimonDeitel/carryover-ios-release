import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @AppStorage("quickmath.theme") private var themeRaw = AppTheme.system.rawValue
    @State private var showPaywall = false
    @State private var showDeleteConfirm = false
    @State private var showReminderPicker = false
    @AppStorage("carryover.reminder.hour") private var reminderHour = 7
    @AppStorage("carryover.reminder.enabled") private var reminderEnabled = false

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                List {
                    // Pro status
                    Section {
                        if store.isPro {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(Color.qmAccent)
                                Text("Carryover Pro — Active")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                                HStack {
                                    Text("Manage Subscription")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.qmAccent)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } else {
                            Button {
                                showPaywall = true
                            } label: {
                                HStack {
                                    Image(systemName: "lock.open.fill")
                                        .foregroundStyle(Color.qmAccent)
                                    Text("Unlock Carryover Pro")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.qmAccent)
                                    Spacer()
                                    Text("$0.99/mo")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)

                            Button {
                                Task { await store.restore() }
                            } label: {
                                HStack {
                                    Text("Restore Purchase")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.qmAccent)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text("Pro")
                    }

                    // Appearance
                    Section {
                        Picker("Appearance", selection: $themeRaw) {
                            ForEach(AppTheme.allCases) { theme in
                                Text(theme.label).tag(theme.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text("Appearance")
                    }

                    // Morning reminder (Pro only)
                    if store.isPro {
                        Section {
                            Toggle(isOn: $reminderEnabled) {
                                HStack {
                                    Image(systemName: "bell.fill")
                                        .foregroundStyle(Color.qmAccent)
                                    Text("Morning Reminder")
                                }
                            }
                            .onChange(of: reminderEnabled) { _, on in
                                if on {
                                    Task {
                                        let granted = await Reminders.requestAuthorization()
                                        if granted {
                                            Reminders.schedule(hour: reminderHour, minute: 0)
                                        } else {
                                            reminderEnabled = false
                                        }
                                    }
                                } else {
                                    Reminders.cancel()
                                }
                            }

                            if reminderEnabled {
                                Stepper("Remind at \(reminderHour):00", value: $reminderHour, in: 4...11)
                                    .onChange(of: reminderHour) { _, hour in
                                        Reminders.schedule(hour: hour, minute: 0)
                                    }
                            }
                        } header: {
                            Text("Notifications")
                        }
                    }

                    // Legal
                    Section {
                        Link(destination: URL(string: "https://shimondeitel.github.io/carryover-site/privacy.html")!) {
                            HStack {
                                Text("Privacy Policy")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                            HStack {
                                Text("Terms of Use")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("Legal")
                    }

                    // Danger zone
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete All Data")
                            }
                        }
                    } header: {
                        Text("Danger Zone")
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(store)
            }
            .confirmationDialog(
                "Delete all tasks, history and settings?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete All", role: .destructive) {
                    appModel.deleteAllData()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
}
