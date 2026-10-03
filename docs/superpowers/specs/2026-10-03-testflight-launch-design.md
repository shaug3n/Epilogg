# EpiLogg TestFlight Launch Design

**Date:** 3 October 2026  
**Status:** Awaiting final review  
**Scope:** Prepare and distribute the current EpiLogg version through TestFlight. Public App Store release is a later, separately approved phase.

## 1. Objective

Prepare the existing local-first Norwegian iPhone app for a controlled TestFlight beta without changing its core product behavior.

The phase is complete when:

1. EpiLogg has production-ready brand assets and an app icon.
2. Required privacy and support information is public and accessible from the app.
3. The app builds as a signed Release archive with valid versioning and App Store metadata.
4. A validated build is uploaded to App Store Connect.
5. Internal TestFlight testing succeeds, followed by an optional external beta after Beta App Review.
6. Findings are recorded before any public App Store submission.

No public App Store release, paid feature, account system, analytics SDK, advertising SDK, backend, or medical functionality is part of this phase.

## 2. Confirmed Product Decisions

- Product name: **EpiLogg**
- Platform: iPhone only
- Primary language: Norwegian Bokmål
- Minimum supported OS: iOS 17
- Distribution order: internal TestFlight, then a small external TestFlight group
- Core data model: local-only SwiftData storage
- No login, backend, tracking, analytics, advertising, or automatic location collection
- Public App Store release will use manual release control if approved after beta
- Current individual Apple Developer account remains in use for TestFlight preparation

Before public App Store submission, the account holder will ask Apple Developer Support whether EpiLogg can be submitted from an individual account under App Review Guideline 5.1.1(ix). The support request must describe EpiLogg as a voluntary offline diary that neither diagnoses, treats, measures, alerts, nor shares health information with the developer. If Apple requires a legal entity, public submission pauses until an organization account is available. This eligibility question does not change the product or introduce a workaround.

## 3. Visual Identity

### 3.1 Approved direction

The approved identity is **C2 – Bokmerket**:

- dark blue-green rounded background;
- open book with two calm page shapes;
- warm peach bookmark;
- restrained green page details;
- no text inside the app icon;
- no medical cross, brain illustration, seizure waveform, monitoring claim, or alarm symbolism.

The icon communicates personal record keeping and history rather than diagnosis or real-time medical monitoring.

### 3.2 Required deliverables

Create and preserve:

- layered vector source for the symbol;
- Icon Composer project or equivalent layered Xcode-compatible icon source;
- standard, dark, and tinted icon appearances;
- flattened 1024 by 1024 marketing icon;
- horizontal wordmark with icon and “EpiLogg”;
- icon-only and wordmark exports as SVG and high-resolution PNG;
- a short brand note containing color values, clear space, minimum size, and forbidden uses.

The production icon must be optically adjusted and tested at 32, 48, 60, 120, 180, and 1024 pixels. Xcode and App Store validation determine the final generated asset sizes. Apple applies its own icon mask; source artwork must not bake in an extra rounded-corner mask.

### 3.3 Brand palette

The identity will reuse the app’s existing restrained palette:

- deep blue-green for the icon background and primary wordmark;
- muted green for supporting details;
- warm peach for the bookmark;
- white and pale green for pages.

Exact production color values are derived from the approved C2 artwork and checked for contrast in standard, dark, and tinted appearances.

## 4. Privacy, Support, and Medical Positioning

### 4.1 Public pages

Publish two stable HTTPS pages before uploading:

1. **Privacy policy**
   - explains that the app stores health diary data locally;
   - states that the developer does not receive the user’s diary data;
   - explains possible inclusion in device backups;
   - describes local deletion and exported JSON behavior;
   - explains that exported files are not encrypted by EpiLogg;
   - identifies any future third-party SDKs before they are added;
   - provides effective date, developer identity, and contact information.

2. **Support page**
   - identifies EpiLogg;
   - provides a monitored contact method;
   - contains basic troubleshooting and data-loss guidance;
   - links to the privacy policy.

The hosting solution may be a simple static site. It must not use unnecessary trackers or collect health information through support forms.

### 4.2 In-app access

Add clearly visible links under Profile:

- “Personvern”
- “Hjelp og kontakt”

The privacy policy link satisfies Apple’s requirement for an easily accessible in-app privacy policy. Links open through the standard system browser presentation and expose failures rather than silently doing nothing.

### 4.3 App Privacy answers

For the current build, select **“No, we do not collect data from this app”** only after a final dependency and network audit confirms:

- no app data is transmitted off-device to the developer or a third party;
- no analytics, crash-reporting, advertising, or tracking SDK is present;
- support contact happens outside the app and is described on the support page.

The on-device privacy manifest remains aligned with actual API usage. App Store Connect answers and the public privacy policy must be updated before introducing any future collection.

### 4.4 Medical claims

All product-page and in-app text must consistently state that EpiLogg:

- is a personal diary for the user’s own observations;
- does not diagnose, treat, predict, or detect seizures;
- does not calculate medicine doses;
- does not replace professional medical advice;
- does not alert clinicians, family, or emergency services.

The review notes explain these boundaries and the absence of medical accuracy claims.

## 5. App Store Connect Record and Build Configuration

### 5.1 App record

Create the app record using:

- name: EpiLogg;
- primary language: Norwegian;
- bundle ID: `no.epilogg.app`, provided it is available and registered to the current team;
- SKU: a stable internal value that contains no sensitive information;
- platform: iOS.

Agreements, tax, banking, and developer contact details must be reviewed even though the beta is free and contains no purchases.

### 5.2 Versioning

Change the release candidate from marketing version `0.1.0` to `1.0.0`.

- `CFBundleShortVersionString`: `1.0.0`
- initial TestFlight build number: `1`
- every subsequent upload increments the build number

Version and build numbers remain generated from the Xcode build settings already referenced by the Info plist.

### 5.3 Toolchain and signing

- Build with a stable Xcode release that includes iOS 26 SDK or later.
- Keep the iOS 17 deployment target unless physical-device testing reveals an unsupported API.
- Use automatic signing with the selected Apple Developer team.
- Register the bundle ID and App Store distribution provisioning through Xcode and the developer portal.
- Do not upload a build produced by a beta Xcode toolchain.

The app contains no encryption feature beyond Apple platform networking and storage APIs. App Store Connect export-compliance answers must be completed truthfully based on the final binary; no exemption is assumed without checking the archive.

## 6. Store Metadata and Beta Material

Prepare Norwegian Bokmål metadata:

- app name;
- subtitle;
- promotional text if used;
- full description;
- keywords;
- support URL;
- privacy policy URL;
- copyright holder;
- category and age-rating questionnaire;
- review contact details;
- review notes;
- TestFlight beta description;
- “What to Test” instructions.

Metadata must describe only implemented functionality. It must not claim seizure detection, emergency response, clinical analysis, treatment guidance, or guaranteed trigger identification.

### 6.1 Screenshots

Capture screenshots from a Release-equivalent build using fictional data. The first set should show:

1. dashboard and development over time;
2. quick seizure registration;
3. saved places and indoor/outdoor context;
4. statistics for a selected period;
5. editable history and privacy-oriented local storage.

Screenshots must not include real names, real medication histories, notifications, debug overlays, simulator chrome not intended for the product page, or unsupported feature claims.

App Store screenshots are prepared during TestFlight but are not required to begin internal beta distribution.

## 7. Release Verification

### 7.1 Automated verification

Before every upload:

- run all unit and UI tests on a clean simulator;
- create a Release build for a generic iOS device;
- run Xcode Analyze;
- validate Info plist and privacy manifest;
- inspect the archive for unexpected frameworks, entitlements, permissions, and privacy manifests;
- validate the archive with App Store Connect.

### 7.2 Physical-device verification

Test on at least one supported physical iPhone:

- clean installation and five-step onboarding;
- medicine validation and backward navigation;
- seizure create, edit, and delete;
- persistence across termination and restart;
- statistics periods and filters;
- saved places and preservation of historical locations;
- JSON export and opening the exported file;
- delete-all flow;
- privacy and support links;
- offline operation;
- portrait and supported landscape layouts;
- larger text sizes, VoiceOver labels, contrast, and reduced motion;
- upgrade from the most recent development build without data loss.

Any crash, data-loss issue, blocked navigation, inaccessible primary action, or misleading medical claim blocks upload.

## 8. TestFlight Rollout

### 8.1 Internal beta

1. Upload the validated archive from Xcode Organizer.
2. Wait for App Store Connect processing and resolve all compliance questions.
3. Add only trusted internal testers.
4. Provide a focused test script covering onboarding, medicine validation, logging, statistics, persistence, export, deletion, accessibility, and offline use.
5. Collect feedback without asking testers to submit real health information.
6. Classify findings as launch blocker, important, or later improvement.

### 8.2 External beta

After internal blockers are resolved:

1. create a small external tester group;
2. provide complete beta description, contact details, and review notes;
3. submit the build for Beta App Review;
4. distribute only after approval;
5. monitor crashes and feedback through App Store Connect without adding a third-party analytics SDK.

The external beta should validate comprehensibility, accessibility, device compatibility, and data preservation. It is not a clinical trial and must not be presented as one.

## 9. Public App Store Phase

Public App Store submission begins only after:

- TestFlight exit criteria are met;
- the individual-versus-organization account question is resolved with Apple;
- final store metadata and screenshots are approved;
- country availability, price, and launch date are explicitly chosen;
- a separate go/no-go approval is given.

If public release is approved, use manual release after App Review rather than automatic publication.

## 10. Exit Criteria

The TestFlight preparation phase is complete when:

- approved C2 brand assets are integrated and validated;
- privacy and support pages are public and linked inside the app;
- App Privacy answers match the audited binary;
- version `1.0.0` has a unique build number;
- automated and physical-device release checks pass;
- the archive is accepted by App Store Connect;
- internal TestFlight testers can install and complete the test script;
- external Beta App Review either succeeds or the team explicitly decides to remain internal;
- all launch blockers are resolved or the release candidate is withdrawn.

