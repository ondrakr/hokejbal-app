# Hokejbal iOS

Livesport-stylová iOS aplikace pro český hokejbal ve vizuálním jazyku [hokejbal.cz](https://www.hokejbal.cz) (červená `#C92A2A`, bílé plochy, iOS TabBar / List / NavigationStack).

## Funkce

- **Živě** – probíhající zápasy s pollingem (mock simuluje góly každých ~8 s)
- **Zápasy** – program podle dne a soutěže
- **Tabulka** – pořadí Extraligy (data z webu)
- **Oblíbené** – týmy, hráči, sledované zápasy
- **Novinky** – články ve stylu hokejbal.cz
- **Notifikace** – nastavení + lokální demo při gólu
- **Připraveno na API** – protokol `HokejbalAPI` + `RemoteHokejbalAPI` (`https://api.hokejbal.cz/v1`)

## Spuštění

```bash
cd Hokejbal
xcodegen generate
open Hokejbal.xcodeproj
```

V Xcode:
1. Nahoře vyberte **simulátor** (např. iPhone 16) – ne „Any iOS Device“
2. Spusťte scheme **Hokejbal** (⌘R)

Projekt je nastavený bez povinného Apple ID pro simulátor (Debug signing vypnutý). Aplikace nemá žádné přihlašování – je volně přístupná.

Pro fyzické zařízení: v Xcode → Hokejbal target → Signing & Capabilities zapněte Automatic a vyberte svůj tým (jen pro instalaci na iPhone, ne pro uživatele aplikace).

Přepnutí mock ↔ remote API: **Novinky → ozubené kolo** nebo **Oblíbené → Nastavení**.

## Architektura napojení API

```
HokejbalAPI (protocol)
├── MockHokejbalAPI      ← výchozí, lokální data
└── RemoteHokejbalAPI    ← REST klient (připravený stub)
```

Endpointy remote klienta:

| Metoda | Cesta |
|--------|--------|
| GET | `/competitions` |
| GET | `/teams?competitionId=` |
| GET | `/players?teamId=` |
| GET | `/matches?…` |
| GET | `/matches/live?cursor=` |
| GET | `/matches/{id}` |
| GET | `/competitions/{id}/standings` |
| GET | `/news?limit=` |

Až bude oficiální ČMSHb API, upravte `RemoteHokejbalAPI.defaultBaseURL` a mapování JSON (snake_case + ISO8601 už je nastavené).

## Požadavky

- Xcode 15+
- iOS 17+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
