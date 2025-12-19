// Policy Transparency View: "Why this suggestion" panel
// Shows clauses used, inputs, and what wasn't used
import SwiftUI

struct PolicyTransparencyView: View {
    let explanation: SuggestionExplanation
    @Environment(\.dismiss) private var dismiss
    @State private var selectedClause: Clause?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Explanation text
                    explanationSection
                    
                    // Clauses used
                    clausesSection
                    
                    // Inputs used
                    inputsUsedSection
                    
                    // Inputs not used
                    if !explanation.inputsNotUsed.isEmpty {
                        inputsNotUsedSection
                    }
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
            .sheet(item: $selectedClause) { clause in
                NavigationView {
                    let doc = RicardianRenderer.render(clause)
                    RicardianDocumentView(document: doc)
                }
            }
        }
    }
    
    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Explanation")
                .font(.headline)
            Text(explanation.explanation)
                .font(.body)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var clausesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Clauses Used")
                .font(.headline)
            
            ForEach(explanation.clauses, id: \.id) { clause in
                Button(action: { selectedClause = clause }) {
                    ClauseCardView(clause: clause)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var inputsUsedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Inputs Used")
                .font(.headline)
            
            ForEach(Array(explanation.inputsUsed.keys.sorted()), id: \.self) { key in
                HStack {
                    Text(key)
                        .font(.body)
                    Spacer()
                    Text(formatValue(explanation.inputsUsed[key]!))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var inputsNotUsedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Inputs Not Used")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ForEach(explanation.inputsNotUsed, id: \.self) { input in
                Text("• \(input)")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatValue(_ value: AnyCodable) -> String {
        switch value.value {
        case let string as String:
            return string
        case let number as Double:
            return String(format: "%.2f", number)
        case let bool as Bool:
            return String(bool)
        default:
            return "\(value.value)"
        }
    }
}

struct ClauseCardView: View {
    let clause: Clause
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let description = clause.description {
                Text(description)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Text(clause.raw)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}
