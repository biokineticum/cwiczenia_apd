# APD Quest (Godot 4)

Przyjazna przygoda 3D: dziewczynka zwiedza świat i wykonuje **questy słuchowe** oparte o ćwiczenia z web app Trening APD (`cwiczenia_apd`).

To **trening wspomagający** (nie diagnostyka). Szum w grze to **względny poziom trudności**, nie kliniczny SNR — dopóki nie ma wspólnego mixu + nagrań.

Architektura (Project store):  
`/cursor/stores/self/docs/architektura-gry-apd-godot.md`  
(w repozytorium kontekstu projektu Cursor; ścieżka lokalna agenta: docs w store projektu).

## Wymagania

- **Godot 4.3+** (4.x Forward+), zainstalowany na PC właściciela.
- Cloud / CI **nie** uruchamia edytora Godot (brak binarki w VM).

## Jak otworzyć na PC (Dariusz)

1. Sklonuj / zaktualizuj repo `cwiczenia_apd`.
2. Uruchom **Godot 4** → **Import** lub **Open**.
3. Wskaż folder `apd-quest-godot/` (plik `project.godot`).
4. Poczekaj na pierwszy import assetów.
5. Naciśnij **F5** (Play) — powinna wczytać się scena `scenes/main.tscn` (polana stub + gracz + NPC).
6. Sterowanie: **WASD** / strzałki, **E** = rozmowa z NPC.

Jeśli pojawią się ostrzeżenia o UID / brakujących `.godot/` — normalne przy pierwszym otwarciu z chmury; Godot wygeneruje cache lokalnie (folder `.godot/` jest w `.gitignore`).

## Co jest w szkielecie

| Element | Ścieżka |
|---------|---------|
| Główna scena | `scenes/main.tscn` |
| Gracz (placeholder) | `scenes/player/player_girl.tscn` |
| Świat stub | `scenes/world/world_stub.tscn` |
| NPC stub | `scenes/npc/npc_stub.tscn` |
| UI quest / dialog / listening | `scenes/ui/` |
| Manager questów | `scripts/quest/quest_manager.gd` |
| Hooki mini-gier słuchowych | `scripts/listening/` |
| Audio bus + szum | `scripts/audio/` |
| Dane ćwiczeń (JSON stub) | `data/` |

## Następne kroki (lokalnie w Godot)

1. Smoke test F5 + kolizje / kamera.
2. Podmienić capsule na model dziewczynki.
3. Dodać nagrania mowy / środowiska do `assets/audio/`.
4. Podpiąć pełną pulę słów/zdań z web `src/lib/exerciseData.js` → `data/`.
5. (Opcjonalnie) Self-hosted Cursor worker z Godotem na PATH do dalszej pracy agentów.

## Zastrzeżenie kliniczne

Ćwiczenia wspierają trening funkcji słuchowych pod opieką specjalisty. Gra **nie** stawia diagnozy APD / CAPD i nie obiecuje „naprawy” przetwarzania słuchowego.
