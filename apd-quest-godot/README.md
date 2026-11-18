# APD Quest (Godot 4) — vertical slice (UX ~5 lat, bez czytania)

Przyjazna przygoda 3D: dziewczynka zwiedza **Polanę Echo** i wykonuje **questy słuchowe**.

To **trening wspomagający** (nie diagnostyka). Szum = **względny poziom trudności**, nie kliniczny SNR.

**Dziecko (~5 lat, nie czyta):** odpowiedzi = **ikony / obrazki** (tap). Tekst bodźca i szum → **tryb rodzica** (przytrzymaj ikonę dorosłego ~1,5 s).

## Wymagania

- **Godot 4.3+** (testowane na **4.7.2** Forward+), Windows OK. Preferuj wersję **standard** (nie .NET/mono).
- Polski TTS (SAPI) zalecany do odsłuchu; bez TTS dziecko i tak nie dostaje napisów — tylko ikona ucha.

## Jak uruchomić — `run.bat` (zalecane)

Bez otwierania edytora Godot:

1. `git pull` w repo `cwiczenia_apd` (branch `main`).
2. Dwukliknij **`apd-quest-godot/run.bat`**  
   albo z roota repo: **`run-apd-quest.bat`**.
3. Skrypt sam szuka Godota (PATH, Downloads, typowe foldery) i odpala grę:  
   `Godot_*.exe --path <ten-folder>`.
4. Jeśli Godot nie jest zainstalowany — bat wypisze jasny komunikat.

Na polanie: **WASD**, **PPM+mysz**, **E** przy Echo / Burza → **Zaczynam!**  
Mini-gra: duże kafelki-ikony; **ucho** = odsłuchaj; **strzałka wstecz** = cofnij; **długie przytrzymanie ikony rodzica** = tekst + szum.

### Edytor (opcjonalnie, F5)

1. Godot 4 → **Import** / **Open** → dokładnie folder **`apd-quest-godot/`** (nazwa projektu: **APD Quest**).
2. **F5**.

**Uwaga:** nie twórz / nie otwieraj zagnieżdżonych pustych projektów w środku (`apd/`, `apd-gra/` itd.).  
One nie mają `run/main_scene` → błąd *"Can't run project: no main scene defined"* i gra „się nie uruchamia”.

### Questy

| NPC | Quest | Mechanika (dziecko) |
|-----|-------|---------------------|
| Echo | Zaklęcie Echo | Sekwencja 2–3 → **tap ikon w kolejności** |
| Burza | Wiadomość w burzy | Odsłuch → **wskaż obrazek** (2–4) |

## Smoke test (headless)

```text
godot --path apd-quest-godot --headless -s res://scripts/smoke_test.gd
```

## Wygląd (bajkowy art pass)

Polana, postacie i rekwizyty są **proceduralnymi mesh’ami** (sukienki, włosy, twarze, chatka, drzewa, kwiaty, ścieżka, mgła, iskierki) — bez zewnętrznych paczek 3D w tym PR.  
Kolorystyka: ciepłe niebo / lawendowy fog, czytelne sylwetki dla dzieci.  
Później można podmienić na modele CC0 (np. Kenney Nature Kit) — attribution w README przy dodaniu plików.

| Element | Ścieżka |
|---------|---------|
| Budowa polany | `scripts/art/fairy_clearing_builder.gd` |
| Postacie stylizowane | `scripts/art/stylized_character_builder.gd` |
| Fabryka mesh/materiałów | `scripts/art/mesh_factory.gd` |

## Co jest w projekcie

| Element | Ścieżka |
|---------|---------|
| Główna scena | `scenes/main.tscn` |
| Polana | `scenes/world/world_stub.tscn` |
| Gracz | `scenes/player/player_girl.tscn` |
| NPC | `scenes/npc/npc_stub.tscn` |
| UI | `scenes/ui/` |
| Mini-gry | `scripts/listening/` |
| Szum proceduralny | `scripts/audio/noise_player.gd` |
| Dane | `data/*.json` |

## Zastrzeżenie kliniczne

Ćwiczenia wspierają trening funkcji słuchowych pod opieką specjalisty. Gra **nie** stawia diagnozy APD / CAPD i nie obiecuje „naprawy” przetwarzania słuchowego.
