# APD Quest (Godot 4) — vertical slice

Przyjazna przygoda 3D: dziewczynka zwiedza **Polanę Echo** i wykonuje **questy słuchowe** oparte o ćwiczenia z web app Trening APD (`cwiczenia_apd`).

To **trening wspomagający** (nie diagnostyka). Szum w grze to **względny poziom trudności**, nie kliniczny SNR.

## Wymagania

- **Godot 4.3+** (testowane na **4.7.2** Forward+), Windows OK.
- Opcjonalnie: polski głos SAPI / systemowy TTS (lepsze odsłuchy; bez TTS gra pokazuje krótki podgląd tekstu).

## Jak uruchomić (Dariusz) — F5

1. Zaktualizuj repo `cwiczenia_apd` i checkout brancha PR (lub `main` po merge).
2. Uruchom **Godot 4** → **Import** / **Open** → folder `apd-quest-godot/` (`project.godot`).
3. Poczekaj na import (pierwszy raz tworzy `.godot/` lokalnie).
4. Naciśnij **F5** (Play Project).
5. Na polanie:
   - **WASD** / strzałki — ruch
   - **PPM + mysz** — obrót kamery (Esc zwalnia kursor)
   - Podejdź do **Echo** (niebieski) lub **Burza** (fiolet) → **E**
   - Dialog → **Zaczynam!** → mini-gra słuchowa
   - Przełącznik **Szum** w overlay (względny poziom)
   - Po sukcesie: punkty w HUD + dialog podziękowania

### Questy w slice

| NPC | Quest | Mechanika |
|-----|-------|-----------|
| Echo | Zaklęcie Echo | Sekwencja słów → tap w kolejności |
| Burza | Wiadomość w burzy | Odsłuch zdania → wybór MC |

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
