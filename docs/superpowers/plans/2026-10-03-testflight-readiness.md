# EpiLogg TestFlight Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a signed, validated EpiLogg 1.0.0 build with the approved Bokmerket identity, public privacy/support resources, complete TestFlight metadata, and a verified external TestFlight beta.

**Architecture:** Keep the iOS app local-first and dependency-free. Add generated brand assets and compile them through the existing Xcode target, expose immutable public URLs through a small `AppLinks` type, host privacy/support content as a separate static site, and keep App Store Connect actions as explicit manual gates with saved evidence. The plan ends at a completed external TestFlight round; App Store submission remains a separate approved phase.

**Tech Stack:** SwiftUI, SwiftData, XCTest/XCUITest, Xcode 27 stable with iOS 26 SDK or later, Swift/AppKit asset-generation script, static HTML/CSS hosted by Vercel on a `haugentech.no` subdomain, App Store Connect/TestFlight.

**Spec:** `docs/superpowers/specs/2026-10-03-testflight-app-store-launch-design.md`

## Global Constraints

- Product name is exactly `EpiLogg`.
- Visual identity is exactly **C2 – Bokmerket**: dark blue-green background, open light book, peach bookmark, restrained green page lines.
- Marketing version is `1.0.0`; first uploaded build number is `1`; every replacement upload increments the build number.
- Bundle identifier remains `no.epilogg.app`; Apple Developer team remains `HRQ5WGW63F`.
- Minimum deployment target remains iOS 17; archive with a stable Xcode release and iOS 26 SDK or later.
- Target remains iPhone-only (`TARGETED_DEVICE_FAMILY = 1`).
- No account, backend, analytics, advertising, crash-reporting SDK, cloud synchronization, or third-party runtime dependency.
- Health/profile data remains on device and is never sent to the developer.
- Public URLs are exactly `https://epilogg.haugentech.no/personvern` and `https://epilogg.haugentech.no/support`.
- Support address is exactly `epilogg@haugentech.no`.
- App copy must not claim diagnosis, treatment, seizure detection, emergency notification, or medical advice.
- Use fictitious health information in all testing and distribution material.
- External TestFlight precedes App Store submission; App Store publication is out of scope for this plan.

## File Structure

### New files

- `Brand/EpiLoggLogo.svg` — editable vector wordmark and symbol reference.
- `Brand/AppIcon.icon/` — Icon Composer source package saved by Icon Composer.
- `Scripts/generate_brand_assets.swift` — deterministic flattened PNG renderer for catalog and marketing assets.
- `Scripts/validate_distribution.py` — checks PNG dimensions/alpha, required public copy, metadata limits, version/build settings, and privacy manifest declarations.
- `EpiLogg/Assets.xcassets/Contents.json` — root asset catalog.
- `EpiLogg/Assets.xcassets/AppIcon.appiconset/Contents.json` — iOS app-icon appearances.
- `EpiLogg/Assets.xcassets/AppIcon.appiconset/AppIcon.png` — standard 1024 × 1024 icon.
- `EpiLogg/Assets.xcassets/AppIcon.appiconset/AppIcon-Dark.png` — dark appearance.
- `EpiLogg/Assets.xcassets/AppIcon.appiconset/AppIcon-Tinted.png` — tinted appearance.
- `Distribution/Marketing/EpiLogg-AppIcon-1024.png` — flattened marketing icon.
- `EpiLogg/Domain/AppLinks.swift` — canonical public URLs and support email.
- `Site/index.html` — small landing page linking to support and privacy.
- `Site/personvern/index.html` — Norwegian privacy policy.
- `Site/support/index.html` — Norwegian support page.
- `Site/styles.css` — shared accessible site styles.
- `Site/vercel.json` — Vercel routing and security-header configuration.
- `Distribution/TestFlight/nb-NO/beta-description.txt` — external beta description.
- `Distribution/TestFlight/nb-NO/what-to-test.txt` — tester instructions.
- `Distribution/TestFlight/nb-NO/review-notes.md` — Beta App Review walkthrough.
- `Distribution/AppPrivacy.md` — exact App Privacy answers and re-evaluation triggers.
- `Distribution/ReleaseChecklist.md` — manual release evidence checklist.
- `Distribution/ExportOptions.plist` — App Store Connect export settings.
- `EpiLoggTests/AppLinksTests.swift` — URL/email contract tests.

### Modified files

- `EpiLogg/Features/Profile/ProfileView.swift` — accessible support/privacy links and version display.
- `EpiLoggUITests/EpiLoggUITests.swift` — regression coverage for legal links and unchanged local-data actions.
- `EpiLogg.xcodeproj/project.pbxproj` — app-icon catalog name and 1.0.0 release version.
- `README.md` — release asset generation, validation, and TestFlight preparation commands.

### Files deliberately not modified

- SwiftData models and persistence code.
- App privacy behavior and network capabilities.
- Seizure/onboarding/dashboard flows.

---

### Task 1: Configure the Public Subdomain and Support Channel

**Files:**
- No repository files in this task.
- Record evidence in the current session, not in source control.

**Interfaces:**
- Produces: active `epilogg.haugentech.no` subdomain, working `epilogg@haugentech.no` mailbox, and a Vercel project that publishes only `Site/`.
- Consumes: none.

- [ ] **Step 1: Confirm control of the parent domain**

Confirm that the product owner controls DNS for `haugentech.no` and can create the exact subdomain `epilogg.haugentech.no`.

Expected:
- DNS access is available;
- the parent domain remains active and renewed;
- no DNS-provider credentials or tokens are committed to the repository.

- [ ] **Step 2: Create the support mailbox**

Create `epilogg@haugentech.no`, enable MFA for the mailbox administrator, and send a message to it from an unrelated address.

Reply from `epilogg@haugentech.no`.

Expected:
- inbound and outbound delivery both succeed;
- sender name is `EpiLogg support`;
- no forwarding rule exposes health information to an unapproved third party.

- [ ] **Step 3: Create the Vercel project**

Create a Vercel project for the static site. Connect it to a repository that contains only public site content, or deploy only the `Site/` directory. Do not expose the private application source.

Expected:
- only the contents of `Site/` will be published;
- the Vercel project root is `Site/`;
- framework preset is `Other`, with no build command required;
- production branch is `main`;
- no analytics, audience insights or third-party integrations are enabled.

- [ ] **Step 4: Configure the custom subdomain**

Add `epilogg.haugentech.no` as the production domain in Vercel. Create the CNAME record requested by Vercel at the DNS provider for `haugentech.no`.

Run after propagation:

```bash
curl -I https://epilogg.haugentech.no
```

Expected before site content exists: a valid TLS response from Vercel; `curl` must not report a certificate-name mismatch.

- [ ] **Step 5: Record the manual gate**

In the session checklist, record:

```text
Domain: epilogg.haugentech.no
Support: epilogg@haugentech.no inbound/outbound verified
Hosting: Vercel project with Site/ as project root
HTTPS: valid
```

Do not commit DNS-provider receipts, account identifiers, Vercel tokens, or mailbox credentials.

---

### Task 2: Generate and Integrate the Bokmerket App Icon

**Files:**
- Create: `Brand/EpiLoggLogo.svg`
- Create: `Brand/AppIcon.icon/`
- Create: `Scripts/generate_brand_assets.swift`
- Create: `Scripts/validate_distribution.py`
- Create: `EpiLogg/Assets.xcassets/Contents.json`
- Create: `EpiLogg/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Generate: `EpiLogg/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
- Generate: `EpiLogg/Assets.xcassets/AppIcon.appiconset/AppIcon-Dark.png`
- Generate: `EpiLogg/Assets.xcassets/AppIcon.appiconset/AppIcon-Tinted.png`
- Generate: `Distribution/Marketing/EpiLogg-AppIcon-1024.png`
- Modify: `EpiLogg.xcodeproj/project.pbxproj`
- Modify: `README.md`

**Interfaces:**
- Produces: `python3 Scripts/validate_distribution.py --brand` and compiled asset name `AppIcon`.
- Consumes: approved C2 colors and geometry from the launch spec.

- [ ] **Step 1: Write the failing brand validation**

Create the brand portion of `Scripts/validate_distribution.py`:

```python
#!/usr/bin/env python3
import argparse
import json
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ICON_DIR = ROOT / "EpiLogg/Assets.xcassets/AppIcon.appiconset"
EXPECTED = {
    "AppIcon.png",
    "AppIcon-Dark.png",
    "AppIcon-Tinted.png",
}

def png_info(path: Path) -> tuple[int, int, int]:
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise AssertionError(f"{path} is not a PNG")
    width, height, bit_depth, color_type = struct.unpack(">IIBB", data[16:26])
    return width, height, color_type

def validate_brand() -> None:
    catalog = json.loads((ICON_DIR / "Contents.json").read_text())
    filenames = {image.get("filename") for image in catalog["images"]}
    assert EXPECTED <= filenames, f"missing icon appearances: {EXPECTED - filenames}"
    for name in EXPECTED:
        width, height, color_type = png_info(ICON_DIR / name)
        assert (width, height) == (1024, 1024), f"{name} is {width}x{height}"
        assert color_type == 2, f"{name} must be RGB without alpha; PNG color type={color_type}"
    marketing = ROOT / "Distribution/Marketing/EpiLogg-AppIcon-1024.png"
    assert png_info(marketing)[:2] == (1024, 1024)
    assert (ROOT / "Brand/EpiLoggLogo.svg").exists()
    assert (ROOT / "Brand/AppIcon.icon").exists()

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--brand", action="store_true")
    args = parser.parse_args()
    if args.brand:
        validate_brand()
    else:
        parser.error("select a validation group")
```

- [ ] **Step 2: Run the validator to verify RED**

Run:

```bash
python3 Scripts/validate_distribution.py --brand
```

Expected: FAIL because `EpiLogg/Assets.xcassets/AppIcon.appiconset/Contents.json` does not exist.

- [ ] **Step 3: Create the deterministic renderer**

Create `Scripts/generate_brand_assets.swift` using AppKit/CoreGraphics. Use these exact production colors:

```swift
import AppKit

struct Palette {
    let backgroundTop: NSColor
    let backgroundBottom: NSColor
    let leftPage: NSColor
    let rightPage: NSColor
    let bookmark: NSColor
    let pageLine: NSColor
}

let standard = Palette(
    backgroundTop: NSColor(calibratedRed: 47/255, green: 83/255, blue: 97/255, alpha: 1),
    backgroundBottom: NSColor(calibratedRed: 24/255, green: 47/255, blue: 58/255, alpha: 1),
    leftPage: .white,
    rightPage: NSColor(calibratedRed: 229/255, green: 240/255, blue: 236/255, alpha: 1),
    bookmark: NSColor(calibratedRed: 243/255, green: 203/255, blue: 181/255, alpha: 1),
    pageLine: NSColor(calibratedRed: 74/255, green: 128/255, blue: 119/255, alpha: 1)
)
```

Render a full-bleed 1024 × 1024 square with no transparent pixels and no pre-rounded outer corners. Scale the approved book paths from the 168-unit concept:

```swift
let leftPage = "M44 44 C60 40 73 46 84 55 V124 C73 114 60 111 44 115 Z"
let rightPage = "M124 44 C108 40 95 46 84 55 V124 C95 114 108 111 124 115 Z"
let bookmark = "M101 43 V82 L111 75 L121 82 V44 C114 42 107 42 101 43 Z"
```

Implement a small parser for `M`, `L`, `C`, `V`, and `Z`, or replace these strings with equivalent `NSBezierPath` calls. Draw the standard, dark, and tinted palettes and write non-alpha RGB PNGs to the four generated destinations.

The marketing PNG is an exact copy of the standard flattened icon.

- [ ] **Step 4: Add the asset catalog manifests**

Create `EpiLogg/Assets.xcassets/Contents.json`:

```json
{
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

Create `EpiLogg/Assets.xcassets/AppIcon.appiconset/Contents.json`:

```json
{
  "images": [
    {
      "filename": "AppIcon.png",
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024"
    },
    {
      "appearances": [
        {
          "appearance": "luminosity",
          "value": "dark"
        }
      ],
      "filename": "AppIcon-Dark.png",
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024"
    },
    {
      "appearances": [
        {
          "appearance": "luminosity",
          "value": "tinted"
        }
      ],
      "filename": "AppIcon-Tinted.png",
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

- [ ] **Step 5: Create the editable vector wordmark**

Create `Brand/EpiLoggLogo.svg` with:

- a square symbol view box containing the same full-bleed background and book paths;
- a separate horizontal lockup artboard containing the symbol plus `EpiLogg`;
- no medical cross, heartbeat line, alarm, or brain imagery;
- no text baked into the app-icon artboard.

Use system-safe fallback fonts in the SVG (`-apple-system`, `SF Pro Rounded`, `Arial Rounded MT Bold`) and convert text to outlines before external marketing delivery.

- [ ] **Step 6: Save the Icon Composer source**

In Apple Icon Composer:

1. Create a new iPhone icon.
2. Import separate full-canvas background, left-page, right-page, bookmark, and page-line layers from the vector source.
3. Configure standard, dark, and tinted appearances to match the flattened files.
4. Preview at 32, 48, and 60 points.
5. Save as `Brand/AppIcon.icon`.

Expected: the book remains legible at 32 points and the bookmark does not merge into the right page.

- [ ] **Step 7: Generate the PNG assets**

Run:

```bash
swift Scripts/generate_brand_assets.swift
```

Expected: four RGB PNG files are written without warnings.

- [ ] **Step 8: Wire the compiled icon name**

In both Debug and Release app-target build settings in `EpiLogg.xcodeproj/project.pbxproj`, add:

```text
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
```

Do not add this setting to unit-test or UI-test targets.

- [ ] **Step 9: Run the brand validator to verify GREEN**

Run:

```bash
python3 Scripts/validate_distribution.py --brand
```

Expected: exit 0 with no output.

- [ ] **Step 10: Build and inspect the compiled app**

Run:

```bash
xcodebuild build \
  -project EpiLogg.xcodeproj \
  -scheme EpiLogg \
  -configuration Release \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath .build/TestFlightBrand \
  CODE_SIGNING_ALLOWED=NO
```

Expected: `** BUILD SUCCEEDED **` and no missing app-icon warning.

Install on the existing iPhone simulator and inspect standard, dark, and tinted appearances at normal home-screen size.

- [ ] **Step 11: Document regeneration**

Add to `README.md`:

```bash
swift Scripts/generate_brand_assets.swift
python3 Scripts/validate_distribution.py --brand
```

Explain that `Brand/AppIcon.icon` is the editable Icon Composer source and generated PNGs must not be edited independently.

- [ ] **Step 12: Commit**

```bash
git add Brand Scripts EpiLogg/Assets.xcassets Distribution/Marketing EpiLogg.xcodeproj/project.pbxproj README.md
git commit -m "feat: add EpiLogg brand assets"
```

---

### Task 3: Publish Privacy and Support Content

**Files:**
- Create: `Site/index.html`
- Create: `Site/personvern/index.html`
- Create: `Site/support/index.html`
- Create: `Site/styles.css`
- Create: `Site/vercel.json`
- Modify: `Scripts/validate_distribution.py`
- Create: `Distribution/AppPrivacy.md`

**Interfaces:**
- Produces: live `https://epilogg.haugentech.no/personvern`, live `https://epilogg.haugentech.no/support`, and `python3 Scripts/validate_distribution.py --site`.
- Consumes: verified domain and mailbox from Task 1.

- [ ] **Step 1: Add failing static-site validation**

Extend `Scripts/validate_distribution.py`:

```python
PUBLIC_BASE_URL = "https://epilogg.haugentech.no"
SUPPORT_EMAIL = "epilogg@haugentech.no"
REQUIRED_SITE_TEXT = {
    "Site/index.html": [
        "EpiLogg",
        f"{PUBLIC_BASE_URL}/personvern",
        f"{PUBLIC_BASE_URL}/support",
    ],
    "Site/personvern/index.html": [
        SUPPORT_EMAIL,
        "lagres lokalt",
        "Apple-sikkerhetskopi",
        "JSON",
        "slette",
        "3. oktober 2026",
    ],
    "Site/support/index.html": [
        SUPPORT_EMAIL,
        "medisinske råd",
        "nødtjenester",
        f"{PUBLIC_BASE_URL}/personvern",
    ],
}

def validate_site() -> None:
    site_text = []
    for relative, phrases in REQUIRED_SITE_TEXT.items():
        text = (ROOT / relative).read_text()
        site_text.append(text)
        for phrase in phrases:
            assert phrase.casefold() in text.casefold(), f"{relative} missing {phrase!r}"

    assert (ROOT / "Site/styles.css").exists()
    vercel = json.loads((ROOT / "Site/vercel.json").read_text())
    assert vercel.get("cleanUrls") is True
    assert vercel.get("trailingSlash") is False

    combined_html = "\n".join(site_text).casefold()
    assert "<script" not in combined_html
    assert "support@epilogg.no" not in combined_html
    assert "https://epilogg.no" not in combined_html
```

Add `--site` to the argument parser and call `validate_site()`.

- [ ] **Step 2: Run site validation to verify RED**

Run:

```bash
python3 Scripts/validate_distribution.py --site
```

Expected: FAIL because `Site/personvern/index.html` does not exist.

- [ ] **Step 3: Write the shared accessible styling**

Create `Site/styles.css` with:

- WCAG AA color contrast using app colors;
- maximum text width of 72 characters;
- visible keyboard focus;
- responsive layout down to 320 CSS pixels;
- no remote fonts, trackers, scripts, cookies, or CDN assets;
- `prefers-reduced-motion` respected by using no required animation.

- [ ] **Step 4: Write the privacy policy**

Create `Site/personvern/index.html` in Norwegian with these sections:

1. `Personvernerklæring for EpiLogg`
2. `Opplysninger du legger inn`
3. `Lokal lagring og Apple-sikkerhetskopi`
4. `Eksport`
5. `Sletting`
6. `Supporthenvendelser`
7. `Endringer i erklæringen`
8. `Kontakt`

State explicitly:

```text
EpiLogg sender ikke profil-, medisin-, steds- eller anfallsopplysninger til utvikleren eller tredjeparter. Opplysningene lagres lokalt på enheten.
```

Explain that an exported JSON file is controlled by the user after export and is not encrypted by EpiLogg.

Use `3. oktober 2026` as the initial update date and `epilogg@haugentech.no` as contact.

- [ ] **Step 5: Write the support page**

Create `Site/support/index.html` in Norwegian with:

- onboarding, logging, editing, export, and delete-all instructions;
- `mailto:epilogg@haugentech.no`;
- statement that support email must not contain sensitive health information;
- statement that EpiLogg does not give medical advice or monitor emergencies;
- instruction to contact local emergency services for an acute emergency;
- link to `/personvern`.

- [ ] **Step 6: Write the landing page**

Create `Site/index.html` with the approved wordmark, one paragraph describing a local personal seizure diary, and links to `/support` and `/personvern`. Do not add download badges before an App Store listing exists.

- [ ] **Step 7: Configure Vercel routing and security headers**

Create `Site/vercel.json` with clean URLs, no trailing slash, and site-wide headers for Content Security Policy, Referrer Policy and `X-Content-Type-Options`. The CSP must disallow scripts, forms and framing.

- [ ] **Step 8: Document App Privacy answers**

Create `Distribution/AppPrivacy.md`:

```markdown
# App Privacy for EpiLogg 1.0.0

- Does this app collect data? **No**
- Tracking: **No**
- Tracking domains: **None**
- Third-party SDKs: **None**

Apple defines collection as transmitting data off device so the developer or a third party can access it beyond servicing a real-time request. EpiLogg does not transmit app data.

Re-evaluate before every release if analytics, crash reporting, cloud sync, support SDKs, advertising, accounts, or any network upload is added.
```

- [ ] **Step 9: Run site validation to verify GREEN**

Run:

```bash
python3 Scripts/validate_distribution.py --site
```

Expected: exit 0.

- [ ] **Step 10: Test locally**

Start the server with the Bash tool in attached async mode and record its exact PID:

```bash
python3 -m http.server 8080 --directory Site
```

Then run:

```bash
curl -fsS http://127.0.0.1:8080/personvern/ | grep -F "epilogg@haugentech.no"
curl -fsS http://127.0.0.1:8080/support/ | grep -F "/personvern"
```

Expected: both commands print a matching line. Stop the HTTP server with `kill <recorded-pid>`; do not use `pkill` or `killall`.

- [ ] **Step 11: Publish the static site to Vercel**

Publish only `Site/` through the dedicated Vercel project. Set the project root to `Site/`, add `epilogg.haugentech.no` as the production domain, and create the DNS record requested by Vercel. Do not expose the private app source or add credentials to source control.

Verify:

```bash
curl -fsS https://epilogg.haugentech.no/personvern | grep -F "epilogg@haugentech.no"
curl -fsS https://epilogg.haugentech.no/support | grep -F "medisinske råd"
```

Expected: both commands exit 0 over HTTPS.

- [ ] **Step 12: Commit application-repository sources**

```bash
git add Site Distribution/AppPrivacy.md Scripts/validate_distribution.py
git commit -m "docs: add privacy and support resources"
```

---

### Task 4: Add In-App Privacy, Support, and Version Links

**Files:**
- Create: `EpiLogg/Domain/AppLinks.swift`
- Create: `EpiLoggTests/AppLinksTests.swift`
- Modify: `EpiLogg/Features/Profile/ProfileView.swift`
- Modify: `EpiLoggUITests/EpiLoggUITests.swift`

**Interfaces:**
- Produces:
  - `AppLinks.privacyPolicy: URL`
  - `AppLinks.support: URL`
  - `AppLinks.supportEmail: String`
- Consumes: live URLs from Task 3.

- [ ] **Step 1: Write failing URL contract tests**

Create `EpiLoggTests/AppLinksTests.swift`:

```swift
import XCTest
@testable import EpiLogg

final class AppLinksTests: XCTestCase {
    func testPublicLinksUseApprovedSecureURLs() {
        XCTAssertEqual(AppLinks.privacyPolicy.absoluteString, "https://epilogg.haugentech.no/personvern")
        XCTAssertEqual(AppLinks.support.absoluteString, "https://epilogg.haugentech.no/support")
        XCTAssertEqual(AppLinks.supportEmail, "epilogg@haugentech.no")
        XCTAssertEqual(AppLinks.privacyPolicy.scheme, "https")
        XCTAssertEqual(AppLinks.support.scheme, "https")
    }
}
```

- [ ] **Step 2: Run unit test to verify RED**

Run:

```bash
xcodebuild test \
  -project EpiLogg.xcodeproj \
  -scheme EpiLogg \
  -destination 'platform=iOS Simulator,id=904B66BF-2A68-4297-9B9F-FC30C37065B1' \
  -derivedDataPath .build/TestFlightLinks \
  -only-testing:EpiLoggTests/AppLinksTests \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO
```

Expected: compile failure because `AppLinks` is not defined.

- [ ] **Step 3: Implement immutable links**

Create `EpiLogg/Domain/AppLinks.swift`:

```swift
import Foundation

enum AppLinks {
    static let privacyPolicy = URL(string: "https://epilogg.haugentech.no/personvern")!
    static let support = URL(string: "https://epilogg.haugentech.no/support")!
    static let supportEmail = "epilogg@haugentech.no"
}
```

- [ ] **Step 4: Run unit test to verify GREEN**

Run the command from Step 2.

Expected: `AppLinksTests` passes.

- [ ] **Step 5: Write the failing UI assertions**

In `testOnboardingLoggingEditingAndDeleting`, after opening Profil, add:

```swift
scrollTo(app.links["profile.privacyPolicy"], in: app)
XCTAssertTrue(app.links["profile.privacyPolicy"].exists)
XCTAssertTrue(app.links["profile.support"].exists)
XCTAssertTrue(app.staticTexts["profile.version"].exists)
```

Do not tap external links in the end-to-end data test; existence and accessible labeling are the app contract. URL values are covered by `AppLinksTests`.

- [ ] **Step 6: Run the UI test to verify RED**

Run:

```bash
xcodebuild test \
  -project EpiLogg.xcodeproj \
  -scheme EpiLogg \
  -destination 'platform=iOS Simulator,id=904B66BF-2A68-4297-9B9F-FC30C37065B1' \
  -derivedDataPath .build/TestFlightLinks \
  -only-testing:EpiLoggUITests/EpiLoggUITests/testOnboardingLoggingEditingAndDeleting \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO
```

Expected: FAIL because `profile.privacyPolicy` does not exist.

- [ ] **Step 7: Add links to the existing privacy card**

In `ProfileView.privacyCard`, after the backup explanation, add:

```swift
Divider()
Link(destination: AppLinks.privacyPolicy) {
    Label("Personvernerklæring", systemImage: "hand.raised")
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
}
.accessibilityIdentifier("profile.privacyPolicy")

Link(destination: AppLinks.support) {
    Label("Hjelp og kontakt", systemImage: "questionmark.circle")
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
}
.accessibilityIdentifier("profile.support")

Text("Versjon \(appVersion)")
    .font(.caption)
    .foregroundStyle(AppStyle.muted)
    .accessibilityIdentifier("profile.version")
```

Add this computed property to `ProfileView`:

```swift
private var appVersion: String {
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
    let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    return build.map { "\(version) (\($0))" } ?? version
}
```

- [ ] **Step 8: Run focused tests**

Run both selectors from Steps 2 and 6 in one `xcodebuild test` invocation.

Expected: URL unit test and profile UI assertions pass.

- [ ] **Step 9: Commit**

```bash
git add EpiLogg/Domain/AppLinks.swift EpiLoggTests/AppLinksTests.swift EpiLogg/Features/Profile/ProfileView.swift EpiLoggUITests/EpiLoggUITests.swift
git commit -m "feat: add privacy and support links"
```

---

### Task 5: Configure Versioning and Distribution Metadata

**Files:**
- Modify: `EpiLogg.xcodeproj/project.pbxproj`
- Create: `Distribution/TestFlight/nb-NO/beta-description.txt`
- Create: `Distribution/TestFlight/nb-NO/what-to-test.txt`
- Create: `Distribution/TestFlight/nb-NO/review-notes.md`
- Create: `Distribution/ExportOptions.plist`
- Create: `Distribution/ReleaseChecklist.md`
- Modify: `Scripts/validate_distribution.py`
- Modify: `README.md`

**Interfaces:**
- Produces: `python3 Scripts/validate_distribution.py --release`, version `1.0.0 (1)`, and copy ready for App Store Connect.
- Consumes: icon from Task 2 and public links from Tasks 3–4.

- [ ] **Step 1: Add failing release validation**

Extend `Scripts/validate_distribution.py`:

```python
LIMITS = {
    "Distribution/TestFlight/nb-NO/beta-description.txt": 4000,
    "Distribution/TestFlight/nb-NO/what-to-test.txt": 4000,
}

def validate_release() -> None:
    project = (ROOT / "EpiLogg.xcodeproj/project.pbxproj").read_text()
    assert project.count("MARKETING_VERSION = 1.0.0;") == 2
    assert project.count("CURRENT_PROJECT_VERSION = 1;") >= 2
    assert project.count("ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;") == 2
    for relative, limit in LIMITS.items():
        text = (ROOT / relative).read_text().strip()
        assert text, f"{relative} is empty"
        assert len(text) <= limit, f"{relative} exceeds {limit} characters"
    notes = (ROOT / "Distribution/TestFlight/nb-NO/review-notes.md").read_text()
    for phrase in ("Ingen innlogging", "fiktive", "Slett alle data"):
        assert phrase.casefold() in notes.casefold(), f"review notes missing {phrase!r}"
    privacy = (ROOT / "EpiLogg/PrivacyInfo.xcprivacy").read_text()
    assert "<false/>" in privacy
    assert "<key>NSPrivacyCollectedDataTypes</key><array/>" in privacy
```

Add `--release` to the parser.

- [ ] **Step 2: Run validator to verify RED**

Run:

```bash
python3 Scripts/validate_distribution.py --release
```

Expected: FAIL because the project still contains `MARKETING_VERSION = 0.1.0;`.

- [ ] **Step 3: Set release version**

In both Debug and Release app-target settings:

```text
MARKETING_VERSION = 1.0.0;
CURRENT_PROJECT_VERSION = 1;
```

Do not change test-target bundle identifiers or deployment target.

- [ ] **Step 4: Write TestFlight beta description**

Create `Distribution/TestFlight/nb-NO/beta-description.txt`:

```text
EpiLogg er en norsk, personlig anfallsdagbok for iPhone. Opplysninger om anfall, medisiner, mulige triggere og steder lagres lokalt på enheten. Appen krever ingen konto og gir ikke medisinske råd, diagnostikk eller anfallsvarsling.

Denne betaen brukes til å kontrollere registrering, historikk, beskrivende statistikk, eksport, sletting og tilgjengelighet før en eventuell App Store-lansering. Bruk bare fiktive opplysninger under testingen.
```

- [ ] **Step 5: Write what-to-test copy**

Create `Distribution/TestFlight/nb-NO/what-to-test.txt`:

```text
Bruk bare fiktive opplysninger.

Test gjerne:
• onboarding med og uten medisiner
• registrering, redigering og sletting av anfall
• egne triggere og lagrede steder
• 7, 30 og 90 dager samt egendefinert periode
• JSON-eksport og «Slett alle data»
• stor tekst og VoiceOver
• at data beholdes etter oppdatering til neste betabygg

EpiLogg oppdager ikke anfall, varsler ikke andre og gir ikke medisinske råd. Send tekniske tilbakemeldinger til epilogg@haugentech.no uten sensitive helseopplysninger.
```

- [ ] **Step 6: Write Beta App Review notes**

Create `Distribution/TestFlight/nb-NO/review-notes.md` with:

- no login is required;
- start button and all five onboarding steps;
- optional medicine behavior and validation;
- `+` button for a seizure;
- statistics period menu;
- Profile → export/delete;
- all sample data is fictitious;
- app is offline and does not provide medical advice;
- support URL and privacy URL;
- contact address `epilogg@haugentech.no`.

Include the exact phrase `Ingen innlogging er nødvendig`.

- [ ] **Step 7: Add export settings**

Create `Distribution/ExportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>destination</key>
    <string>upload</string>
    <key>method</key>
    <string>app-store-connect</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>HRQ5WGW63F</string>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 8: Write the release checklist**

Create `Distribution/ReleaseChecklist.md` with unchecked sections for:

- domain/support verification;
- automated tests;
- physical iPhone clean install;
- upgrade install;
- VoiceOver and large text;
- offline behavior;
- JSON export;
- delete-all;
- archive validation;
- App Privacy;
- TestFlight metadata;
- Beta App Review;
- internal tester sign-off;
- external tester sign-off.

Require date, build number, tester initials, device model, and iOS version for each manual run.

- [ ] **Step 9: Run release validator**

Run:

```bash
python3 Scripts/validate_distribution.py --release
plutil -lint Distribution/ExportOptions.plist EpiLogg/Info.plist EpiLogg/PrivacyInfo.xcprivacy
```

Expected: validator exit 0 and all plists report `OK`.

- [ ] **Step 10: Document TestFlight commands**

Add to `README.md`:

```bash
python3 Scripts/validate_distribution.py --brand
python3 Scripts/validate_distribution.py --site
python3 Scripts/validate_distribution.py --release
```

Document that upload credentials and archive files must never be committed.

- [ ] **Step 11: Commit**

```bash
git add EpiLogg.xcodeproj/project.pbxproj Distribution Scripts/validate_distribution.py README.md
git commit -m "chore: prepare TestFlight metadata"
```

---

### Task 6: Run Release Verification and Create the Signed Archive

**Files:**
- Modify only if verification finds a release-blocking defect.
- Update manually: `Distribution/ReleaseChecklist.md`

**Interfaces:**
- Produces: signed `.xcarchive`, successful Organizer validation, physical-device evidence, and an internal TestFlight build.
- Consumes: all repository artifacts from Tasks 2–5.

- [ ] **Step 1: Run all static distribution validation**

Run:

```bash
python3 Scripts/validate_distribution.py --brand
python3 Scripts/validate_distribution.py --site
python3 Scripts/validate_distribution.py --release
plutil -lint EpiLogg.xcodeproj/project.pbxproj EpiLogg/Info.plist EpiLogg/PrivacyInfo.xcprivacy Distribution/ExportOptions.plist
```

Expected: all commands exit 0.

- [ ] **Step 2: Run the complete test suite**

Run:

```bash
xcodebuild test \
  -project EpiLogg.xcodeproj \
  -scheme EpiLogg \
  -destination 'platform=iOS Simulator,id=904B66BF-2A68-4297-9B9F-FC30C37065B1' \
  -derivedDataPath .build/TestFlight \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO
```

Expected: all unit tests and both existing UI tests plus the new profile-link assertions pass with zero failures.

- [ ] **Step 3: Run a clean Release build**

Run:

```bash
xcodebuild clean build \
  -project EpiLogg.xcodeproj \
  -scheme EpiLogg \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath .build/TestFlight \
  DEVELOPMENT_TEAM=HRQ5WGW63F
```

Expected: `** BUILD SUCCEEDED **`, no app-icon error, and no signing error.

- [ ] **Step 4: Complete physical-device clean-install checks**

On a physical iPhone running iOS 17 or later:

1. Delete EpiLogg.
2. Install the Release build from Xcode.
3. Complete onboarding without medication.
4. Create one fictitious seizure.
5. Force-quit and reopen.
6. Confirm the record remains.
7. Export JSON and inspect it.
8. Delete all data and confirm onboarding returns.

Record device, OS, date, build, and result in `Distribution/ReleaseChecklist.md`.

- [ ] **Step 5: Complete accessibility and offline checks**

On the same device:

1. Enable a large Dynamic Type accessibility size.
2. Complete onboarding and create a record.
3. Enable VoiceOver and navigate Dashboard, Logg, and Profil.
4. Enable airplane mode and repeat save/edit/export/delete.
5. Inspect standard, dark, and tinted app icons.
6. Open privacy and support links after restoring connectivity.

Expected: no blocked control, clipped required text, network dependency, or missing accessible label.

- [ ] **Step 6: Create the archive**

Run:

```bash
xcodebuild archive \
  -project EpiLogg.xcodeproj \
  -scheme EpiLogg \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath .build/archives/EpiLogg-1.0.0-1.xcarchive \
  DEVELOPMENT_TEAM=HRQ5WGW63F
```

Expected: `** ARCHIVE SUCCEEDED **`.

- [ ] **Step 7: Inspect archive metadata**

Run:

```bash
plutil -p .build/archives/EpiLogg-1.0.0-1.xcarchive/Info.plist
plutil -p .build/archives/EpiLogg-1.0.0-1.xcarchive/Products/Applications/EpiLogg.app/Info.plist
```

Expected:

- `CFBundleIdentifier = no.epilogg.app`
- `CFBundleShortVersionString = 1.0.0`
- `CFBundleVersion = 1`
- application contains compiled app-icon assets and `PrivacyInfo.xcprivacy`.

- [ ] **Step 8: Validate in Xcode Organizer**

Open the archive in Xcode Organizer and select **Validate App**.

Expected: validation succeeds. Treat every error as blocking. Investigate warnings and record an explicit rationale before continuing.

- [ ] **Step 9: Create the App Store Connect app record**

In App Store Connect:

- platform: iOS;
- name: EpiLogg;
- primary language: Norwegian;
- bundle ID: `no.epilogg.app`;
- SKU: `EPILOGG-IOS-001`;
- user access: Full Access unless the account needs a narrower role.

If `EpiLogg` is unavailable, stop and request naming approval; do not append punctuation or company names silently.

- [ ] **Step 10: Enter app-level privacy and URLs**

Enter:

- Privacy Policy URL: `https://epilogg.haugentech.no/personvern`
- Support URL: `https://epilogg.haugentech.no/support`
- App Privacy: **No, we do not collect data from this app**

Cross-check every answer with `Distribution/AppPrivacy.md`.

- [ ] **Step 11: Upload build 1**

Use Organizer **Distribute App → App Store Connect → Upload**. Do not upload with a beta or release-candidate Xcode unless Apple explicitly permits that build.

Expected:
- upload completes;
- build `1.0.0 (1)` finishes processing;
- no export-compliance question is left unanswered.

- [ ] **Step 12: Complete export-compliance answers**

Answer based on the compiled app: EpiLogg uses only encryption supplied by Apple’s operating system and does not implement custom encryption. Record the exact App Store Connect answer in the release checklist.

If App Store Connect requests documentation instead of accepting the exemption, stop and investigate; do not guess.

- [ ] **Step 13: Add internal testers**

Add the account holder as an internal tester, install `1.0.0 (1)` through TestFlight, and rerun:

- first launch;
- create/edit/delete;
- export;
- delete-all;
- privacy/support links.

Expected: behavior matches the Xcode-installed Release build.

- [ ] **Step 14: Commit checklist evidence**

Commit only non-sensitive checklist results:

```bash
git add Distribution/ReleaseChecklist.md
git commit -m "test: record TestFlight release verification"
```

Do not commit archive files, xcresult bundles, Apple account screenshots, tester email addresses, certificates, or credentials.

---

### Task 7: Complete External TestFlight Review and Upgrade Testing

**Files:**
- Modify: `EpiLogg.xcodeproj/project.pbxproj` for build `2`
- Update: `Distribution/ReleaseChecklist.md`
- Update only if review requires factual clarification: `Distribution/TestFlight/nb-NO/*`

**Interfaces:**
- Produces: approved external TestFlight group, build-to-build upgrade evidence, and a written App Store phase recommendation.
- Consumes: processed build `1.0.0 (1)` and metadata from Task 5.

- [ ] **Step 1: Configure the external group**

Create group `EpiLogg ekstern beta` with a small invited group of adult testers. Do not use a public link for the first round.

Paste:

- beta description from `beta-description.txt`;
- test instructions from `what-to-test.txt`;
- review notes from `review-notes.md`;
- feedback address `epilogg@haugentech.no`.

- [ ] **Step 2: Submit build 1 for Beta App Review**

Select `1.0.0 (1)` and submit it to Beta App Review.

Expected:
- no login credentials requested;
- privacy/support URLs resolve publicly;
- medical limitations are stated in review notes.

If rejected, record the exact rejection text in the session and address only the cited issue. Do not broaden product claims to obtain approval.

- [ ] **Step 3: Run the first external beta round**

Ask each tester to complete the list in `what-to-test.txt` with fictitious data and report:

- device model and iOS version;
- passed/failed scenario;
- exact reproduction steps;
- screenshot only if it contains no sensitive information.

Classify findings:

- **Blocker:** crash, data loss, cannot complete onboarding/logging/delete-all.
- **Important:** inaccessible control, incorrect retained data, misleading health copy.
- **Minor:** visual polish or non-blocking copy issue.

Fix Blocker and Important findings before proceeding. Minor findings require an explicit decision.

- [ ] **Step 4: Increment build number for upgrade verification**

After any accepted fixes—or as a no-functional-change upgrade build if no fixes are needed—change both app-target build settings to:

```text
CURRENT_PROJECT_VERSION = 2;
```

Keep:

```text
MARKETING_VERSION = 1.0.0;
```

- [ ] **Step 5: Re-run validators and complete suite**

Run Task 6 Steps 1–3 with build number `2`.

Expected: zero failures and Release build success.

- [ ] **Step 6: Archive and upload build 2**

Archive as:

```text
.build/archives/EpiLogg-1.0.0-2.xcarchive
```

Validate and upload through Organizer.

- [ ] **Step 7: Verify TestFlight upgrade without data loss**

On at least one internal and one external tester device:

1. Keep fictitious records created in build 1.
2. Update to build 2 through TestFlight without deleting the app.
3. Confirm profile, medications, places, triggers, and seizures remain.
4. Create and edit a new record.
5. Export JSON.
6. Force-quit and reopen.

Expected: all build-1 data and new build-2 changes remain intact.

- [ ] **Step 8: Close the beta gate**

Update `Distribution/ReleaseChecklist.md` with:

- build 1 Beta App Review result;
- build 2 processing/review result;
- external tester device matrix;
- open Blocker/Important/Minor counts;
- upgrade-test outcome;
- recommendation: proceed to App Store phase or run another beta.

Fase 1 is complete only when Blocker = 0 and Important = 0.

- [ ] **Step 9: Commit final TestFlight evidence**

```bash
git add EpiLogg.xcodeproj/project.pbxproj Distribution/ReleaseChecklist.md
git commit -m "test: complete external TestFlight round"
```

- [ ] **Step 10: Stop before App Store submission**

Do not prepare screenshots or press **Submit for Review** as part of this plan. Return to the product owner with:

- TestFlight findings;
- support volume;
- unresolved Minor issues;
- Apple Developer Support response about Guideline 5.1.1(ix);
- recommendation for the separate App Store submission plan.
