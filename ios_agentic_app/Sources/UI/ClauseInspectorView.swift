// Clause Inspector: Shows "why this suggestion" with ClauseLang contracts
// Governance and transparency UI for user trust
import SwiftUI

struct ClauseInspectorView: View {
    let executedClauses: [ExecutedClause]
    let flowCost: Double
    let entropy: Double
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Summary
                    summarySection
                    
                    // Executed Clauses
                    clausesSection
                    
                    // Flow Cost Analysis
                    flowCostSection
                    
                    // Entropy Status
                    entropySection
                }
                .padding()
            }
            .navigationTitle("Why This Suggestion")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary")
                .font(.headline)
            Text("This schedule was generated using \(executedClauses.count) active contracts.")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var clausesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Contracts")
                .font(.headline)
            
            ForEach(Array(executedClauses.enumerated()), id: \.offset) { index, executed in
                ClauseCard(clause: executed.clause, result: executed.result)
            }
        }
    }
    
    private var flowCostSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Flow Cost")
                .font(.headline)
            Text("Context switching cost: \(String(format: "%.2f", flowCost))")
                .font(.body)
            Text("Lower is better - this schedule minimizes context switching.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var entropySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Entropy Status")
                .font(.headline)
            
            ProgressView(value: entropy, total: 0.22)
                .progressViewStyle(.linear)
            
            Text("\(String(format: "%.0f", entropy * 100))% of entropy cap used")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if entropy >= 0.22 {
                Text("Entropy cap reached. Schedule frozen for approval.")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ClauseCard: View {
    let clause: FlowstateContract.Clause
    let result: ClauseResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Clause description (human-readable)
            Text(clause.description)
                .font(.body)
                .fontWeight(.medium)
            
            // Raw clause (machine-readable)
            Text(clause.raw)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(8)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            
            // Execution result
            HStack {
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.success ? .green : .red)
                Text(result.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Ricardian Document View

struct RicardianDocumentView: View {
    let document: RicardianDocument
    @State private var showingMachine = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Prose section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Human-Readable (Prose)")
                        .font(.headline)
                    
                    Text(document.prose)
                        .font(.body)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
                // Toggle for machine form
                Button(action: { showingMachine.toggle() }) {
                    HStack {
                        Text(showingMachine ? "Hide" : "Show")
                        Text("Machine-Executable Form")
                        Image(systemName: showingMachine ? "chevron.up" : "chevron.down")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                
                if showingMachine {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Machine-Executable (JSON)")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(document.machine)
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Clause Details")
    }
}
