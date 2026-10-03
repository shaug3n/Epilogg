# EpiLogg Release and TestFlight Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce, validate, upload, and test a signed EpiLogg 1.0.0 build through internal and then controlled external TestFlight.

**Architecture:** Keep release configuration in Xcode build settings and verification evidence in reproducible scripts/checklists. The archive is built only after brand, privacy, support, metadata, automated tests, and physical-device checks pass. Upload, tester invitation, and external Beta App Review remain explicit manual gates.

**Tech Stack:** Xcode 26 or later stable release, iOS 26 SDK or later, SwiftUI, SwiftData, XCTest/XCUITest, App Store Connect, TestFlight

**Spec:** `docs/superpowers/specs/2026-10-03-testflight-launch-design.md`

## Global Constraints

- Depends on both earlier implementation plans in `docs/superpowers/plans/`.
- Marketing version is `1.0.0`.
- Initial upload build number is `1`; every later upload increments it.
- Deployment target remains iOS 17.
- Bundle ID remains `no.epilogg.app` if registration succeeds.
- Use stable Xcode with iOS 26 SDK or later; never upload from beta Xcode.
- Do not add analytics, crash-reporting, backend, advertising, login, or medical functionality.
- Do not initialize Git automatically.
- Do not upload or invite testers without explicit account-holder approval.

---

### Task 1: Set release version and validate configuration

**Files:**
- Modify: `EpiLogg.xcodeproj/project.pbxproj`
- Create: `Tools/validate_release_configuration.py`
- Modify: `README.md`

**Interfaces:**
- Produces: app target with marketing version `1.0.0`, build `1`, bundle ID `no.epilogg.app`, and deployment target `17.0`.

- [ ] **Step 1: Write a failing release configuration check**

Parse `project.pbxproj` and assert both Debug and Release app configurations contain:

```text
MARKETING_VERSION = 1.0.0;
CURRENT_PROJECT_VERSION = 1;
PRODUCT_BUNDLE_IDENTIFIER = no.epilogg.app;
IPHONEOS_DEPLOYMENT_TARGET = 17.0;
ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
```

Also assert `Info.plist` obtains short version and build from `$(MARKETING_VERSION)` and `$(CURRENT_PROJECT_VERSION)`.

- [ ] **Step 2: Run the validator and confirm the version failure**

Run:

```bash
python3 Tools/validate_release_configuration.py
```

Expected: failure because the current marketing version is `0.1.0`.

- [ ] **Step 3: Update only the app target version**

Set `MARKETING_VERSION = 1.0.0` for Debug and Release. Preserve the existing build number at `1`. Do not alter test bundle IDs.

- [ ] **Step 4: Validate configuration and plist files**

Run:

```bash
python3 Tools/validate_release_configuration.py
plutil -lint EpiLogg.xcodeproj/project.pbxproj
plutil -lint EpiLogg/Info.plist
plutil -lint EpiLogg/PrivacyInfo.xcprivacy
```

Expected: all commands exit 0.

- [ ] **Step 5: Update release documentation**

Document the build-number rule: keep marketing version `1.0.0` throughout beta and increment `CURRENT_PROJECT_VERSION` for every replacement upload.

- [ ] **Step 6: Record the task checkpoint**

If Git has been initialized separately, commit with:

```text
chore: prepare version 1.0.0
```

### Task 2: Run automated release and binary audits

**Files:**
- Create: `Tools/audit_release_archive.sh`
- Modify only for discovered defects: production or test files related to the defect.

**Interfaces:**
- Consumes: completed brand and privacy plans.
- Produces: clean Release build and auditable archive checks.

- [ ] **Step 1: Run the complete simulator suite**

Use a clean dedicated simulator and run:

```bash
xcodebuild test \
  -project EpiLogg.xcodeproj \
  -scheme EpiLogg \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO
```

Expected: all unit and UI tests pass with zero failures.

- [ ] **Step 2: Run static analysis**

Run:

```bash
xcodebuild analyze \
  -project EpiLogg.xcodeproj \
  -scheme EpiLogg \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO
```

Expected: exit 0 with no analyzer finding.

- [ ] **Step 3: Create an unsigned verification archive**

Run:

```bash
xcodebuild archive \
  -project EpiLogg.xcodeproj \
  -scheme EpiLogg \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$PWD/build/EpiLogg-Verification.xcarchive" \
  CODE_SIGNING_ALLOWED=NO
```

Expected: `** ARCHIVE SUCCEEDED **`.

- [ ] **Step 4: Implement and run archive auditing**

`Tools/audit_release_archive.sh` must fail if it finds:

- unexpected dynamic frameworks;
- analytics, advertising, or crash-reporting SDK names;
- location, camera, microphone, contacts, photo library, or HealthKit usage descriptions;
- unexpected entitlements;
- missing app icon;
- wrong bundle ID, marketing version, or build number;
- missing privacy manifest.

It must print the final linked frameworks, entitlements, versions, and privacy manifest path.

- [ ] **Step 5: Fix each discovered defect with a regression test**

For any code behavior defect, first add the smallest XCTest or XCUITest that reproduces it, observe failure, apply one surgical fix, and re-run the full relevant selector. Configuration-only defects use the failing validation script as the regression.

- [ ] **Step 6: Re-run all automated release gates**

Expected: complete tests, analysis, archive, and audit all exit 0.

- [ ] **Step 7: Record the task checkpoint**

Store bounded logs outside the workspace. If Git has been initialized separately, commit verified fixes with:

```text
fix: resolve release audit findings
```

### Task 3: Complete physical-device release acceptance

**Files:**
- Create: `AppStore/PhysicalDeviceTestChecklist.md`
- Modify only for verified defects.

**Interfaces:**
- Produces: signed-off acceptance evidence for a supported physical iPhone.

- [ ] **Step 1: Install a Release build on a physical iPhone**

Use automatic development signing and a device running iOS 17 or later. Perform both a clean install and an upgrade over the most recent development build.

- [ ] **Step 2: Execute the functional checklist**

Verify with fictional data:

- five-step onboarding;
- empty optional onboarding;
- partial medicine validation on Continue and Skip;
- backward navigation preserving fields;
- create/edit/delete seizure;
- saved places and historical-place preservation;
- 7/30/90/custom statistics;
- persistence across force-quit and restart;
- JSON export and readable output;
- delete all data;
- privacy and support links;
- offline operation.

- [ ] **Step 3: Execute accessibility and layout checks**

Verify portrait and supported landscape orientations, largest practical Dynamic Type sizes, VoiceOver labels/order, button hit areas, contrast, reduced motion, and keyboard dismissal.

- [ ] **Step 4: Verify data-protection behavior**

Lock and unlock the device, relaunch, and confirm data remains available according to the configured `completeUntilFirstUserAuthentication` protection. Confirm no network dependency blocks core use.

- [ ] **Step 5: Resolve blockers**

Any crash, data loss, blocked navigation, inaccessible primary action, broken public link, or misleading medical claim blocks archive upload and requires a regression test before a fix.

- [ ] **Step 6: Record owner sign-off**

Date and sign the checklist with device model, OS version, app version, and build number.

### Task 4: Create the App Store Connect app record

**Files:**
- Update: `AppStore/AppStoreConnectChecklist.md`

**Interfaces:**
- Produces: an App Store Connect record linked to bundle ID `no.epilogg.app`.

- [ ] **Step 1: Obtain account-holder approval**

Present the exact app name, bundle ID, SKU, platform, primary language, and URLs. Do not create the record before approval.

- [ ] **Step 2: Register or confirm the bundle ID**

Confirm `no.epilogg.app` belongs to team `HRQ5WGW63F` and matches the signed target. If unavailable, stop and request a new bundle-ID decision; do not silently rename it.

- [ ] **Step 3: Create the app record**

Use:

- name: `EpiLogg`;
- platform: iOS;
- primary language: Norwegian;
- bundle ID: `no.epilogg.app`;
- SKU: `EPILOGG-IOS-001`;
- user access: full access unless the account holder intentionally restricts it.

- [ ] **Step 4: Enter app information**

Enter support and privacy URLs, copyright, age-rating answers, and the approved Norwegian metadata. Do not create an in-app purchase or subscription.

- [ ] **Step 5: Complete compliance questions**

Answer content rights, advertising identifier, privacy, and export-compliance questions from the actual audited binary. Record answers in the checklist without storing account secrets.

### Task 5: Produce and upload the signed archive

**Files:**
- No production file changes expected.
- Store logs and `.xcarchive` outside source control.

**Interfaces:**
- Produces: processed TestFlight build `1.0.0 (1)`.

- [ ] **Step 1: Obtain explicit upload approval**

Show evidence from Tasks 1–4 and ask the account holder to approve archive upload. Approval to execute the plan is not upload approval.

- [ ] **Step 2: Clean and archive with distribution signing**

In Xcode Organizer:

1. select `Any iOS Device (arm64)`;
2. use the EpiLogg scheme and Release configuration;
3. Product → Archive;
4. confirm archive identity is EpiLogg 1.0.0 (1), team `HRQ5WGW63F`, bundle ID `no.epilogg.app`.

- [ ] **Step 3: Validate the signed archive**

Use Organizer → Distribute App → App Store Connect → Upload and run validation. Stop on every warning that affects privacy, signing, icon, version, entitlement, or SDK requirements.

- [ ] **Step 4: Upload once**

Upload the validated archive. Do not repeat an upload with the same build number. If replacement is required, increment build to `2`, rerun release configuration checks, tests, audit, and archive validation.

- [ ] **Step 5: Verify App Store Connect processing**

Wait for processing to complete. Confirm:

- no invalid binary status;
- icon displays correctly;
- version/build is correct;
- export-compliance state is complete;
- no unexpected SDK privacy requirement appears.

### Task 6: Run internal TestFlight

**Files:**
- Create: `AppStore/InternalBetaResults.md`

**Interfaces:**
- Produces: completed internal test matrix and go/no-go result for external beta.

- [ ] **Step 1: Obtain tester-invitation approval**

Agree on named internal testers. Do not store their email addresses in the repository.

- [ ] **Step 2: Add internal testers and build**

Assign processed build `1.0.0 (1)` to the internal group and add the approved “What to Test” text.

- [ ] **Step 3: Execute the beta matrix**

Each tester records device, OS, clean/upgrade installation, completed scenarios, failures, and accessibility observations. They use fictional health data.

- [ ] **Step 4: Triage findings**

Classify:

- launch blocker: crash, data loss, privacy mismatch, unusable core flow;
- important: confusing core flow, accessibility barrier, broken layout;
- later improvement: non-blocking polish.

- [ ] **Step 5: Resolve blockers through TDD**

Every behavioral fix starts with a failing regression test. Increment build number for every uploaded replacement and repeat Tasks 2, 3, and 5.

- [ ] **Step 6: Decide external beta readiness**

External beta is allowed only when zero launch blockers remain and the account holder explicitly approves Beta App Review submission.

### Task 7: Run controlled external TestFlight beta

**Files:**
- Create: `AppStore/ExternalBetaResults.md`

**Interfaces:**
- Produces: external Beta App Review result and public-release readiness findings.

- [ ] **Step 1: Obtain external-beta approval**

Agree on a small external group and confirm support capacity. Do not store tester personal information in the repository.

- [ ] **Step 2: Complete Beta App Review information**

Enter approved beta description, “What to Test,” review notes, contact information, privacy URL, support URL, and export compliance.

- [ ] **Step 3: Submit the build for Beta App Review**

Do not describe the beta as clinical research or request real health data. Respond to reviewer questions using the approved medical-positioning text.

- [ ] **Step 4: Distribute after approval**

Invite only the approved group. Monitor App Store Connect feedback and crash information without adding a third-party SDK.

- [ ] **Step 5: Run the external matrix**

Focus on comprehension, accessibility, device compatibility, persistence, export, deletion, and offline use.

- [ ] **Step 6: Write the TestFlight exit report**

Summarize build tested, device coverage, unresolved issues, Apple account-eligibility response, metadata readiness, and recommendation:

- proceed to a separately approved public App Store plan;
- run another beta build; or
- pause release.

No public submission occurs from this task.

