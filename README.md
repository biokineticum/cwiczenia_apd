# Trening APD - Aplikacja do Treningu Zaburzeń Przetwarzania Słuchowego

🎧 **Profesjonalna aplikacja React do terapii i diagnozy zaburzeń przetwarzania słuchowego (APD)**

## 🌟 Funkcjonalności

### 🔊 Zaawansowany System Audio

* **4 typy szumów tła**: Biały, Różowy, Brązowy, Babble Noise
* **Dwukanałowe stereo** z Web Audio API
* **Precyzyjna kontrola SNR** (Signal-to-Noise Ratio) od -20dB do +30dB
* **Prawdziwe mieszanie sygnałów audio** w czasie rzeczywistym

### 🎯 Moduły Treningowe

#### 1. **Mowa w Szumie** 📢

* 80+ zróżnicowanych zdań (życie codzienne, szkoła, przyroda, emocje)
* Adaptacyjny algorytm trudności
* Wybór typu szumu dla każdego modułu osobno
* System oceny słowo po słowie

#### 2. **Rozpoznawanie Dźwięków** 🔍

* 8 różnych dźwięków środowiskowych
* Graficzne reprezentacje (emoji)
* Trening w szumie tła
* System wielokrotnego wyboru

#### 3. **Lateralizacja** 🎚️

* **Tryb prosty**: rozpoznawanie ucha (L/R)
* **Tryb sekwencji cyfr**: zapamiętywanie i powtarzanie sekwencji
* Alternating L-R panning z Web Audio API
* Szum w tle podczas sekwencji
* Regulowana długość sekwencji (3-7 cyfr)

#### 4. **Audio + Motor** 🏃‍♂️

* 10 poleceń ruchowych
* Integracja słuchu z ruchem
* Trening koordynacji audio-motorycznej
* System weryfikacji przez terapeutę

### 📊 Panel Terapeuty

* **Zaawansowane statystyki** dla każdego modułu
* **Monitoring w czasie rzeczywistym**
* **Historia sesji** z dokładnymi metrykami
* **Eksport danych** do analizy
* **Kontrola parametrów** treningu

### ⚙️ Kalibracja i Ustawienia

* **Kalibracja głośności** na początku sesji
* **Globalny suwak SNR** z podglądem na żywo
* **Wybór szumu** indywidualnie dla każdego modułu
* **Timer sesji** z monitoringiem zmęczenia
* **Poziom zmęczenia** (1-10) z wpływem na algorytm

## 🚀 Technologie

* **React 18** z hookami
* **Web Audio API** - zaawansowane przetwarzanie audio
* **Tailwind CSS** - responsywny design
* **Real-time audio processing** - dwukanałowe mieszanie sygnałów
* **Adaptive algorithms** - automatyczna regulacja trudności

## 📦 Instalacja

```bash
# Klonowanie repozytorium
git clone [url-repozytorium]
cd trening-apd

# Instalacja zależności
npm install

# Uruchomienie w trybie development
npm start

# Build produkcyjny
npm run build
```

## 🎮 Użytkowanie

### Dla Pacjenta

1. **Kalibracja**: Ustaw komfortową głośność
2. **Wybór modułu**: Rozpocznij od modułu podstawowego
3. **Trening**: Wykonuj zadania zgodnie z instrukcjami
4. **Postęp**: Obserwuj swoje wyniki w czasie rzeczywistym

### Dla Terapeuty

1. **Panel terapeuty**: Włącz zaawansowane statystyki
2. **Monitorowanie**: Śledź postępy pacjenta na żywo
3. **Analiza**: Eksportuj dane do dalszej analizy
4. **Dostosowanie**: Modyfikuj parametry według potrzeb

## 🔧 Konfiguracja Audio

### Szumy Tła

* **Biały szum**: Pełne spektrum częstotliwości
* **Różowy szum**: Więcej niskich częstotliwości (naturalny)
* **Brązowy szum**: Dominacja bardzo niskich częstotliwości
* **Babble Noise**: Symulacja rozmów w tle

### SNR (Signal-to-Noise Ratio)

* **Zakres**: -20dB do +30dB
* **Adaptacyjne**: Automatyczne dostosowanie na podstawie wyników
* **Manualne**: Ręczne ustawienie przez terapeutę

## 📈 Algorytm Adaptacyjny

```javascript
// Logika adaptacji trudności
if (correctAnswer) {
    correctStreak++;
    if (correctStreak >= 2) {
        SNR -= stepSize; // Zwiększ trudność
        correctStreak = 0;
    }
} else {
    SNR += stepSize; // Zmniejsz trudność
    correctStreak = 0;
}
```

## 🎯 Wskaźniki Jakości

### Metryki dla Terapeuty

* **Accuracy**: Procent poprawnych odpowiedzi
* **Response Time**: Średni czas reakcji
* **SNR Progression**: Postęp w poziomie trudności
* **Fatigue Impact**: Wpływ zmęczenia na wyniki
* **Session Duration**: Długość efektywnego treningu

## 🔒 Zgodność i Bezpieczeństwo

* **GDPR Compliant**: Ochrona danych osobowych
* **Audiological Standards**: Zgodność z normami audiologicznymi
* **Safe Volume Levels**: Automatyczna ochrona słuchu
* **Session Monitoring**: Kontrola czasu ekspozycji

## 🌐 Kompatybilność

* **Browsers**: Chrome 80+, Firefox 75+, Safari 13+, Edge 80+
* **Devices**: Desktop, tablet, smartphone
* **Audio**: Słuchawki stereo wymagane dla pełnej funkcjonalności
* **OS**: Windows, macOS, Linux, iOS, Android

## 📱 Responsive Design

Aplikacja automatycznie dostosowuje się do różnych rozmiarów ekranów:

* **Desktop**: Pełny panel terapeuty + moduły
* **Tablet**: Zoptymalizowany interfejs dotykowy
* **Mobile**: Podstawowe funkcje treningowe

## 🤝 Wkład w Projekt

1. Fork repozytorium
2. Utwórz branch funkcjonalności (`git checkout -b feature/AmazingFeature`)
3. Commit zmiany (`git commit -m 'Add some AmazingFeature'`)
4. Push do brancha (`git push origin feature/AmazingFeature`)
5. Otwórz Pull Request

## 📄 Licencja

**Copyright © 2025 Biokineticum Dariusz Mosler. Wszelkie prawa zastrzeżone.**

Ten projekt jest chroniony prawami autorskimi - szczegóły w pliku `LICENSE.md`

Dla licencji komercyjnych i akademickich skontaktuj się z autorem.

## 👨‍⚕️ Dla Specjalistów

**Trening APD** został zaprojektowany we współpracy z audiologami i terapeutami mowy. Aplikacja implementuje sprawdzone metody terapeutyczne dla zaburzeń przetwarzania słuchowego.

### Zastosowania Kliniczne:

* **Diagnostyka**: Ocena zdolności przetwarzania słuchowego
* **Terapia**: Systematyczny trening umiejętności słuchowych
* **Monitoring**: Śledzenie postępów w terapii
* **Badania**: Zbieranie danych do badań naukowych

## 📞 Wsparcie

* **Email**: <biokineticum@proton.me>


***

**🎧 Pomóż dzieciom i dorosłym rozwijać umiejętności słuchowe z zaawansowaną technologią audio!**

*Aplikacja została przetestowana przez certyfikowanych audiologów i terapeutów mowy.*
