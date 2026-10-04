# EpiLogg

En norsk iPhone-app for å føre en personlig anfallsdagbok. EpiLogg viser bare opplysninger du selv legger inn, og gir ikke medisinske råd, stiller ikke diagnoser og varsler ikke helsepersonell eller pårørende.

## Kom i gang i Xcode

1. Åpne `EpiLogg.xcodeproj`.
2. Velg skjemaet **EpiLogg**, og velg en iPhone-simulator.
3. Trykk **Run**. Appen støtter iOS 17 eller nyere.

For fysisk iPhone: velg app-targetet **EpiLogg → Signing & Capabilities**, slå på automatisk signering og velg Apple Developer-teamet ditt. Endre bundle identifier `no.epilogg.app` dersom teamet krever en unik ID.

## Kjør testene

Kjør alle enhets- og UI-testene på en tilgjengelig iPhone-simulator:

```sh
xcodebuild test \
  -project EpiLogg.xcodeproj \
  -scheme EpiLogg \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Kjernefunksjonene og beregningene har enhets­tester, inkludert oppgradering av eksisterende databaser til en profil med lagrede steder. UI-testen går gjennom onboarding med egendefinerte triggere og steder, bruker dem ved anfallslogging, velger inne-/utemiljø og åpner anfallene i en egendefinert periode. Den starter appen på nytt for å verifisere lagring, endrer stedslisten i profilen og kontrollerer at historiske steder bevares. Den tester også at steder fra nye anfall blir tilgjengelige senere, men ikke lagres ved avbrutt registrering, før den redigerer, sletter og kontrollerer sletting av alle data.

En egen UI-regresjonstest kontrollerer at tomme eller delvis utfylte medisiner med manglende navn stopper både «Fortsett» og «Hopp over» på medisinsiden. Den tester også flere medisiner, retting og fjerning, samt at opplysninger beholdes når brukeren går tilbake.

## Merkevarefiler

Appikonet bruker den godkjente retningen **Bokmerket**. `Brand/AppIcon.icon` er den redigerbare Icon Composer-kilden, mens PNG-filene i asset-katalogen genereres deterministisk fra Swift-skriptet og skal ikke redigeres separat.

```sh
swift Scripts/generate_brand_assets.swift
python3 Scripts/validate_distribution.py --brand
```

## Offentlig informasjonsside

`Site/` inneholder den statiske landingssiden, personvernerklæringen og supportsiden for `https://epilogg.haugentech.no`. Vercel-prosjektet skal bruke `Site/` som prosjektrot og krever ingen byggekommando.

```sh
python3 Scripts/validate_distribution.py --site
python3 -m http.server 8080 --directory Site
```

Nettstedet bruker ikke skript, analyseverktøy, informasjonskapsler eller eksterne ressurser. Offentlig kontaktadresse er `epilogg@haugentech.no`.

## TestFlight-forberedelser

Versjon og buildnummer valideres sammen med TestFlight-beskrivelsen, testinstruksjonene, Beta App Review-notatene og eksportinnstillingene:

```sh
python3 Scripts/validate_distribution.py --brand
python3 Scripts/validate_distribution.py --site
python3 Scripts/validate_distribution.py --release
plutil -lint Distribution/ExportOptions.plist EpiLogg/Info.plist EpiLogg/PrivacyInfo.xcprivacy
```

Bruk `Distribution/ReleaseChecklist.md` for fysisk enhetstesting og App Store Connect-gjennomgang. Ikke legg opplastingslegitimasjon, signeringshemmeligheter, provisioning-profiler eller arkivfiler i Git.

## Innhold

- Fem steg i onboardingen, med valgfrie opplysninger om diagnose, medisiner, mulige triggere og egne steder.
- Medisiner valideres før brukeren forlater medisinsiden: hver medisin som er lagt til, må ha navn. Dose og tidspunkt er valgfrie. Tomme medisiner kan fjernes, og «Tilbake» gjør det mulig å rette opplysninger underveis og fra siste steg.
- Stedsbibliotek med forslagene Hjemme, Jobb og Skole og mulighet for egne steder. Listen kan endres under **Profil → Dine steder** uten å endre tidligere anfall.
- Registrering med tidspunkt, type og valgfri varighet. Sted velges i et alltid synlig **Hvor skjedde det?**-kort, ikke under ekstra detaljer.
- Ett valgfritt sted per anfall, uten automatisk valg. Nye steder legges til i biblioteket når anfallet lagres. Inne-/utemiljø velges separat for hvert anfall, uten GPS.
- Mulige triggere og andre valgfrie opplysninger under ekstra detaljer.
- Anfallshistorikk med redigering, sletting og varige medisinøyeblikksbilder.
- Dashboard for 7, 30 eller 90 dager, egendefinerte datoperioder, datofiltrering, mulige triggere og ukjente varigheter.
- Lokal JSON-eksport, inkludert lagrede steder, og sletting av profil, medisiner og logg.

## Personvern

Appen oppretter ingen konto og sender ikke opplysninger til en server. Data lagres lokalt med Apples SwiftData. Lokale appdata kan være en del av iPhone-sikkerhetskopien, avhengig av Apples sikkerhetskopiinnstillinger. JSON-filen brukeren eksporterer, er ikke kryptert av appen og bør deles og lagres med forsiktighet. Hvis appen avinstalleres eller enheten mister data uten sikkerhetskopi, kan lokale opplysninger gå tapt.

## Før offentlig lansering

Medisinske begreper og symptomlister er ment som nøytrale valg i en personlig logg, ikke råd eller anbefalinger. Gjennomgå tekster med kvalifisert helsepersonell, test tilgjengelighet og personvern på faktiske enheter, og verifiser personvern- og distribusjonskrav før innsending til App Store.
