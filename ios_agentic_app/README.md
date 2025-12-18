# Productivity Agentic iOS App

**Enterprise-Grade Knowledge Escort Service**

A native Swift iOS app that demonstrates **elegance of reasoning** through sophisticated agentic architecture, knowledge management, and reasoning capabilities—not just UI polish.

## Philosophy

> "We prove our worthiness not through design, but through something much rarer: elegance of reasoning and a personal enterprise-grade knowledge escort service."

This app focuses on:
- **Reasoning Excellence** - Sophisticated planning, reflection, and self-correction
- **Knowledge Escort** - A knowledge system that guides and enhances your work
- **Enterprise-Grade** - Reliability, observability, and production-quality reasoning

## Architecture

### Reasoning Engine

The `ReasoningEngine` orchestrates a sophisticated reasoning loop:

1. **Understand** - Extract intent, entities, and context
2. **Retrieve Knowledge** - Multi-strategy knowledge retrieval (semantic + graph)
3. **Plan** - Knowledge-informed planning
4. **Execute** - Tool execution with error recovery
5. **Reflect** - Self-reflection and plan revision
6. **Integrate** - Knowledge integration and learning

### Knowledge Escort Service

A comprehensive knowledge management system:

- **Vector Memory** - Semantic search with embeddings (MLX-ready)
- **Knowledge Graph** - Entity-relationship graph for structured knowledge
- **Context Manager** - Conversation and knowledge context tracking
- **Multi-Strategy Retrieval** - Combines semantic search, graph traversal, and temporal filtering

### Key Components

```
┌─────────────────────────────────────────┐
│      Reasoning Engine                   │
│  (Understand → Plan → Execute → Reflect)│
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      Knowledge Escort                   │
│  (Vector Memory + Graph + Context)      │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      Tools Layer                         │
│  (HTTP, Files, Calendar, Tasks, etc.)    │
└─────────────────────────────────────────┘
```

## Features

### Reasoning Capabilities

- **Intent Understanding** - Entity extraction and intent classification
- **Knowledge-Informed Planning** - Plans leverage retrieved knowledge
- **Self-Reflection** - Analyzes execution and revises plans
- **Error Recovery** - Attempts recovery from failures
- **Reasoning Traces** - Full observability of reasoning process

### Knowledge Management

- **Semantic Search** - Vector-based similarity search (MLX-ready)
- **Knowledge Graph** - Entity-relationship graph traversal
- **Context Awareness** - Temporal and conversation context
- **Knowledge Integration** - Automatic extraction and integration
- **Suggestions** - Proactive knowledge suggestions

### Enterprise-Grade

- **Observability** - Reasoning traces and context snapshots
- **Reliability** - Error recovery and plan revision
- **Scalability** - Efficient vector search and graph traversal
- **Safety** - Tool policy enforcement and security gates

## Project Structure

```
ios_agentic_app/
├── Sources/
│   ├── AgentCore/              # Core agent types
│   │   ├── AgentTypes.swift
│   │   ├── Agent.swift         # Main agent (uses ReasoningEngine)
│   │   ├── Planner.swift        # Planning (MLX-ready)
│   │   ├── Memory.swift         # Message memory
│   │   └── Tooling.swift       # Tool protocol
│   │
│   ├── Reasoning/              # Reasoning architecture
│   │   └── ReasoningEngine.swift  # Main reasoning loop
│   │
│   ├── Knowledge/              # Knowledge escort service
│   │   ├── KnowledgeEscort.swift    # Main knowledge service
│   │   ├── KnowledgeGraph.swift      # Entity-relationship graph
│   │   ├── VectorMemory.swift        # Semantic search (MLX-ready)
│   │   └── ContextManager.swift      # Context tracking
│   │
│   ├── Tools/                  # Agent tools
│   │   ├── HTTPTool.swift
│   │   ├── FilesTool.swift
│   │   ├── CalendarTool.swift
│   │   ├── ClipboardTool.swift
│   │   └── TasksTool.swift
│   │
│   └── UI/                     # SwiftUI views
│       ├── ContentView.swift
│       ├── TimelineView.swift
│       ├── TasksView.swift
│       ├── AgentConsoleView.swift
│       └── SettingsView.swift
```

## Reasoning Flow

### Example: "Create a task to finish the report by Friday"

1. **Understand**
   - Intent: `create`
   - Entities: `task`, `report`, `Friday`
   - Context: Current date, user preferences

2. **Retrieve Knowledge**
   - Semantic search: "task creation patterns"
   - Graph traversal: Related tasks, similar deadlines
   - Temporal context: Upcoming Friday

3. **Plan**
   - Step 1: Use TasksTool to create task
   - Step 2: Set due date to Friday
   - Step 3: Confirm creation

4. **Execute**
   - Call TasksTool with extracted parameters
   - Handle any errors

5. **Reflect**
   - Check if task was created successfully
   - Analyze execution quality
   - Revise plan if needed

6. **Integrate Knowledge**
   - Extract: "User creates tasks with deadlines"
   - Add to knowledge graph
   - Update vector memory
   - Update context

## MLX Integration (Ready)

The architecture is designed for MLX integration:

- **Planner** - Replace heuristic with MLX LLM
- **Vector Memory** - Use MLX embedding model
- **Reasoning** - Use MLX for intent understanding, reflection, answer synthesis
- **Knowledge Extraction** - Use MLX for entity extraction and knowledge parsing

## Usage

### Basic Agent Interaction

```swift
let agent = Agent(...)
let messages = try await agent.handle(userInput: "Create a task")
```

### Knowledge Escort

```swift
let answer = try await agent.answer("What tasks do I have?")
// Returns: KnowledgeAnswer with answer, confidence, sources, reasoning
```

### Reasoning Trace

```swift
let result = try await reasoningEngine.reason(about: userInput)
let trace = result.trace
// Full observability of reasoning process
```

## Next Steps

1. **MLX Integration** - Add MLX LLM for planning and reasoning
2. **Enhanced Knowledge Extraction** - Use MLX for better entity extraction
3. **Observability UI** - Visualize reasoning traces and knowledge graph
4. **Long-Term Memory** - Persistent knowledge across sessions
5. **Multi-Modal** - Support images, documents, etc.

## Philosophy

This app demonstrates that **elegance of reasoning** is more valuable than UI polish. The architecture prioritizes:

- **Sophisticated Reasoning** - Not just pattern matching, but true understanding
- **Knowledge Integration** - Learning and improving over time
- **Enterprise Reliability** - Production-grade error handling and observability
- **Extensibility** - Ready for MLX and future enhancements

## License

MIT
