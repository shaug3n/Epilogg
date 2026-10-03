# EpiLogg TestFlight Roadmap

> **For agentic workers:** Execute the linked implementation plans in dependency order. Do not upload, distribute, or publish without an explicit approval at the relevant manual gate.

**Goal:** Coordinate EpiLogg’s path from the current development build to a controlled TestFlight beta.

**Spec:** `docs/superpowers/specs/2026-10-03-testflight-launch-design.md`

## Plan order

1. [Brand and App Icon](./2026-10-03-epilogg-brand-and-app-icon.md)
2. [Privacy, Support, and Store Material](./2026-10-03-epilogg-privacy-and-store-material.md)
3. [Release and TestFlight Distribution](./2026-10-03-epilogg-release-and-testflight.md)

Plans 1 and 2 can be implemented independently. Plan 3 depends on the verified outputs of both.

## Manual gates

- Creating an App Store Connect app record requires the account holder’s approval.
- Uploading an archive requires the account holder’s approval.
- Adding internal or external testers requires the account holder’s approval.
- External TestFlight distribution requires Beta App Review.
- Public App Store submission and release are outside these plans.
- The workspace is not currently a Git repository. Do not initialize Git automatically. Where a plan mentions a commit message, use it only if the owner has separately initialized version control.

