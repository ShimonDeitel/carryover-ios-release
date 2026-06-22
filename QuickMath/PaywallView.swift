import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    private let proFeatures = [
        ("chart.bar.fill", "Age insights showing your most-procrastinated tasks over time"),
        ("clock.arrow.trianglehead.2.counterclockwise.rotate.90", "Snooze, schedule and bulk-drop carried items"),
        ("bell.badge.fill", "Custom rollover time and a morning carry-over reminder")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 28) {
                            // Header
                            VStack(spacing: 10) {
                                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                                    .font(.system(size: 52))
                                    .foregroundStyle(Color.qmAccent)
                                    .padding(.top, 8)

                                Text("Carryover Pro")
                                    .font(.title.weight(.bold))
                                    .foregroundStyle(.primary)

                                Text("$0.99 / month. Auto-renews until you cancel.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 12)

                            // Benefits
                            VStack(spacing: 0) {
                                ForEach(proFeatures.indices, id: \.self) { i in
                                    let (icon, text) = proFeatures[i]
                                    HStack(alignment: .top, spacing: 14) {
                                        Image(systemName: icon)
                                            .font(.system(size: 20))
                                            .foregroundStyle(Color.qmAccent)
                                            .frame(width: 28)
                                            .padding(.top, 1)
                                        Text(text)
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    if i < proFeatures.count - 1 {
                                        Divider().padding(.leading, 58)
                                    }
                                }
                            }
                            .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal)

                            // Disclosure
                            Text("Subscription automatically renews monthly at \(store.displayPrice) unless cancelled at least 24 hours before the end of the current period. Cancel anytime in your Apple Account settings.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)

                            // Terms & Privacy
                            HStack(spacing: 20) {
                                Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                                    .font(.caption)
                                    .foregroundStyle(Color.qmAccent)
                                Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/carryover-site/privacy.html")!)
                                    .font(.caption)
                                    .foregroundStyle(Color.qmAccent)
                            }

                            Spacer(minLength: 120)
                        }
                    }

                    // Bottom CTA
                    VStack(spacing: 12) {
                        Button {
                            Task { await store.purchase() }
                        } label: {
                            Group {
                                if store.purchaseInFlight {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Unlock Carryover Pro")
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .prominentButton()
                        .disabled(store.purchaseInFlight)
                        .padding(.horizontal)

                        Button {
                            Task { await store.restore() }
                        } label: {
                            Text("Restore Purchase")
                                .font(.subheadline)
                                .foregroundStyle(Color.qmAccent)
                        }
                        .buttonStyle(.plain)

                        Spacer(minLength: 8)
                    }
                    .padding(.top, 8)
                    .background(.ultraThinMaterial)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
            .onChange(of: store.isPro) { _, newVal in
                if newVal { dismiss() }
            }
        }
    }
}
