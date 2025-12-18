# ClauseLang Integration

ClauseLang integration for the iOS agentic app, providing structured contract primitives for agent policies and privacy policy ingestion.

## Overview

ClauseLang enables:
- **Structured Policy Representation**: Convert natural language policies into structured primitives
- **Privacy Policy Ingestion**: Parse privacy policies into ClauseLang clauses
- **Policy Enforcement**: Enforce policies at the tool and reasoning level
- **Semantic Role Mapping**: Map actors, data types, and jurisdictions
- **Modular Storage**: Store policies as YAML/JSON with modular clause references

## Architecture

```
ClauseLang/
├── ClauseLangTypes.swift          # Core types (Clause, Condition, Action, ContractPrimitive)
├── ClauseLangParser.swift         # Parser for ClauseLang syntax
├── ClauseLangPolicy.swift         # Policy system integration
├── SemanticRoleMapper.swift      # Semantic role/data type/jurisdiction mapping
└── ClauseLangStorage.swift        # YAML/JSON storage and modular policy management
```

## Core Concepts

### ClauseLang Syntax

ClauseLang uses a simple "WHEN ... THEN ..." syntax:

```swift
"WHEN consent == 'explicit' THEN allow_access"
"WHEN duration > 90 days THEN delete_data"
"WHEN role == 'processor' THEN notify_controller"
```

### Clause Types

- `consent` - Consent-based access control
- `retention` - Data retention policies
- `sharing` - Data sharing policies
- `deletion` - Data deletion policies
- `access` - Access control policies
- `notification` - Notification requirements
- `security` - Security requirements
- `toolPolicy` - Tool usage policies
- `agentBehavior` - Agent behavior policies

### Semantic Roles

- `dataSubject` - Data subject (user)
- `controller` - Data controller (organization)
- `processor` - Data processor (third party)
- `agent` - AI agent
- `user` - User role
- `system` - System role

### Data Types

- `personalData` - Personal data
- `metadata` - Metadata
- `sensitiveData` - Sensitive data
- `biometricData` - Biometric data
- `locationData` - Location data

### Jurisdictions

- `GDPR` - European Union GDPR
- `CCPA` - California Consumer Privacy Act
- `PIPEDA` - Canadian privacy law
- `LGPD` - Brazilian privacy law
- `custom` - Custom jurisdiction

## Usage

### Parsing ClauseLang Syntax

```swift
let parser = ClauseLangParser()
let clause = try await parser.parse("WHEN consent == 'explicit' THEN allow_access")
```

### Creating a Policy

```swift
let contract = ContractPrimitive(
    id: "privacy-policy-001",
    title: "Privacy Policy",
    parties: [.dataSubject, .controller],
    clauses: [clause],
    jurisdiction: .GDPR
)
```

### Policy Enforcement

```swift
let policy = ClauseLangPolicy(
    basePolicy: toolPolicy,
    clauses: [clause],
    contracts: [contract]
)

let result = policy.evaluateToolAction(
    toolName: "http",
    arguments: ["url": "https://example.com"],
    context: evaluationContext
)

if result.isAllowed {
    // Proceed with tool execution
}
```

### Privacy Policy Ingestion

```swift
let tool = PrivacyPolicyIngestionTool(parser: parser, knowledgeEscort: knowledgeEscort)
let result = try await tool.call(
    args: [
        "policy_text": privacyPolicyText,
        "jurisdiction": "GDPR",
        "extract_clauses": "true"
    ],
    policy: toolPolicy
)
```

### Semantic Role Mapping

```swift
let mapper = SemanticRoleMapper()
let role = await mapper.mapRole("data subject") // Returns .dataSubject
let dataType = await mapper.mapDataType("personal information") // Returns .personalData
let jurisdiction = await mapper.mapJurisdiction("GDPR") // Returns .GDPR
```

### Storage

```swift
let storage = ClauseLangStorage()
try await storage.savePolicyDocument(policyDocument)
let loaded = try await storage.loadPolicyDocument(filename: "policy.json")

// Modular clause storage
try await storage.saveClause(clause)
let clause = try await storage.loadClause(id: "clause-001")
```

## Integration with ReasoningEngine

The `ReasoningEngine` now supports ClauseLang policies:

```swift
let reasoningEngine = ReasoningEngine(
    planner: planner,
    knowledgeBase: knowledgeEscort,
    tools: tools,
    memory: memory,
    mlxLLM: mlxLLM,
    clauseLangPolicy: clauseLangPolicy
)
```

Policies are automatically enforced during tool execution, with violations logged and execution blocked.

## Privacy Policy Ingestion Process

1. **Parse Text**: Extract clauses from natural language privacy policy
2. **Map to ClauseLang**: Convert extracted clauses to ClauseLang syntax
3. **Create Contract**: Build ContractPrimitive with semantic roles and jurisdictions
4. **Store**: Save to knowledge base and storage system

## Future Enhancements

- [ ] YAML parsing support (currently JSON only)
- [ ] MLX-powered clause extraction from natural language
- [ ] Advanced condition operators (regex, time-based)
- [ ] Policy versioning and migration
- [ ] Policy conflict resolution
- [ ] Policy audit logging
- [ ] Integration with knowledge graph for policy relationships

## References

- ClauseLang syntax specification
- Agent Contract Primitives framework
- SemanticOS fundamentals (to be integrated)
