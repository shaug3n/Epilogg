# EpiLogg Privacy and Store Material Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish EpiLogg’s privacy and support information, expose it inside the app, and prepare accurate Norwegian TestFlight and App Store metadata.

**Architecture:** Maintain deployable static pages in `Website/epilogg/` and point the app to stable HTTPS URLs under `haugentech.no`. Centralize external URLs in one typed Swift namespace, use a reusable open-URL control that surfaces failures, and keep all store copy in versioned plain-text files validated for Apple’s limits.

**Tech Stack:** Static HTML/CSS, SwiftUI `OpenURLAction`, XCTest/XCUITest, shell validation, App Store Connect

**Spec:** `docs/superpowers/specs/2026-10-03-testflight-launch-design.md`

## Global Constraints

- Privacy URL: `https://haugentech.no/epilogg/personvern/`
- Support URL: `https://haugentech.no/epilogg/support/`
- Public contact: `kontakt@haugentech.no`
- Developer identity in the policy: `Sondre Haugen`
- Do not add analytics, forms, cookies, trackers, third-party fonts, or third-party scripts.
- State that EpiLogg is a personal diary, not diagnosis, treatment, detection, prediction, dosage guidance, or emergency response.
- Do not initialize Git automatically.

---

### Task 1: Create privacy and support pages

**Files:**
- Create: `Website/epilogg/styles.css`
- Create: `Website/epilogg/personvern/index.html`
- Create: `Website/epilogg/support/index.html`
- Create: `Tools/validate_public_pages.py`

**Interfaces:**
- Produces: static files deployable at the two exact URLs consumed by the app.

- [ ] **Step 1: Write a failing public-page validator**

Create `Tools/validate_public_pages.py` using only Python’s standard library. It must parse both HTML files and assert:

- `<html lang="nb">`;
- page-specific `<title>`;
- a link to the other page;
- `kontakt@haugentech.no`;
- no `<script>`, `<form>`, remote stylesheet, iframe, or analytics hostname;
- privacy page includes the literal headings `Opplysninger som lagres`, `Lagring og sletting`, `Eksport`, and `Kontakt`;
- support page includes `Vanlige spørsmål`, `Sikkerhetskopi og tap av data`, and `Kontakt`.

- [ ] **Step 2: Run the validator and verify it fails**

Run:

```bash
python3 Tools/validate_public_pages.py
```

Expected: exit 1 because both HTML files are missing.

- [ ] **Step 3: Create the shared static design**

Use system fonts, the approved deep blue-green, muted green, warm peach, and a maximum text width of 720 pixels. Include visible keyboard focus and a skip-free semantic heading structure. Load no remote assets.

- [ ] **Step 4: Write the Norwegian privacy policy**

The policy must explicitly state:

- EpiLogg stores profile, medicine, seizure, trigger, place, note, and statistics source data locally through Apple SwiftData;
- Sondre Haugen does not receive or access diary data;
- the app has no account, analytics, advertising, or tracking;
- iPhone backups may contain app data according to the user’s Apple backup settings;
- users delete individual seizures or all data inside the app;
- exported JSON is created only on user request, leaves app-controlled storage when shared, and is not encrypted by EpiLogg;
- support email may contain whatever the sender chooses to disclose and users should not email health details;
- effective date is 3 October 2026;
- contact is `kontakt@haugentech.no`.

- [ ] **Step 5: Write the Norwegian support page**

Include:

- what EpiLogg does and does not do;
- how to export data;
- how to delete data;
- offline behavior;
- backup/data-loss warning;
- request not to send health details by email;
- mail link to `kontakt@haugentech.no`;
- privacy-policy link.

- [ ] **Step 6: Run static-page validation**

Run:

```bash
python3 Tools/validate_public_pages.py
python3 -m http.server 8088 --directory Website
```

Start the HTTP server with the Bash tool in attached async mode and record its exact shell ID and PID. Then run:

```bash
curl -fsS http://127.0.0.1:8088/epilogg/personvern/ | grep 'Personvern'
curl -fsS http://127.0.0.1:8088/epilogg/support/ | grep 'Hjelp'
```

Stop only that known HTTP-server execution after the checks. Expected: validator and both curl checks exit 0.

- [ ] **Step 7: Record the task checkpoint**

If Git has been initialized separately, commit with:

```text
docs: add EpiLogg privacy and support pages
```

### Task 2: Add resilient in-app links

**Files:**
- Create: `EpiLogg/Domain/LaunchResources.swift`
- Create: `EpiLogg/Design/ExternalResourceButton.swift`
- Modify: `EpiLogg/Features/Profile/ProfileView.swift`
- Test: `EpiLoggTests/LaunchResourcesTests.swift`
- Test: `EpiLoggUITests/EpiLoggUITests.swift`

**Interfaces:**
- Produces:

```swift
enum LaunchResources {
    static let privacyPolicyURL: URL
    static let supportURL: URL
}

struct ExternalResourceButton: View {
    let title: String
    let systemImage: String
    let url: URL
    let onFailure: () -> Void
}
```

- [ ] **Step 1: Write failing URL tests**

Add:

```swift
func testLaunchResourceURLsUseExpectedHTTPSPages() {
    XCTAssertEqual(
        LaunchResources.privacyPolicyURL.absoluteString,
        "https://haugentech.no/epilogg/personvern/"
    )
    XCTAssertEqual(
        LaunchResources.supportURL.absoluteString,
        "https://haugentech.no/epilogg/support/"
    )
    XCTAssertEqual(LaunchResources.privacyPolicyURL.scheme, "https")
    XCTAssertEqual(LaunchResources.supportURL.scheme, "https")
}
```

- [ ] **Step 2: Add failing UI expectations**

In the existing end-to-end profile flow, assert buttons with identifiers `profile.privacy` and `profile.support` exist. Do not tap external links in the automated UI test.

- [ ] **Step 3: Run tests and verify failure**

Run the unit selector and UI selector. Expected: unit test fails to compile because `LaunchResources` is missing, and UI coverage lacks the buttons after the type is added.

- [ ] **Step 4: Implement URL constants and open handling**

`ExternalResourceButton` must call:

```swift
@Environment(\.openURL) private var openURL

Button {
    openURL(url) { accepted in
        if !accepted { onFailure() }
    }
} label: {
    Label(title, systemImage: systemImage)
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
}
```

Use existing profile error presentation with the message:

```text
Kunne ikke åpne siden. Prøv igjen, eller kontakt kontakt@haugentech.no.
```

Add both controls in a visible `Hjelp og personvern` card before destructive data actions.

- [ ] **Step 5: Run targeted tests**

Expected: URL unit test and existing UI test pass.

- [ ] **Step 6: Verify real links manually**

After deployment in Task 3, tap both controls on a physical iPhone and verify Safari opens the expected HTTPS page. Turn on airplane mode and verify the app shows the explicit error path.

- [ ] **Step 7: Record the task checkpoint**

If Git has been initialized separately, commit with:

```text
feat: add privacy and support links
```

### Task 3: Deploy public pages to haugentech.no

**Files:**
- Deploy: contents of `Website/epilogg/` to the existing haugentech.no host.

**Interfaces:**
- Produces: stable public HTTPS endpoints used by App Store Connect and the app.

- [ ] **Step 1: Confirm deployment ownership and backup**

Identify the existing haugentech.no deployment method and back up the current site before changing it. Do not replace unrelated pages.

- [ ] **Step 2: Deploy only the EpiLogg subtree**

Publish:

```text
Website/epilogg/personvern/index.html -> /epilogg/personvern/
Website/epilogg/support/index.html    -> /epilogg/support/
Website/epilogg/styles.css            -> /epilogg/styles.css
```

- [ ] **Step 3: Verify HTTPS behavior**

Run:

```bash
curl --fail --silent --show-error --location \
  https://haugentech.no/epilogg/personvern/ \
  | grep 'Opplysninger som lagres'
curl --fail --silent --show-error --location \
  https://haugentech.no/epilogg/support/ \
  | grep 'Vanlige spørsmål'
```

Expected: both exit 0 with no certificate or redirect loop.

- [ ] **Step 4: Verify mobile rendering and contact link**

Open both URLs on iPhone. Confirm readable text without horizontal scrolling, visible focus/link styles, correct cross-links, and a mail link addressed to `kontakt@haugentech.no`.

- [ ] **Step 5: Record the task checkpoint**

Record deployment date and verification output. If the website source is separately version-controlled, commit there with:

```text
docs: publish EpiLogg privacy and support pages
```

### Task 4: Prepare versioned store and beta copy

**Files:**
- Create: `AppStore/nb-NO/name.txt`
- Create: `AppStore/nb-NO/subtitle.txt`
- Create: `AppStore/nb-NO/promotional_text.txt`
- Create: `AppStore/nb-NO/description.txt`
- Create: `AppStore/nb-NO/keywords.txt`
- Create: `AppStore/review_notes_nb.txt`
- Create: `AppStore/testflight_beta_description_nb.txt`
- Create: `AppStore/testflight_what_to_test_nb.txt`
- Create: `Tools/validate_store_metadata.py`

**Interfaces:**
- Produces: reviewed copy for App Store Connect and the external-beta review form.

- [ ] **Step 1: Write failing metadata length checks**

The validator must enforce:

- name at most 30 characters;
- subtitle at most 30 characters;
- promotional text at most 170 characters;
- keywords at most 100 UTF-8 bytes;
- description at most 4000 characters;
- every file is nonempty and contains none of the unfinished marker strings `TBD`, `TODO`, or `FILL ME`.

- [ ] **Step 2: Run validator and verify missing-file failures**

Run:

```bash
python3 Tools/validate_store_metadata.py
```

Expected: exit 1 listing the missing metadata files.

- [ ] **Step 3: Add fixed short metadata**

Use:

```text
name: EpiLogg
subtitle: Personlig anfallsdagbok
promotional text: Loggfør anfall, medisiner, mulige triggere og steder. Se utviklingen over tid – privat og lokalt på din iPhone.
keywords: epilepsi,anfall,dagbok,logg,medisin,triggere,statistikk,helse
```

- [ ] **Step 4: Write the full Norwegian description**

The description must cover quick logging, optional duration, triggers, saved places, medicines, editable history, 7/30/90/custom periods, JSON export, local storage, and limitations. It must not promise diagnosis, detection, prediction, treatment, emergency alerts, medical advice, or causal trigger analysis.

- [ ] **Step 5: Write review and TestFlight material**

Review notes must explain:

- no login is required;
- all fields are optional except a medicine name after the user starts adding that medicine;
- data remains local;
- the app contains no paid features;
- review can complete onboarding with empty fields;
- delete-all is under Profile;
- EpiLogg is not a medical device and makes no measurement or accuracy claim.

“What to Test” must ask testers to verify onboarding, medicine validation, logging, edit/delete, saved places, statistics periods, restart persistence, JSON export, delete-all, accessibility, and offline behavior using fictional data.

- [ ] **Step 6: Validate and human-review copy**

Run:

```bash
python3 Tools/validate_store_metadata.py
```

Expected: exit 0. Then obtain owner approval of every visible text file before entering it in App Store Connect.

- [ ] **Step 7: Record the task checkpoint**

If Git has been initialized separately, commit with:

```text
docs: prepare Norwegian App Store metadata
```

### Task 5: Produce App Store screenshots

**Files:**
- Create: `AppStore/Screenshots/nb-NO/01-oversikt.png`
- Create: `AppStore/Screenshots/nb-NO/02-registrer-anfall.png`
- Create: `AppStore/Screenshots/nb-NO/03-steder.png`
- Create: `AppStore/Screenshots/nb-NO/04-statistikk.png`
- Create: `AppStore/Screenshots/nb-NO/05-historikk.png`
- Create: `AppStore/Screenshots/README.md`
- Create: `Tools/validate_store_screenshots.swift`

**Interfaces:**
- Produces: five portrait screenshots at an Apple-accepted 6.9-inch size of exactly 1320 by 2868 pixels.

- [ ] **Step 1: Write a failing screenshot validator**

Create `Tools/validate_store_screenshots.swift` with AppKit. It must load the five exact paths, assert each is PNG, assert `pixelsWide == 1320` and `pixelsHigh == 2868`, and reject an alpha channel. It must also reject files with duplicate SHA-256 hashes.

- [ ] **Step 2: Run the validator and confirm missing-file failures**

Run:

```bash
swift Tools/validate_store_screenshots.swift
```

Expected: exit 1 listing all five missing screenshots.

- [ ] **Step 3: Prepare deterministic fictional content**

Use only fictional information:

- preferred name `Ola`;
- medicine `Eksempelmedisin`, dose `100 mg`;
- places `Hjemme` and `Jobb`;
- trigger `Lite søvn`;
- at least four seizures spread across the previous 30 days;
- no real contact, medication, location, or health history.

The screenshots must not show keyboard, debug overlays, alerts, cursor, simulator controls, or notifications.

- [ ] **Step 4: Capture the five product views**

Capture:

1. dashboard with 30-day trend;
2. prominent “Hvor skjedde det?” registration card;
3. saved-place selection;
4. custom statistics period and chart;
5. editable seizure history.

Use a 6.9-inch simulator configuration producing 1320 by 2868 portrait PNG output. Do not add device frames or marketing captions in this phase.

- [ ] **Step 5: Validate image files**

Run:

```bash
swift Tools/validate_store_screenshots.swift
```

Expected: exit 0 with `Validated 5 App Store screenshots at 1320x2868`.

- [ ] **Step 6: Human-review every screenshot**

Verify Norwegian copy, fictional data, legibility, correct app icon, no unsupported claim, no personal information, and a distinct product feature in each image.

- [ ] **Step 7: Record the task checkpoint**

If Git has been initialized separately, commit with:

```text
docs: add Norwegian App Store screenshots
```

### Task 6: Complete privacy and account eligibility records

**Files:**
- Create: `AppStore/AppStoreConnectChecklist.md`
- Create: `AppStore/AppleSupportAccountQuestion.txt`

**Interfaces:**
- Produces: auditable manual answers and the exact support request required before public submission.

- [ ] **Step 1: Write the App Privacy audit checklist**

Record checks for network code, dependencies, linked frameworks, privacy manifests, analytics, crash reporting, advertising, and support forms. The answer `No, we do not collect data from this app` is entered only if every check remains false.

- [ ] **Step 2: Write the Apple Developer Support question**

Use a concise description stating that EpiLogg is an offline personal epilepsy diary, accepts optional sensitive information directly from the user, does not transmit it to the developer, and does not diagnose, treat, detect, predict, measure, calculate dosage, or contact healthcare services. Ask whether Guideline 5.1.1(ix) requires conversion from an individual to an organization account before public App Store submission.

- [ ] **Step 3: Submit the question manually**

The account holder sends the text through Apple Developer Support and stores the response outside the repository if it contains personal account information.

- [ ] **Step 4: Complete App Store Connect privacy information**

Enter:

- privacy policy URL: `https://haugentech.no/epilogg/personvern/`;
- support URL: `https://haugentech.no/epilogg/support/`;
- data collection: `No, we do not collect data from this app`, only if Step 1 passes.

- [ ] **Step 5: Record the task checkpoint**

Mark the public-submission account gate as:

- cleared for individual account;
- requires organization conversion; or
- unresolved, which blocks public submission but not internal TestFlight preparation.
