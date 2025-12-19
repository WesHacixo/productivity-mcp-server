// Consent Management View: User consent flows with real effects
// Ethics-as-product-feature with legible governance
import SwiftUI

@MainActor
class ConsentViewModel: ObservableObject {
    @Published var consentState: ConsentState
    @Published var auditTrail: [AuditEntry] = []
    private let governance: GovernanceSystem
    
    init(governance: GovernanceSystem) {
        self.governance = governance
        // Load initial state (in real implementation)
        self.consentState = ConsentState()
    }
    
    func loadState() async {
        // Load from governance system
        // For now, use default
    }
    
    func toggleLearning() async {
        if consentState.learningEnabled {
            await governance.revokeConsent(for: "learning")
        } else {
            await governance.grantConsent(for: "learning")
        }
        await loadState()
    }
    
    func toggleDataStorage() async {
        if consentState.dataStorageEnabled {
            await governance.revokeConsent(for: "data_storage")
        } else {
            await governance.grantConsent(for: "data_storage")
        }
        await loadState()
    }
    
    func toggleDataSharing() async {
        if consentState.dataSharingEnabled {
            await governance.revokeConsent(for: "data_sharing")
        } else {
            await governance.grantConsent(for: "data_sharing")
        }
        await loadState()
    }
    
    func deleteAllData() async {
        await governance.deleteUserData()
        await loadState()
    }
    
    func loadAuditTrail() async {
        auditTrail = await governance.getAuditTrail(limit: 50)
    }
}

struct ConsentManagementView: View {
    @StateObject private var viewModel: ConsentViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(governance: GovernanceSystem) {
        _viewModel = StateObject(wrappedValue: ConsentViewModel(governance: governance))
    }
    
    var body: some View {
        NavigationView {
            List {
                // Consent toggles
                Section("Consent Settings") {
                    ConsentToggle(
                        title: "Learning & Pattern Recognition",
                        description: "Allow the app to learn from your usage patterns to improve suggestions",
                        isEnabled: viewModel.consentState.learningEnabled,
                        action: { await viewModel.toggleLearning() }
                    )
                    
                    ConsentToggle(
                        title: "Data Storage",
                        description: "Store your tasks, schedules, and knowledge graph locally",
                        isEnabled: viewModel.consentState.dataStorageEnabled,
                        action: { await viewModel.toggleDataStorage() }
                    )
                    
                    ConsentToggle(
                        title: "Data Sharing",
                        description: "Sync data across devices (currently disabled)",
                        isEnabled: viewModel.consentState.dataSharingEnabled,
                        action: { await viewModel.toggleDataSharing() }
                    )
                }
                
                // Audit trail
                Section("Audit Trail") {
                    ForEach(viewModel.auditTrail) { entry in
                        AuditEntryRow(entry: entry)
                    }
                }
                
                // Data deletion
                Section {
                    Button(role: .destructive, action: {
                        Task {
                            await viewModel.deleteAllData()
                        }
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete All Data")
                        }
                    }
                } footer: {
                    Text("This will permanently delete all stored data, embeddings, and knowledge graph. This action cannot be undone.")
                }
            }
            .navigationTitle("Privacy & Consent")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadState()
                await viewModel.loadAuditTrail()
            }
        }
    }
}

struct ConsentToggle: View {
    let title: String
    let description: String
    let isEnabled: Bool
    let action: () async -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(title, isOn: Binding(
                get: { isEnabled },
                set: { _ in Task { await action() } }
            ))
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct AuditEntryRow: View {
    let entry: AuditEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.action)
                    .font(.body)
                Spacer()
                Text(entry.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let data = entry.data, !data.isEmpty {
                Text(data.map { "\($0.key): \($0.value)" }.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
