# Ollama Codebase Review

Use the Ollama cloud coder model (`qwen3-coder:480b-cloud`) to review your entire codebase.

## Quick Start

```bash
cd /Users/damian/Projects/productivity-mcp-server
go run scripts/review_codebase_ollama.go
```

This will:
1. Collect code files (Go, TypeScript, Swift, etc.)
2. Review them in chunks using Ollama
3. Generate a comprehensive summary
4. Output results to stdout

## Options

```bash
go run scripts/review_codebase_ollama.go \
  -path . \
  -ollama-url http://100.74.59.83:11434 \
  -model qwen3-coder:480b-cloud \
  -patterns "*.go,*.ts,*.tsx,*.swift" \
  -exclude "node_modules,.git,vendor" \
  -focus "architecture,security,performance" \
  -max-files 50 \
  -chunk-size 10 \
  -output review.txt
```

### Parameters

- `-path`: Base directory to review (default: current directory)
- `-ollama-url`: Ollama server URL (default: `http://100.74.59.83:11434` - Mac Studio)
- `-model`: Model to use (default: `qwen3-coder:480b-cloud`)
- `-patterns`: File patterns to include (default: `*.go,*.ts,*.tsx,*.swift,*.js,*.jsx`)
- `-exclude`: Directories to exclude (default: `node_modules,.git,vendor,build,dist,.next`)
- `-focus`: Review focus areas (default: `architecture,security,performance,best-practices`)
- `-max-files`: Maximum files to review (default: 50)
- `-chunk-size`: Files per review chunk (default: 10)
- `-output`: Output file path (default: stdout)

## Examples

### Review Go files only
```bash
go run scripts/review_codebase_ollama.go \
  -patterns "*.go" \
  -max-files 30
```

### Review specific directory
```bash
go run scripts/review_codebase_ollama.go \
  -path ./handlers \
  -patterns "*.go" \
  -output handlers_review.txt
```

### Focus on security
```bash
go run scripts/review_codebase_ollama.go \
  -focus "security,vulnerabilities,authentication" \
  -output security_review.txt
```

### Review iOS app
```bash
go run scripts/review_codebase_ollama.go \
  -path ./ios_agentic_app \
  -patterns "*.swift" \
  -exclude ".build,node_modules" \
  -output ios_review.txt
```

## How It Works

1. **File Collection**: Walks the directory tree, collecting files matching the patterns
2. **Chunking**: Groups files into chunks (default: 10 files per chunk)
3. **Review**: Sends each chunk to Ollama with a comprehensive review prompt
4. **Summary**: Generates a final executive summary of all reviews

## Review Focus Areas

The review covers:
- ✅ Code quality and best practices
- ✅ Potential bugs or issues
- ✅ Security concerns
- ✅ Performance optimizations
- ✅ Architecture and design patterns
- ✅ Suggestions for improvement

## Output Format

The output includes:
1. Individual file reviews (grouped by chunk)
2. Overall assessment per chunk
3. Final executive summary with:
   - Overall codebase health
   - Key strengths
   - Critical issues
   - Priority recommendations
   - Architecture assessment

## Integration with Server

The `handlers/ollama.go` provides a Go handler for integrating Ollama into the MCP server:

```go
ollamaHandler := handlers.NewOllamaHandler(ollamaURL, modelName)
response, err := ollamaHandler.Generate(prompt, systemPrompt)
```

## Troubleshooting

### Ollama Connection Issues
```bash
# Test Ollama connection
./scripts/validate_ollama_direct.sh
```

### Large Codebases
- Reduce `-max-files` to review fewer files
- Increase `-chunk-size` to review more files per request
- Use `-path` to review specific directories

### Timeout Issues
- The script uses a 120-second timeout per request
- For very large chunks, reduce `-chunk-size`
- Cloud models may take longer - be patient

## Notes

- **Ollama doesn't have native tools** - this script provides the tooling layer
- The cloud model (`qwen3-coder:480b-cloud`) requires internet access
- Reviews are comprehensive but may take time for large codebases
- Results are saved incrementally - you can stop and resume

## Next Steps

1. Run a small test review first:
   ```bash
   go run scripts/review_codebase_ollama.go -max-files 5 -chunk-size 2
   ```

2. Review specific areas:
   ```bash
   go run scripts/review_codebase_ollama.go -path ./handlers -output handlers_review.txt
   ```

3. Full codebase review:
   ```bash
   go run scripts/review_codebase_ollama.go -max-files 100 -output full_review.txt
   ```
