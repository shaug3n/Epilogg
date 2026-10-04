# EpiLogg 1.0.0 TestFlight release checklist

## Release configuration

- [x] Marketing version is `1.0.0` and first build number is `1`.
- [x] App icon and distribution assets validate.
- [x] Privacy policy and support pages resolve over HTTPS.
- [ ] `epilogg@haugentech.no` accepts and sends support mail.
- [ ] App Privacy answers match `AppPrivacy.md` and the shipped build.
- [ ] TestFlight description, test instructions and review notes are entered.

## Automated verification

- [x] Distribution validator passes for brand, site and release.
- [x] Unit and UI test suites pass on a supported iOS simulator.
- [x] Release build succeeds and the local IPA export uses Apple Distribution signing.
- [ ] Validate the archive in Xcode Organizer before uploading.

## Verification evidence — 4 October 2026

- Complete suite: 33 unit tests and 3 UI tests passed on iPhone 17 Pro / iOS 26.5.
- Clean Release build and archive succeeded. Xcode emitted only the non-blocking App Intents metadata warning; the app does not use App Intents.
- Local App Store Connect export succeeded as `1.0.0 (1)`. The IPA is signed with Apple Distribution and an App Store profile (`get-task-allow=false`). It has not been uploaded.
- Privacy and support pages were fetched over HTTPS and returned the approved domain and support address.

## Manual test runs

Record date, build number, tester initials, device model, iOS version and evidence for every run.

| Test | Date | Build | Tester initials | Device model | iOS version | Result / evidence |
|---|---|---|---|---|---|---|
| Clean install on physical iPhone |  |  |  |  |  |  |
| Upgrade from previous beta build |  |  |  |  |  |  |
| VoiceOver and large text |  |  |  |  |  |  |
| Logging without network access |  |  |  |  |  |  |
| JSON export and safe handling |  |  |  |  |  |  |
| Delete all data |  |  |  |  |  |  |
| Archive validation |  |  |  |  |  |  |
| Internal tester sign-off |  |  |  |  |  |  |
| External tester sign-off |  |  |  |  |  |  |

## App Store Connect and beta review

- [ ] App record uses bundle ID `no.epilogg.app` and SKU `EPILOGG-IOS-001`.
- [ ] Privacy Policy URL: `https://epilogg.haugentech.no/personvern`.
- [ ] Support URL: `https://epilogg.haugentech.no/support`.
- [ ] Beta App Review walkthrough uses fictitious data and needs no login.
- [ ] Internal TestFlight build is accepted and tested.
- [ ] External TestFlight build is approved and tester feedback reviewed.

Do not commit signing credentials, API keys, provisioning secrets or archive files.
