/**
 * ~200 common Polish words for auditory sequence training (kids / home practice).
 * Training support only — not a diagnostic word list.
 */

export const WORD_POOL = [
  // dom / rodzina
  'mama', 'tata', 'babcia', 'dziadek', 'dziecko', 'brat', 'siostra', 'rodzina', 'dom', 'pokój',
  'łóżko', 'okno', 'drzwi', 'stół', 'krzesło', 'lampa', 'kuchnia', 'łazienka', 'klucz', 'książka',
  // szkoła
  'szkoła', 'klasa', 'nauczyciel', 'uczeń', 'zeszyt', 'ołówek', 'kredka', 'tablica', 'plecak', 'piórnik',
  'lekcja', 'przerwa', 'zadanie', 'czytanie', 'pisanie', 'litera', 'cyfra', 'mapa', 'atlas', 'globus',
  // jedzenie
  'chleb', 'masło', 'ser', 'mleko', 'woda', 'sok', 'jabłko', 'gruszka', 'banan', 'truskawka',
  'zupa', 'obiad', 'śniadanie', 'kolacja', 'kanapka', 'jajko', 'ryż', 'makaron', 'ziemniak', 'marchew',
  'ogórek', 'pomidor', 'sałata', 'ciasto', 'cukierki', 'lody', 'herbata', 'kakao', 'jogurt', 'miód',
  // zwierzęta
  'pies', 'kot', 'koń', 'krowa', 'owca', 'koza', 'świnia', 'kura', 'kaczka', 'gęś',
  'ptak', 'ryba', 'mysz', 'królik', 'chomik', 'żółw', 'żaba', 'motyl', 'pszczoła', 'biedronka',
  // natura
  'słońce', 'księżyc', 'gwiazda', 'niebo', 'chmura', 'deszcz', 'śnieg', 'wiatr', 'burza', 'tęcza',
  'las', 'drzewo', 'liść', 'kwiat', 'trawa', 'rzeka', 'jezioro', 'morze', 'góra', 'pole',
  'kamyczek', 'piasek', 'ziemia', 'ogród', 'park', 'ścieżka', 'most', 'łąka', 'krzak', 'grzyb',
  // ciało / ubranie
  'głowa', 'oko', 'ucho', 'nos', 'usta', 'ręka', 'noga', 'stopa', 'palec', 'serce',
  'kurtka', 'spodnie', 'sukienka', 'buty', 'skarpetki', 'czapka', 'szalik', 'rękawiczki', 'pasek', 'koszula',
  // kolory / liczby / przymiotniki proste
  'czerwony', 'niebieski', 'zielony', 'żółty', 'biały', 'czarny', 'różowy', 'brązowy', 'szary', 'fioletowy',
  'duży', 'mały', 'długi', 'krótki', 'ciepły', 'zimny', 'mokry', 'suchy', 'szybki', 'wolny',
  'jeden', 'dwa', 'trzy', 'cztery', 'pięć', 'sześć', 'siedem', 'osiem', 'dziewięć', 'dziesięć',
  // czynności / przedmioty codzienne
  'biegać', 'skakać', 'śpiewać', 'tańczyć', 'rysować', 'malować', 'czytać', 'pisać', 'słuchać', 'patrzeć',
  'jeść', 'pić', 'spać', 'budzić', 'myć', 'czesać', 'ubierać', 'otwierać', 'zamykać', 'nosić',
  'piłka', 'lalka', 'auto', 'rower', 'hulajnoga', 'klocki', 'puzzle', 'miś', 'balon', 'latawiec',
  'telefon', 'komputer', 'telewizor', 'radio', 'zegar', 'budzik', 'lustro', 'ręcznik', 'mydło', 'szczotka',
  // miejsca / pogoda / czas
  'sklep', 'apteka', 'poczta', 'kino', 'basen', 'boisko', 'plac', 'ulica', 'miasto', 'wieś',
  'rano', 'wieczór', 'noc', 'dzień', 'tydzień', 'miesiąc', 'rok', 'dziś', 'jutro', 'wczoraj',
];

export const WORD_SEQUENCE_LENGTHS = [3, 4, 5];

/** Pick `length` unique random words from the pool. */
export function pickWordSequence(length = 3, pool = WORD_POOL) {
  const n = Math.min(Math.max(3, length), 5, pool.length);
  const copy = [...pool];
  for (let i = copy.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy.slice(0, n);
}

export function randomSequenceLength(lengths = WORD_SEQUENCE_LENGTHS) {
  return lengths[Math.floor(Math.random() * lengths.length)];
}
