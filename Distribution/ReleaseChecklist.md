# EpiLogg 1.0.0 TestFlight release checklist

## Release configuration

- [ ] Marketing version is `1.0.0` and first build number is `1`.
- [ ] App icon and distribution assets validate.
- [ ] Privacy policy and support pages resolve over HTTPS.
- [ ] `epilogg@haugentech.no` accepts and sends support mail.
- [ ] App Privacy answers match `AppPrivacy.md` and the shipped build.
- [ ] TestFlight description, test instructions and review notes are entered.

## Automated verification

- [ ] Distribution validator passes for brand, site and release.
- [ ] Unit and UI test suites pass on a supported iOS simulator.
- [ ] Release build and archive validate without warnings requiring action.

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
