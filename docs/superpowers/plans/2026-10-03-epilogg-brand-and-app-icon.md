# EpiLogg Brand and App Icon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce and integrate the approved C2 “Bokmerket” identity as a production-quality EpiLogg app icon and reusable wordmark.

**Architecture:** Keep editable brand source files outside the app target and generated runtime assets inside one Xcode asset catalog. A deterministic macOS rendering script converts reviewed SVG sources into opaque 1024-pixel PNG files, while a validator checks dimensions, alpha, and required variants before Xcode compiles them.

**Tech Stack:** SVG, Swift/AppKit rendering tools, Xcode asset catalogs, SwiftUI, `xcodebuild`

**Spec:** `docs/superpowers/specs/2026-10-03-testflight-launch-design.md`

## Global Constraints

- Product name is exactly `EpiLogg`.
- Identity is C2 “Bokmerket”: dark blue-green background, open book, warm peach bookmark.
- Do not add medical crosses, brain illustrations, monitoring waveforms, alarms, or text inside the app icon.
- Produce standard, dark, and tinted appearances plus a flattened 1024 by 1024 marketing icon.
- Keep the deployment target at iOS 17.
- Do not initialize Git automatically.

---

### Task 1: Create deterministic brand source and icon validation

**Files:**
- Create: `Brand/Source/EpiLogg-Mark-Standard.svg`
- Create: `Brand/Source/EpiLogg-Mark-Dark.svg`
- Create: `Brand/Source/EpiLogg-Mark-Tinted.svg`
- Create: `Brand/Source/EpiLogg-Wordmark.svg`
- Create: `Tools/render_app_icons.swift`
- Create: `Tools/validate_app_icons.swift`
- Create: `Brand/README.md`
- Generate: `Brand/Exports/EpiLogg-AppIcon-Standard-1024.png`
- Generate: `Brand/Exports/EpiLogg-AppIcon-Dark-1024.png`
- Generate: `Brand/Exports/EpiLogg-AppIcon-Tinted-1024.png`
- Generate: `Brand/Exports/EpiLogg-Wordmark.svg`

**Interfaces:**
- Consumes: approved C2 geometry and colors from the launch spec.
- Produces: three opaque 1024 by 1024 PNG files and one SVG wordmark for Task 2.

- [ ] **Step 1: Write the failing icon validator**

Create `Tools/validate_app_icons.swift` so it checks the literal required paths:

```swift
import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let names = [
    "EpiLogg-AppIcon-Standard-1024.png",
    "EpiLogg-AppIcon-Dark-1024.png",
    "EpiLogg-AppIcon-Tinted-1024.png"
]

var failures: [String] = []
for name in names {
    let url = root.appendingPathComponent("Brand/Exports/\(name)")
    guard let image = NSImage(contentsOf: url),
          let representation = image.representations.first as? NSBitmapImageRep else {
        failures.append("\(name): missing or unreadable")
        continue
    }
    if representation.pixelsWide != 1024 || representation.pixelsHigh != 1024 {
        failures.append("\(name): expected 1024x1024")
    }
    if representation.hasAlpha {
        failures.append("\(name): icon must be opaque")
    }
}

if failures.isEmpty {
    print("Validated 3 opaque 1024x1024 app icons")
} else {
    failures.forEach { fputs("\($0)\n", stderr) }
    exit(1)
}
```

- [ ] **Step 2: Run the validator and confirm the source assets are missing**

Run:

```bash
swift Tools/validate_app_icons.swift
```

Expected: exit 1 with three `missing or unreadable` messages.

- [ ] **Step 3: Draw the approved vector sources**

Use a 1024 by 1024 SVG view box. The standard mark must use these production values:

```xml
<linearGradient id="background" x1="128" y1="80" x2="896" y2="960">
  <stop stop-color="#2F5361"/>
  <stop offset="1" stop-color="#182F3A"/>
</linearGradient>
```

Use:

- left page `#FFFFFF`;
- right page `#E5F0EC`;
- bookmark `#F3CBB5`;
- page details `#4A8077`.

Keep all geometry inside a 120-pixel safe margin. The SVG canvas background must cover every pixel. Dark and tinted sources preserve the approved silhouette while using the colors shown in the approved visual companion. The wordmark contains the symbol and text `EpiLogg` but no medical tagline.

- [ ] **Step 4: Implement opaque SVG-to-PNG rendering**

Create `Tools/render_app_icons.swift` with AppKit. It must load each SVG with `NSImage`, draw into a 1024 by 1024 `NSBitmapImageRep` created with `hasAlpha: false`, and write PNG output to the exact three `Brand/Exports` paths. Fail with a nonzero exit for a missing source, failed draw, or failed PNG encoding.

- [ ] **Step 5: Generate and validate all exports**

Run:

```bash
swift Tools/render_app_icons.swift
swift Tools/validate_app_icons.swift
```

Expected: `Validated 3 opaque 1024x1024 app icons`.

- [ ] **Step 6: Add brand usage documentation**

Document in `Brand/README.md`:

- approved colors;
- icon safe area of 120 pixels;
- no extra rounded-corner mask in source files;
- minimum standalone mark size of 32 pixels;
- no stretching, recoloring, rotation, outline effects, or medical additions;
- standard, dark, and tinted source-to-export mapping.

- [ ] **Step 7: Record the task checkpoint**

Save validator output to the session artifact directory. If Git has been initialized separately, commit with:

```text
feat: add EpiLogg brand source assets
```

### Task 2: Integrate app icons into Xcode

**Files:**
- Create: `EpiLogg/Assets.xcassets/Contents.json`
- Create: `EpiLogg/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Copy: `EpiLogg/Assets.xcassets/AppIcon.appiconset/AppIcon-Standard-1024.png`
- Copy: `EpiLogg/Assets.xcassets/AppIcon.appiconset/AppIcon-Dark-1024.png`
- Copy: `EpiLogg/Assets.xcassets/AppIcon.appiconset/AppIcon-Tinted-1024.png`
- Modify: `EpiLogg.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: validated PNG exports from Task 1.
- Produces: an Xcode `AppIcon` asset set selected by the EpiLogg target.

- [ ] **Step 1: Write an asset-catalog contract check**

Create `Tools/validate_app_icon_catalog.swift` that decodes `Contents.json` and asserts:

- exactly three image entries;
- each image uses `idiom: "universal"`, `platform: "ios"`, and `size: "1024x1024"`;
- standard has no appearance field;
- dark has luminosity value `dark`;
- tinted has luminosity value `tinted`;
- every referenced filename exists.

- [ ] **Step 2: Run the catalog check and verify it fails**

Run:

```bash
swift Tools/validate_app_icon_catalog.swift
```

Expected: exit 1 because `EpiLogg/Assets.xcassets/AppIcon.appiconset/Contents.json` does not exist.

- [ ] **Step 3: Create the app icon set**

Use this `images` structure in the app icon `Contents.json`:

```json
[
  {
    "filename": "AppIcon-Standard-1024.png",
    "idiom": "universal",
    "platform": "ios",
    "size": "1024x1024"
  },
  {
    "appearances": [{ "appearance": "luminosity", "value": "dark" }],
    "filename": "AppIcon-Dark-1024.png",
    "idiom": "universal",
    "platform": "ios",
    "size": "1024x1024"
  },
  {
    "appearances": [{ "appearance": "luminosity", "value": "tinted" }],
    "filename": "AppIcon-Tinted-1024.png",
    "idiom": "universal",
    "platform": "ios",
    "size": "1024x1024"
  }
]
```

Set `info.author` to `xcode` and `info.version` to `1`.

- [ ] **Step 4: Select the icon set in both app configurations**

Set:

```text
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
```

for Debug and Release app-target build settings. Do not add it to unit or UI test targets.

- [ ] **Step 5: Validate the catalog and compile assets**

Run:

```bash
swift Tools/validate_app_icon_catalog.swift
xcodebuild build \
  -project EpiLogg.xcodeproj \
  -scheme EpiLogg \
  -configuration Release \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

Expected: both commands exit 0 with no missing app icon warning.

- [ ] **Step 6: Verify rendered appearances**

Install the simulator build and inspect:

- standard home-screen icon;
- dark home-screen appearance;
- tinted home-screen appearance;
- Settings icon;
- Spotlight icon.

Capture one screenshot for each appearance in the session artifact directory. Reject clipping, muddy page separation, illegible bookmark, or a second rounded-corner border.

- [ ] **Step 7: Record the task checkpoint**

If Git has been initialized separately, commit with:

```text
feat: integrate production app icon
```

### Task 3: Run brand acceptance checks

**Files:**
- Modify only if a defect is found: files created in Tasks 1 and 2.

**Interfaces:**
- Consumes: compiled AppIcon asset set.
- Produces: approved, reusable brand package for TestFlight and store material.

- [ ] **Step 1: Compare icon output at required sizes**

Render or inspect the standard icon at 32, 48, 60, 120, 180, and 1024 pixels. Verify the book remains identifiable and the bookmark remains visible at every size.

- [ ] **Step 2: Check color and accessibility behavior**

Verify standard, dark, and tinted variants against light and dark wallpapers. The book boundary must remain visible without relying only on the peach bookmark.

- [ ] **Step 3: Re-run all brand and build checks**

Run:

```bash
swift Tools/validate_app_icons.swift
swift Tools/validate_app_icon_catalog.swift
xcodebuild build \
  -project EpiLogg.xcodeproj \
  -scheme EpiLogg \
  -configuration Release \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

Expected: all commands exit 0.

- [ ] **Step 4: Obtain owner approval on the production output**

Present the actual generated standard, dark, and tinted files, not the brainstorming mockups. Do not continue to archive upload until the owner accepts the production render.

- [ ] **Step 5: Record the task checkpoint**

If Git has been initialized separately, commit any acceptance fixes with:

```text
fix: refine EpiLogg app icon output
```

