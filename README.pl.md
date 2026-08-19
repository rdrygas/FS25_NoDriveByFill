# FS25 No Drive-By Fill

### Opis

FS25_NoDriveByFill wyłącza napełnianie z bliska ("zdalne") materiałami sypkimi
dla pojazdów i maszyn sterowanych przez gracza.

W podstawowej grze wiele maszyn można napełnić po prostu przez podjechanie do
odpowiedniego big-baga, worka na palecie lub podobnego źródła i użycie klawisza
napełniania. Mod usuwa ten skrót dla materiałów sypkich. Materiał trzeba
fizycznie dostarczyć do zbiornika, np. podnosząc worek ładowarką albo
wysypując go do otwartego siewnika, rozsiewacza, przyczepy lub wozu
przeładunkowego.

Napełnianie materiałami ciekłymi celowo pozostaje bez zmian.

### Przyjęte założenia

Mod działa według następujących zasad:

- obejmuje tylko sprzęt należący do zestawu aktualnie sterowanego przez gracza;
- nie zmienia zachowania sprzętu sterowanego przez AI;
- działa na wszystkich typach pojazdów korzystających ze specjalizacji
  `FillUnit`, zamiast polegać na kategoriach sklepowych takich jak `trailers`,
  `trailersSemi` czy `augerWagons`;
- blokuje materiały sypkie;
- pozostawia bez zmian materiały ciekłe;
- nie blokuje fizycznego wsypywania lub wysypywania materiału do zbiornika;
- pozostawia działanie normalnych silosów i stacji załadunkowych, jeżeli
  korzystają z mechanizmu stacji załadunkowej, a nie blokowanego napełniania
  z bliska;
- pozostawia ręczne sterowanie pokrywą.

### Sposób działania

Mod jest globalną specjalizacją pojazdu.

`NoDriveByFillInit.lua` dodaje specjalizację do każdego zarejestrowanego typu
pojazdu posiadającego `FillUnit`. Następnie `NoDriveByFill.lua` sprawdza typ
materiału udostępniany przez aktualnie wybrane pobliskie źródło.

Dla materiałów zablokowanych mod:

1. nie pozwala aktywować pobliskiego triggera napełniania;
2. blokuje uruchomienie napełniania przez `setFillUnitIsFilling(true)`;
3. usuwa aktywator napełniania, dzięki czemu nie pojawia się podpowiedź `R`;
4. nie pozwala automatycznie otworzyć pokrywy z powodu zablokowanego źródła.

Standardowy mechanizm zmiany poziomu napełnienia i wysypywania nie jest
podmieniany, dlatego materiał nadal można fizycznie wsypywać do maszyny.

### Blokowane materiały

Mod rozpoznaje jawnie najczęściej używane materiały sypkie, m.in.:

- nasiona, nawóz stały i wapno;
- sól drogową;
- pszenicę, jęczmień, owies, rzepak, słonecznik, soję, kukurydzę i sorgo;
- ziemniaki, buraki cukrowe, trzcinę cukrową i obsługiwane warzywa;
- karmę dla świń, pasze, trawę, siano, słomę, kiszonkę, sieczkę i dodatki
  mineralne;
- zrębki drzewne i obornik.

Dodatkowo automatycznie blokowane są kompatybilne fillType należące do
kategorii `BULK`. Ułatwia to współpracę z mapami i modami dodającymi własne
materiały sypkie.

Znane materiały ciekłe oraz kategorie `LIQUID`, `SPRAYER` i `SLURRYTANK` są
wyłączone z blokady.

### Tabela działania

| Sytuacja | Działanie |
|---|---|
| Siewnik obok worka/palety z nasionami | Napełnianie z bliska zablokowane |
| Rozsiewacz obok nawozu stałego | Napełnianie z bliska zablokowane |
| Rozsiewacz wapna obok wapna | Napełnianie z bliska zablokowane |
| Rozsiewacz soli obok soli drogowej | Napełnianie z bliska zablokowane |
| Przyczepa/naczepa obok kompatybilnego materiału sypkiego | Napełnianie z bliska zablokowane |
| Wóz przeładunkowy obok kompatybilnego materiału sypkiego | Napełnianie z bliska zablokowane |
| Podpowiedź `R` dla zablokowanego źródła | Ukryta |
| Automatyczne otwieranie pokrywy przy zablokowanym źródle | Wyłączone |
| Ręczne otwieranie/zamykanie pokrywy | Działa |
| Wsypywanie worka podniesionego ładowarką | Działa |
| Wsypywanie łyżką lub z innego źródła wysypującego | Działa |
| Napełnianie z kompatybilnego silosu/stacji | Działa |
| Nawóz ciekły, herbicyd, woda, paliwo i inne ciecze | Bez zmian |
| Sprzęt sterowany przez AI | Bez zmian |

### Konfiguracja

Mod nie ma menu konfiguracji w grze.

Zachowanie można zmienić bezpośrednio w pliku:

`FS25_NoDriveByFill/scripts/NoDriveByFill.lua`

Najważniejsze są dwie tablice:

- `NoDriveByFill.BLOCKED_FILL_TYPE_NAMES` — jawnie blokowane materiały sypkie;
- `NoDriveByFill.LIQUID_FILL_TYPE_NAMES` — jawnie dozwolone materiały ciekłe.

Pozostałe fillType należące do kategorii `BULK` są blokowane automatycznie.

Aby dodać własny materiał sypki, wpisz jego nazwę fillType:

```lua
CUSTOM_MATERIAL = true,
```

Aby jawnie zabezpieczyć dodatkową ciecz przed blokadą, dodaj ją analogicznie
do `LIQUID_FILL_TYPE_NAMES`.

### Instalacja

Skopiuj plik ZIP do:

`Documents/My Games/FarmingSimulator2025/mods`

Następnie włącz **No Drive-By Fill** podczas wczytywania zapisu gry.

### Wpisy w logu

Podczas uruchamiania mod zapisuje wpis podobny do:

```text
Info: [FS25_NoDriveByFill] Added specialization to 123 FillUnit vehicle types.
```

Przy zablokowaniu napełniania może pojawić się np.:

```text
Info: [FS25_NoDriveByFill] Blocked proximity filling: vehicle='...', fillType='WHEAT'
```

### Historia zmian

#### 1.0.0.0

- pierwsza wersja moda.

#### 1.0.1.0

- zastąpiono początkowe globalne nadpisywanie funkcji specjalizacją pojazdu;
- poprawiono przechwytywanie funkcji zarejestrowanych dla konkretnych typów
  pojazdów;
- uruchomiono właściwą blokadę napełniania z bliska nasionami, nawozem stałym
  i wapnem.

#### 1.0.2.0

- ukryto podpowiedź `R` dla zablokowanych źródeł;
- wyłączono automatyczne otwieranie pokrywy przy zablokowanych źródłach;
- zachowano ręczne sterowanie pokrywą.

#### 1.1.0.0

- rozszerzono działanie z siewników i rozsiewaczy na wszystkie typy pojazdów
  korzystające z `FillUnit`;
- dodano przyczepy, naczepy, wozy przeładunkowe i kompatybilny sprzęt z modów;
- dodano zboża, pasze, sól drogową i inne materiały sypkie;
- dodano automatyczną obsługę kategorii fillType `BULK`;
- zachowano bez zmian napełnianie cieczami.
