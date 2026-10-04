# EpiLogg: TestFlight- og App Store-lansering

**Dato:** 3. oktober 2026  
**Status:** Klar for gjennomgang  
**Produktnavn:** EpiLogg  
**Første distribusjonsmål:** Ekstern TestFlight-beta  
**Senere distribusjonsmål:** Norsk App Store

## Mål

Klargjøre dagens lokale iPhone-app for en trygg ekstern TestFlight-beta uten å endre kjernefunksjonaliteten. Resultatene fra betatesten brukes som en egen beslutningsport før App Store-innsending.

Arbeidet skal:

- gi EpiLogg en ferdig visuell identitet og et produksjonsklart appikon;
- etablere nødvendig personvern-, support- og butikkmateriell;
- produsere et signert og validert Release-arkiv;
- gjøre en ekstern TestFlight-beta tilgjengelig for en begrenset testgruppe;
- bevare iOS 17 som minimumsversjon, men bygge med iOS 26 SDK eller nyere;
- unngå påstander om diagnostikk, behandling, anfallsdeteksjon eller medisinsk rådgivning.

Arbeidet skal ikke:

- innføre konto, server, analyseverktøy, reklame eller tredjeparts-SDK-er;
- sende helseopplysninger av enheten;
- publisere automatisk i App Store;
- endre lagringsmodell eller brukerflyter uten at betatesting avdekker et konkret behov.

## Faseinndeling og godkjenningsporter

### Fase 1: Ekstern TestFlight-beta

Fase 1 omfatter visuell identitet, personvern og support, Release-konfigurasjon, enhetskontroll, arkivering, opplasting til App Store Connect og ekstern TestFlight-distribusjon.

TestFlight-bygget skal ikke gjøres tilgjengelig før:

1. produksjonsikonet er godkjent i appen;
2. personvern- og supportlenker er offentlige;
3. Release-arkivet er validert av Xcode;
4. alle automatiserte tester består;
5. en fysisk iPhone-test er gjennomført;
6. TestFlight-metadata og Beta App Review-notater er kontrollert.

### Fase 2: App Store-innsending

Fase 2 starter først etter en eksplisitt beslutning basert på betafeil, tilbakemeldinger og juridisk avklaring. Den omfatter endelig butikktekst, skjermbilder, aldersvurdering, tilgjengelighetserklæringer, App Privacy-svar, Review-notater og manuell innsending.

Godkjent bygg skal publiseres manuelt, ikke automatisk.

## Visuell identitet

### Godkjent retning

Den godkjente identiteten er **C2 – Bokmerket**:

- mørk blågrønn, avrundet bakgrunn;
- en åpen bok i lyse, rolige flater;
- et varmt ferskenfarget bokmerke;
- diskrete grønne tekstlinjer;
- ordmerket `EpiLogg` i et avrundet, tydelig uttrykk.

Symbolet skal kommunisere personlig logg og historikk. Det skal ikke bruke medisinsk kors, hjerneillustrasjon, alarm, sensor eller pulsgrafikk som kan antyde overvåking eller medisinsk måling.

### Produksjonsleveranser

- lagdelt Icon Composer-kilde for standard, mørk og tonet visning;
- appikon konfigurert i Xcode;
- flat 1024 × 1024 markedsføringsfil uten innbakte avrundede hjørner;
- vektororiginal for symbolet;
- horisontalt ordmerke med og uten undertittel;
- eksporterte PNG-er for supportside og TestFlight-materiell.

Ikonet skal kontrolleres ved 32, 48, 60 og 1024 piksler, på lys og mørk hjemmeskjerm, og med iOS-toning. Små detaljer skal fjernes dersom de mister lesbarhet.

## Produkt- og byggeklarering

Første betaversjon settes til:

- markedsversjon: `1.0.0`;
- første opplastede build: `1`;
- bundle ID: `no.epilogg.app`;
- minimumssystem: iOS 17;
- målplattform: iPhone;
- distribusjon: gratis beta uten kjøp eller abonnement.

Hvert nytt TestFlight-bygg øker buildnummeret. Markedsversjonen endres bare når en ny versjonslinje opprettes.

Release-konfigurasjonen skal bruke riktig Apple Developer-team, automatisk eller eksplisitt App Store-signering og et gyldig distribusjonssertifikat. Arkivet skal bygges med en stabil Xcode-versjon og iOS 26 SDK eller nyere.

## Personvern, sikkerhet og support

### Offentlig nettsted og kontakt

Personvern- og supportinnhold publiseres som et statisk nettsted på Vercel uten analyseverktøy, informasjonskapsler, sporingsskript eller eksterne runtime-avhengigheter. De permanente adressene er:

- `https://epilogg.haugentech.no/personvern`;
- `https://epilogg.haugentech.no/support`;
- `epilogg@haugentech.no` for support og personvernspørsmål.

Vercel-prosjektet skal publisere bare innholdet i `Site/`. DNS for `epilogg.haugentech.no`, Vercel-tilkoblingen og e-postkontoen administreres manuelt uten at tokens eller innloggingsopplysninger lagres i kildekoden.

### Personvernerklæring

En offentlig personvernerklæring skal forklare:

- at appen ikke oppretter konto;
- at profil-, medisin-, steds- og anfallsopplysninger lagres lokalt;
- at utvikleren ikke mottar disse opplysningene;
- at lokale data kan inngå i brukerens Apple-sikkerhetskopi;
- hvordan alle appdata slettes;
- at eksportert JSON ikke krypteres av EpiLogg;
- at supporthenvendelser behandles separat fra appdata;
- kontaktinformasjon og dato for siste oppdatering.

Lenken skal finnes både i App Store Connect og lett tilgjengelig under Profil i appen.

### Supportside

Supportsiden skal inneholde:

- kontaktadresse;
- kort brukerveiledning;
- informasjon om eksport og sletting;
- tydelig avgrensning mot medisinsk rådgivning;
- anbefaling om å kontakte helsepersonell ved medisinske spørsmål og lokale nødtjenester i en akuttsituasjon;
- lenke til personvernerklæringen.

### App Privacy

Med dagens arkitektur er planlagt App Privacy-svar **Data Not Collected**, fordi appen ikke overfører data til utvikleren eller tredjepart. Svaret må vurderes på nytt dersom analyse, krasjrapportering, skytjenester, support-SDK eller andre eksterne komponenter legges til.

Det eksisterende personvernmanifestet skal kontrolleres mot ferdig binær og Xcodes arkivrapport. Ingen nye tillatelser skal legges til uten et faktisk funksjonsbehov.

## Helsekommunikasjon og App Review

EpiLogg skal beskrives som en personlig anfallsdagbok for brukerens egne observasjoner. Metadata, skjermbilder og Review-notater skal konsekvent si at appen:

- ikke diagnostiserer epilepsi;
- ikke oppdager eller varsler om anfall;
- ikke gir behandlings- eller doseringsråd;
- ikke varsler helsepersonell eller pårørende;
- viser beskrivende statistikk basert på det brukeren selv har registrert.

App Review-notatene skal forklare at ingen innlogging kreves, at alle felt er valgfrie, og at testeren kan opprette og slette fiktive registreringer.

Før App Store-innsending skal Apple Developer Support kontaktes med en presis beskrivelse av den offline, ikke-diagnostiske dagboken. Målet er å avklare om Guideline 5.1.1(ix) krever organisasjonskonto. Hvis Apple krever juridisk enhet, stoppes App Store-fasen til kontoen er konvertert eller appen overføres til en kvalifisert organisasjon. TestFlight brukes ikke til å omgå denne avklaringen.

## TestFlight-oppsett

App Store Connect-posten opprettes med norsk som primærspråk og `EpiLogg` som navn, forutsatt at navnet er tilgjengelig ved opprettelse.

Ekstern betagruppe skal starte med et lite antall inviterte voksne testere. TestFlight-materialet skal inneholde:

- betabeskrivelse;
- hva som skal testes;
- kjent begrensning om lokal lagring og manglende skysynkronisering;
- feedback-e-post;
- kontaktinformasjon for Beta App Review;
- Review-notater med trinn for onboarding, logging, statistikk, eksport og sletting.

Testerne skal eksplisitt bes om å bruke fiktive opplysninger. Første betarunde skal undersøke:

- installasjon og første oppstart;
- onboarding med og uten medisiner;
- registrering, redigering og sletting av anfall;
- lagrede steder og triggere;
- statistikk og egendefinerte perioder;
- JSON-eksport;
- sletting av alle data;
- stor tekst, VoiceOver og mørk/tonet appikonvisning;
- oppgradering mellom to TestFlight-build uten datatap.

## App Store-materiell

Fase 2 bruker norsk metadata og fiktive helseopplysninger.

Planlagt skjermbildeserie:

1. oversikt med utvikling over tid;
2. rask registrering av anfall;
3. sted, miljø og valgfrie detaljer;
4. historikk og redigering;
5. profil, medisiner og lokale personvernvalg.

Skjermbildene skal bruke samme enhet, typografi og datahistorie. De skal ikke inneholde påstander om årsakssammenheng eller medisinsk effekt.

Butikkteksten skal fokusere på:

- enkel personlig registrering;
- valgfrie helseopplysninger;
- beskrivende oversikt over egne logger;
- lokal lagring uten konto;
- eksport og full sletting.

App Preview-video og flere lokaliseringer er utenfor første lansering.

## Verifikasjon

### Automatisert

- full enhets- og UI-testsuite;
- Release-build for simulator og fysisk enhet der det er relevant;
- validering av prosjektfil, Info.plist og personvernmanifest;
- arkiv- og App Store-validering i Xcode;
- kontroll av at appikonet finnes i den arkiverte appen;
- kontroll av versjon og buildnummer.

### Manuell

- installasjon på fysisk iPhone med ren appdata;
- oppgradering fra gjeldende utviklingsbygg;
- tvungen avslutning og ny oppstart;
- eksport og åpning av JSON;
- sletting og ny onboarding;
- VoiceOver, stor tekst og redusert bevegelse;
- kontroll uten nettverk;
- kontroll av personvern- og supportlenker;
- minst én full TestFlight-runde før App Store-fasen.

## Feilhåndtering og tilbakeføring

- Et mislykket bygg får aldri gjenbrukt buildnummer.
- TestFlight-distribusjon pauses dersom en feil kan gi datatap eller uriktig helsekommunikasjon.
- Oppdateringer av SwiftData-modellen krever egen migrasjonstest før ny beta.
- App Store-innsending stoppes dersom personvernsvaret, kontotype eller Review-notater er uavklart.
- Brukeren beholder eksplisitt kontroll over sletting og eksport; lanseringsarbeidet skal ikke introdusere skjult telemetri.

## Ferdigkriterier

Fase 1 er ferdig når et signert og validert `1.0.0`-bygg er godkjent for ekstern TestFlight, offentlige personvern- og supportsider er tilgjengelige, produksjonsikonet er integrert, og den definerte beta-testlisten er gjennomført uten åpne feil som innebærer datatap eller blokkert kjerneflyt.

Fase 2 er ferdig når Apple-kontokravet er avklart, endelig metadata og skjermbilder er godkjent, App Privacy er publisert, et betatestet bygg er sendt til App Review, og en godkjent versjon er klar for manuell publisering.
