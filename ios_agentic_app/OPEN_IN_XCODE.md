# Opening Swift Package in Xcode

## Quick Start

### Option 1: Open Package Directly (Recommended)

```bash
cd /Users/damian/Projects/productivity-mcp-server/ios_agentic_app
open Package.swift
```

Xcode will open the Swift Package. However, this is a **library package**, not an app. You need to create an app target.

### Option 2: Create Xcode App Project

1. **Open Xcode**
2. **File > New > Project**
3. Choose **"iOS" > "App"**
4. Configure:
   - **Product Name:** `ProductivityAgenticApp`
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Bundle Identifier:** `com.productivity.agentic`
   - **Storage:** None (we'll use the package)
5. **Save** to a new directory (e.g., `ios_agentic_app/XcodeProject`)

6. **Add Package Dependency:**
   - Select your app target
   - Go to **"Package Dependencies"** tab
   - Click **"+"** button
   - Choose **"Add Local..."**
   - Navigate to: `/Users/damian/Projects/productivity-mcp-server/ios_agentic_app`
   - Select `Package.swift`
   - Click **"Add Package"**

7. **Link the Library:**
   - Select your app target
   - Go to **"General"** tab
   - Under **"Frameworks, Libraries, and Embedded Content"**
   - Click **"+"**
   - Add: `ProductivityAgenticApp`

8. **Update App Entry Point:**
   - Replace the default `App.swift` with:
   ```swift
   import SwiftUI
   import ProductivityAgenticApp
   
   @main
   struct App: SwiftUI.App {
       var body: some Scene {
           WindowGroup {
               ContentView()
           }
       }
   }
   ```

9. **Import Views:**
   - The package contains `ContentView` in `Sources/UI/ContentView.swift`
   - Make sure it's public or create a wrapper

### Option 3: Convert Package to App (Advanced)

Create a new file `Sources/App.swift`:

```swift
import SwiftUI

@main
struct ProductivityAgenticApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

Then update `Package.swift` to include an executable:

```swift
products: [
    .executable(name: "ProductivityAgenticApp", targets: ["App"]),
    .library(name: "ProductivityAgenticApp", targets: ["ProductivityAgenticApp"])
],
targets: [
    .executableTarget(
        name: "App",
        dependencies: ["ProductivityAgenticApp"],
        path: "Sources/App"
    ),
    // ... existing targets
]
```

## Current Package Structure

```
ios_agentic_app/
├── Package.swift              ✅ Valid Swift Package
├── Sources/
│   ├── AppMain.swift         ✅ Has @main entry point
│   ├── AgentCore/            ✅ Core agent types
│   ├── Reasoning/            ✅ Reasoning engine
│   ├── Knowledge/            ✅ Knowledge management
│   ├── Tools/                ✅ Agent tools
│   └── UI/                   ✅ SwiftUI views
└── Tests/                    ✅ Test files
```

## Verification

### Check Package is Valid

```bash
cd ios_agentic_app
swift package describe
```

Should show:
- Package name: `ProductivityAgenticApp`
- Platforms: iOS 17.0+
- Targets: `ProductivityAgenticApp`, `ProductivityAgenticAppTests`

### Build Package

```bash
swift build
```

Should compile without errors.

### Run Tests

```bash
swift test
```

## Common Issues

### 1. "No such module 'ProductivityAgenticApp'"

**Solution:** Make sure you've added the package as a dependency and linked it in your app target.

### 2. "Cannot find 'ContentView' in scope"

**Solution:** 
- Check that `ContentView.swift` is in the package
- Make sure it's marked as `public` if importing from app
- Or create the view in your app target

### 3. "Package requires iOS 17.0"

**Solution:** 
- Update your app's deployment target to iOS 17.0+
- Or update `Package.swift` to support lower iOS versions

### 4. MLX Dependency Issues

**Solution:**
- MLX is currently commented out in `Package.swift`
- Uncomment if you want to use MLX features
- Or leave commented if not using MLX

## Recommended Approach

**For Development:**
1. Use Option 2 (Create Xcode App Project)
2. Link the Swift Package as dependency
3. This gives you full Xcode features (debugging, Interface Builder, etc.)

**For Production:**
- Consider creating an executable target in the package
- Or use the Xcode project approach

## Next Steps After Opening

1. ✅ Build the project (Cmd+B)
2. ✅ Fix any compilation errors
3. ✅ Run on simulator (Cmd+R)
4. ✅ Test on device
5. ✅ Verify all features work

## Build Commands

```bash
# Build package
swift build

# Run tests
swift test

# Generate Xcode project (if needed)
swift package generate-xcodeproj
# Note: This is deprecated in newer Swift versions
```
