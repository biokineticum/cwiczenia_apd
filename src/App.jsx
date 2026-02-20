import React, { useState, useEffect, useRef, useCallback } from 'react';
import Navbar from './components/Navbar';
import SEOContent from './components/SEOContent';
import PrivacyPolicy from './components/PrivacyPolicy';
import CookiesBanner from './components/CookiesBanner';
import Footer from './components/Footer';

// Ikony SVG
const Timer = () => <svg width="16" height="16" fill="currentColor" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" /><polyline points="12,6 12,12 16,14" /></svg>;
const Download = () => <svg width="16" height="16" fill="currentColor" viewBox="0 0 24 24"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" /><polyline points="7,10 12,15 17,10" /><line x1="12" y1="15" x2="12" y2="3" /></svg>;
const Mic = () => <svg width="16" height="16" fill="currentColor" viewBox="0 0 24 24"><path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z" /><path d="M19 10v2a7 7 0 0 1-14 0v-2" /><line x1="12" y1="19" x2="12" y2="23" /><line x1="8" y1="23" x2="16" y2="23" /></svg>;
const Volume2 = () => <svg width="16" height="16" fill="currentColor" viewBox="0 0 24 24"><path d="M11 5L6 9H2v6h4l5 4V5z" /><path d="M19.07 4.93a10 10 0 0 1 0 14.14M15.54 8.46a5 5 0 0 1 0 7.07" /></svg>;
const Headphones = () => <svg width="16" height="16" fill="currentColor" viewBox="0 0 24 24"><path d="M3 18v-6a9 9 0 0 1 18 0v6" /><path d="M21 19a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3z" /><path d="M3 19a2 2 0 0 0 2 2h1a2 2 0 0 0 2-2v-3a2 2 0 0 0-2-2H3z" /></svg>;
const Target = () => <svg width="16" height="16" fill="currentColor" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" /><circle cx="12" cy="12" r="6" /><circle cx="12" cy="12" r="2" /></svg>;
const BarChart3 = () => <svg width="16" height="16" fill="currentColor" viewBox="0 0 24 24"><path d="M3 3v18h18" /><path d="M18 17V9" /><path d="M13 17V5" /><path d="M8 17v-3" /></svg>;
const Settings = () => <svg width="16" height="16" fill="currentColor" viewBox="0 0 24 24"><circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1 1.51V5a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82v.07a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z" /></svg>;
const Info = () => <svg width="16" height="16" fill="currentColor" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" /><line x1="12" y1="16" x2="12" y2="12" /><line x1="12" y1="8" x2="12.01" y2="8" /></svg>;

function TreningAPD() {
    // Stan główny
    const [currentView, setCurrentView] = useState('home'); // 'home' or 'privacy'
    const [currentModule, setCurrentModule] = useState('speechInNoise');
    const [sessionTime, setSessionTime] = useState(0);
    const [fatigueLevel, setFatigueLevel] = useState(0);
    const [showParentPanel, setShowParentPanel] = useState(false);
    const [volumeCalibrated, setVolumeCalibrated] = useState(false);
    const [manualSNR, setManualSNR] = useState(10);
    const [useManualSNR, setUseManualSNR] = useState(false);

    // Adaptacyjna kontrola trudności
    const [adaptiveState, setAdaptiveState] = useState({
        correctStreak: 0,
        reversals: 0,
        currentSNR: 10,
        stepSize: 2,
        history: []
    });

    // Moduł: Mowa w szumie
    const [speechInNoiseState, setSpeechInNoiseState] = useState({
        currentSentence: '',
        sentenceWords: [],
        noiseType: 'white',
        userInput: ''
    });

    // Moduł: Rozpoznawanie dźwięków
    const [soundRecognitionState, setSoundRecognitionState] = useState({
        options: [],
        correctSound: '',
        noiseType: 'white',
        soundsLibrary: [
            { name: 'Pies szczeka', sound: 'hau hau hau', image: '🐕' },
            { name: 'Kot miauczy', sound: 'miau miau miau', image: '🐱' },
            { name: 'Krowa robi', sound: 'muuu muuu', image: '🐄' },
            { name: 'Samochód jedzie', sound: 'wruum wruum wruum', image: '🚗' },
            { name: 'Deszcz pada', sound: 'kap kap kap kap', image: '🌧️' },
            { name: 'Ptaki śpiewają', sound: 'ćwir ćwir ćwir', image: '🐦' },
            { name: 'Dzwonek dzwoni', sound: 'dzyń dzyń dzyń', image: '🔔' },
            { name: 'Bęben bije', sound: 'bum bum bum bum', image: '🥁' }
        ]
    });

    // Lateralizacja - ROZBUDOWANA o sekwencje cyfr
    const [lateralizationState, setLateralizationState] = useState({
        mode: 'simple',
        currentEar: '',
        panningValue: 0,
        digitSequence: [],
        userDigitSequence: [],
        sequenceLength: 3,
        currentDigitIndex: 0
    });

    // Audio + Motor
    const [audioMotorState, setAudioMotorState] = useState({
        currentCommand: '',
        commands: [
            'Klaśnij jeden raz',
            'Tupnij dwa razy',
            'Podnieś prawą rękę',
            'Dotknij nosa',
            'Klaśnij dwa razy i tupnij',
            'Podnieś lewą nogę',
            'Dotknij prawego ucha',
            'Zrób krok w przód',
            'Podnieś obie ręce',
            'Dotknij lewego kolana'
        ],
        parentCheck: false
    });

    // ROZBUDOWANA BAZA ZDAŃ - 80+ zdań!
    const sentences = [
        // Życie codzienne - podstawowe
        'Mama gotuje obiad',
        'Tata czyta gazetę',
        'Babcia piecze ciasto',
        'Dziadek ogląda telewizję',
        'Kot śpi na kanapie',
        'Pies biegnie po parku',
        'Dziecko bawi się zabawkami',
        'Kura znosi jajka',

        // Szkoła i nauka
        'Nauczycielka pisze na tablicy',
        'Uczniowie rozwiązują zadania',
        'Dziecko rysuje kredkami',
        'Chłopiec czyta książkę',
        'Dziewczynka liczy do dziesięciu',
        'Klasa śpiewa piosenkę',
        'Dzieci biegną na boisko',
        'Wychowawczyni opowiada bajkę',

        // Emocje i stany
        'Dziecko jest szczęśliwe',
        'Mama się martwi',
        'Tata jest zmęczony',
        'Babcia czuje się dobrze',
        'Kot jest głodny',
        'Pies jest smutny',
        'Dziewczynka płacze',
        'Chłopiec się śmieje',

        // Kolory i opisy
        'Czerwona róża pachnie pięknie',
        'Niebieska koszula wisi w szafie',
        'Żółty słonecznik rośnie w ogrodzie',
        'Zielona trawa jest mokra',
        'Biały kot myje się łapką',
        'Czarna kurtka wisi na wieszaku',
        'Różowe kwiaty kwitną wiosną',
        'Brązowy pies goni piłkę',

        // Trudne grupy spółgłoskowe
        'Trzeba kupić chleb',
        'Krzak krzewi się w krzakach',
        'Wszyscy chrzną w kościele',
        'Chrząszcz brzmi w trzcinie',
        'Przyniosę prześliczne prezenty',
        'Strzał strzelił bardzo głośno',
        'Pszczoła brzuczy przy pstryku',
        'Żółć żółtego żółwia',

        // Czasy przeszłe
        'Wczoraj jedliśmy pizzę',
        'Dzieci bawiły się w parku',
        'Mama przygotowała śniadanie',
        'Tata naprawił rower',
        'Kot złapał mysz',
        'Pies szczekał na listonosza',
        'Babcia upiekła ciasto',
        'Dziadek czytał bajki',

        // Czasy przyszłe
        'Jutro pójdziemy do kina',
        'Mama ugotuje zupę',
        'Dzieci będą się uczyć',
        'Tata kupi nowy samochód',
        'Kot będzie spał',
        'Pies pobiegnie na spacer',
        'Babcia odwiedzi nas',
        'Dziadek pokaże zdjęcia',

        // Homofony i podobnie brzmiące
        'Tata pije wodę',
        'Tata bije wodę',
        'Kot łowi myszy',
        'Kot łowi muchy',
        'Mama szyje sukienkę',
        'Mama myje sukienkę',
        'Dziecko bierze książkę',
        'Dziecko chowa książkę',

        // Złożone struktury
        'Gdy pada deszcz, dzieci zostają w domu',
        'Kiedy mama gotuje, tata pomaga',
        'Ponieważ jest zimno, zakładamy kurtki',
        'Chociaż jest trudno, dziecko się uczy',
        'Jeśli będzie słonecznie, pójdziemy na plażę',
        'Zanim pójdziemy spać, myjemy zęby',
        'Dopóki nie skończy pracy, tata zostanie',
        'Wszędzie gdzie spojrzysz, są kwiaty',

        // Pytania
        'Czy mama przygotowała obiad?',
        'Gdzie jest moja zabawka?',
        'Kiedy będziemy jeść kolację?',
        'Dlaczego kot śpi tak długo?',
        'Jak nazywa się ten ptak?',
        'Kto włączył muzykę?',
        'Co robimy jutro?',
        'Którą drogą idziemy do szkoły?',

        // Rozkazy i prośby
        'Zamknij drzwi',
        'Przynieś mi książkę',
        'Włącz światło proszę',
        'Usiądź przy stole',
        'Umyj ręce przed jedzeniem',
        'Połóż zabawki na półkę',
        'Ubierz się ciepło',
        'Posprzątaj swój pokój'
    ];

    // Refs dla audio
    const audioContextRef = useRef(null);
    const noiseRef = useRef(null);
    const speechRef = useRef(null);

    // Timer sesji
    useEffect(() => {
        const timer = setInterval(() => {
            setSessionTime(prev => prev + 1);
            setFatigueLevel(prev => Math.min(100, prev + 0.1));
        }, 1000);
        return () => clearInterval(timer);
    }, []);

    // Inicjalizacja AudioContext
    const initializeAudioContext = useCallback(() => {
        if (!audioContextRef.current) {
            try {
                audioContextRef.current = new (window.AudioContext || window.webkitAudioContext)();
            } catch (e) {
                console.warn('AudioContext not supported');
            }
        }
        return audioContextRef.current;
    }, []);

    // ZAAWANSOWANY GENERATOR SZUMÓW - różne typy z dwoma kanałami
    const generateNoise = useCallback((ctx, type, duration = 10) => {
        console.log(`🔊 GENEROWANIE SZUMU ${type.toUpperCase()} - ${duration}s dwukanałowego`);

        const bufferSize = ctx.sampleRate * duration;
        const noiseBuffer = ctx.createBuffer(2, bufferSize, ctx.sampleRate);

        for (let channel = 0; channel < noiseBuffer.numberOfChannels; channel++) {
            const channelData = noiseBuffer.getChannelData(channel);

            switch (type) {
                case 'white':
                    for (let i = 0; i < bufferSize; i++) {
                        channelData[i] = (Math.random() * 2 - 1) * 0.3;
                    }
                    break;

                case 'pink':
                    let b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;
                    for (let i = 0; i < bufferSize; i++) {
                        const white = Math.random() * 2 - 1;
                        b0 = 0.99886 * b0 + white * 0.0555179;
                        b1 = 0.99332 * b1 + white * 0.0750759;
                        b2 = 0.96900 * b2 + white * 0.1538520;
                        b3 = 0.86650 * b3 + white * 0.3104856;
                        b4 = 0.55000 * b4 + white * 0.5329522;
                        b5 = -0.7616 * b5 - white * 0.0168980;
                        const pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362;
                        b6 = white * 0.115926;
                        channelData[i] = pink * 0.11;
                    }
                    break;

                case 'brown':
                    let lastOut = 0;
                    for (let i = 0; i < bufferSize; i++) {
                        const white = Math.random() * 2 - 1;
                        const brown = (lastOut + (0.02 * white)) / 1.02;
                        lastOut = brown;
                        channelData[i] = brown * 3.5;
                    }
                    break;

                case 'babble':
                    // Symulacja głosów w tle
                    for (let i = 0; i < bufferSize; i++) {
                        const freq = 200 + Math.random() * 2000;
                        const time = i / ctx.sampleRate;
                        channelData[i] = Math.sin(2 * Math.PI * freq * time) * 0.15 * (Math.random() * 0.5 + 0.5);
                    }
                    break;

                default:
                    // Biały szum jako domyślny
                    for (let i = 0; i < bufferSize; i++) {
                        channelData[i] = (Math.random() * 2 - 1) * 0.3;
                    }
            }
        }

        return noiseBuffer;
    }, []);

    // Adaptacyjny algorytm trudności
    const updateAdaptive = useCallback((isCorrect) => {
        setAdaptiveState(prev => {
            let newSNR = prev.currentSNR;
            let newStepSize = prev.stepSize;
            let newReversals = prev.reversals;

            if (isCorrect) {
                const newStreak = prev.correctStreak + 1;
                if (newStreak >= 2) {
                    newSNR = Math.max(-20, newSNR - newStepSize);
                    if (newSNR !== prev.currentSNR && prev.history.length > 0 &&
                        prev.history[prev.history.length - 1] > newSNR) {
                        newReversals++;
                        newStepSize = newReversals >= 2 ? Math.max(0.5, newStepSize / 2) : newStepSize;
                    }
                }

                return {
                    ...prev,
                    correctStreak: newStreak,
                    currentSNR: newSNR,
                    stepSize: newStepSize,
                    reversals: newReversals,
                    history: [...prev.history, newSNR]
                };
            } else {
                newSNR = Math.min(30, newSNR + newStepSize);
                if (prev.history.length > 0 && prev.history[prev.history.length - 1] < newSNR) {
                    newReversals++;
                    newStepSize = newReversals >= 2 ? Math.max(0.5, newStepSize / 2) : newStepSize;
                }

                return {
                    ...prev,
                    correctStreak: 0,
                    currentSNR: newSNR,
                    stepSize: newStepSize,
                    reversals: newReversals,
                    history: [...prev.history, newSNR]
                };
            }
        });
    }, []);

    // 🎯 SYSTEM RÓWNOLEGŁYCH KANAŁÓW - KLUCZ APLIKACJI!
    const playParallelChannelsTest = useCallback((noiseType, speechText, snr = 10) => {
        window.testStartTime = Date.now();
        const effectiveSNR = useManualSNR ? manualSNR : snr;

        const ctx = initializeAudioContext();
        console.log(`T=0.000: 🚀 ROZPOCZYNAM TEST RÓWNOLEGŁYCH KANAŁÓW`);
        console.log(`T=0.000: Szum: ${noiseType}, SNR: ${effectiveSNR}dB, Tekst: "${speechText}"`);

        // KANAŁ 1: SZUM - startuje NATYCHMIAST
        const noiseBuffer = generateNoise(ctx, noiseType, 10);
        const noiseSource = ctx.createBufferSource();
        const noiseGain = ctx.createGain();

        noiseSource.buffer = noiseBuffer;

        const noiseLevel = Math.pow(10, -effectiveSNR / 20) * 0.5;
        noiseGain.gain.setValueAtTime(noiseLevel, ctx.currentTime);
        console.log(`T=0.000: 🔊 SZUM ${noiseType.toUpperCase()} ROZPOCZĘTY - poziom: ${noiseLevel.toFixed(3)}`);

        noiseSource.connect(noiseGain);
        noiseGain.connect(ctx.destination);
        noiseSource.start(ctx.currentTime);
        noiseSource.stop(ctx.currentTime + 10);

        // KANAŁ 2: MOWA - startuje po 2-2.5 sekundach
        const speechDelay = 2 + Math.random() * 0.5;
        console.log(`T=${speechDelay.toFixed(3)}: 🎤 MOWA ZAPLANOWANA`);

        setTimeout(() => {
            console.log(`T=${(Date.now() - window.testStartTime) / 1000}: 🗣️ MOWA START - "${speechText}"`);

            if ('speechSynthesis' in window) {
                const utterance = new SpeechSynthesisUtterance(speechText);
                utterance.lang = 'pl-PL';
                utterance.rate = 0.8;
                utterance.volume = 0.7;

                utterance.onstart = () => {
                    console.log(`T=${(Date.now() - window.testStartTime) / 1000}: ✅ SYNTEZA MOWY ROZPOCZĘTA`);
                };

                utterance.onend = () => {
                    console.log(`T=${(Date.now() - window.testStartTime) / 1000}: ⏹️ SYNTEZA MOWY ZAKOŃCZONA`);
                };

                window.speechSynthesis.speak(utterance);
            }
        }, speechDelay * 1000);
    }, [generateNoise, initializeAudioContext, manualSNR, useManualSNR]);

    // Test dźwięków zwierząt z szumem
    const playSoundWithNoise = useCallback((soundText, noiseType, snr = 15) => {
        window.testStartTime = Date.now();
        const effectiveSNR = useManualSNR ? manualSNR : snr;

        const ctx = initializeAudioContext();
        console.log(`T=0.000: 🔊 TEST DŹWIĘKU Z SZUMEM: "${soundText}"`);

        const noiseBuffer = generateNoise(ctx, noiseType, 8);
        const noiseSource = ctx.createBufferSource();
        const noiseGain = ctx.createGain();

        noiseSource.buffer = noiseBuffer;
        const noiseLevel = Math.pow(10, -effectiveSNR / 20) * 0.4;
        noiseGain.gain.setValueAtTime(noiseLevel, ctx.currentTime);

        noiseSource.connect(noiseGain);
        noiseGain.connect(ctx.destination);
        noiseSource.start(ctx.currentTime);
        noiseSource.stop(ctx.currentTime + 8);

        console.log(`T=0.000: 🌊 SZUM ${noiseType.toUpperCase()} ROZPOCZĘTY`);

        setTimeout(() => {
            console.log(`T=${(Date.now() - window.testStartTime) / 1000}: 🐾 DŹWIĘK START - "${soundText}"`);

            if ('speechSynthesis' in window) {
                const utterance = new SpeechSynthesisUtterance(soundText);
                utterance.lang = 'pl-PL';
                utterance.rate = 0.7;
                utterance.volume = 0.8;
                window.speechSynthesis.speak(utterance);
            }
        }, 1500);
    }, [generateNoise, initializeAudioContext, manualSNR, useManualSNR]);

    // Odtwarzanie z panningiem (Web Audio API)
    const playWithPanning = useCallback((frequency, pan = 0, duration = 1000) => {
        const ctx = initializeAudioContext();

        const oscillator = ctx.createOscillator();
        const gainNode = ctx.createGain();
        const panNode = ctx.createStereoPanner();

        oscillator.frequency.setValueAtTime(frequency, ctx.currentTime);
        oscillator.type = 'sine';

        panNode.pan.setValueAtTime(pan, ctx.currentTime);
        gainNode.gain.setValueAtTime(0.3, ctx.currentTime);

        oscillator.connect(panNode);
        panNode.connect(gainNode);
        gainNode.connect(ctx.destination);

        oscillator.start();
        oscillator.stop(ctx.currentTime + duration / 1000);
    }, [initializeAudioContext]);

    // Nowe ćwiczenie - mowa w szumie
    const startSpeechInNoise = useCallback(() => {
        const sentence = sentences[Math.floor(Math.random() * sentences.length)];
        const words = sentence.toLowerCase().split(' ');

        setSpeechInNoiseState(prev => ({
            ...prev,
            currentSentence: sentence,
            sentenceWords: words,
            userInput: ''
        }));

        playParallelChannelsTest(speechInNoiseState.noiseType, sentence, useManualSNR ? manualSNR : adaptiveState.currentSNR);
    }, [sentences, playParallelChannelsTest, speechInNoiseState.noiseType, manualSNR, useManualSNR, adaptiveState.currentSNR]);

    // Sprawdzanie odpowiedzi
    const checkSpeechAnswer = useCallback(() => {
        const userWords = speechInNoiseState.userInput.toLowerCase().trim().split(/\s+/);
        const targetWords = speechInNoiseState.sentenceWords;

        let correctWords = 0;
        userWords.forEach(word => {
            if (targetWords.includes(word)) correctWords++;
        });

        const accuracy = correctWords / targetWords.length;
        const isCorrect = accuracy >= 0.7;

        updateAdaptive(isCorrect);

        console.log(`📊 Odpowiedź: ${(accuracy * 100).toFixed(1)}% poprawna (${correctWords}/${targetWords.length} słów)`);

        setSpeechInNoiseState(prev => ({
            ...prev,
            currentSentence: '',
            sentenceWords: [],
            userInput: ''
        }));
    }, [speechInNoiseState, updateAdaptive]);

    // Moduł rozpoznawania dźwięków
    const startSoundRecognition = useCallback(() => {
        const correctIndex = Math.floor(Math.random() * soundRecognitionState.soundsLibrary.length);
        const correct = soundRecognitionState.soundsLibrary[correctIndex];

        const shuffled = [...soundRecognitionState.soundsLibrary]
            .sort(() => Math.random() - 0.5)
            .slice(0, 4);

        if (!shuffled.includes(correct)) {
            shuffled[0] = correct;
        }

        setSoundRecognitionState(prev => ({
            ...prev,
            options: shuffled,
            correctSound: correct.name
        }));

        playSoundWithNoise(correct.sound, soundRecognitionState.noiseType, useManualSNR ? manualSNR : adaptiveState.currentSNR);
    }, [soundRecognitionState.soundsLibrary, soundRecognitionState.noiseType, playSoundWithNoise, manualSNR, useManualSNR, adaptiveState.currentSNR]);

    // Lateralizacja - prosta z dźwiękami
    const startSimpleLateralization = useCallback(() => {
        const ears = ['Lewe ucho', 'Prawe ucho'];
        const selectedEar = ears[Math.floor(Math.random() * ears.length)];
        const pan = selectedEar === 'Lewe ucho' ? -1 : 1;

        setLateralizationState(prev => ({
            ...prev,
            currentEar: selectedEar,
            panningValue: pan
        }));

        console.log(`👂 LATERALIZACJA: ${selectedEar} (pan: ${pan})`);

        // Użyj Web Audio API z prawdziwym panningiem
        playWithPanning(800, pan, 1000);
    }, [playWithPanning]);

    // NOWA: Lateralizacja z sekwencjami cyfr
    const startDigitSequence = useCallback(() => {
        const length = lateralizationState.sequenceLength;
        const sequence = Array.from({ length }, () => Math.floor(Math.random() * 10));

        setLateralizationState(prev => ({
            ...prev,
            mode: 'sequence',
            digitSequence: sequence,
            userDigitSequence: [],
            currentDigitIndex: 0
        }));

        playDigitSequenceWithPanning(sequence, () => {
            console.log('🔢 SEKWENCJA CYFR ZAKOŃCZONA - czekam na odpowiedź');
        });
    }, [lateralizationState.sequenceLength]);

    // ZAAWANSOWANE odtwarzanie sekwencji cyfr z szumem i panningiem  
    const playDigitSequenceWithPanning = useCallback((sequence, onComplete) => {
        window.testStartTime = Date.now();
        const ctx = initializeAudioContext();

        console.log(`🔢 SEKWENCJA CYFR START: ${sequence.join('-')} (alternating L-R z szumem)`);

        // Szum w tle przez całą sekwencję
        const noiseBuffer = generateNoise(ctx, 'white', sequence.length * 2);
        const noiseSource = ctx.createBufferSource();
        const noiseGain = ctx.createGain();

        noiseSource.buffer = noiseBuffer;
        const noiseLevel = 0.2; // Delikatny szum w tle
        noiseGain.gain.setValueAtTime(noiseLevel, ctx.currentTime);

        noiseSource.connect(noiseGain);
        noiseGain.connect(ctx.destination);
        noiseSource.start(ctx.currentTime);
        noiseSource.stop(ctx.currentTime + sequence.length * 2);

        // Cyfry z alternującym panningiem
        sequence.forEach((digit, index) => {
            setTimeout(() => {
                const pan = index % 2 === 0 ? -1 : 1;
                const ear = pan < 0 ? 'LEWE' : 'PRAWE';

                console.log(`T=${(index * 1.5).toFixed(1)}s: Cyfra "${digit}" → ${ear} UCHO (pan: ${pan})`);

                // Tone z panningiem jako wskazanie ucha
                playWithPanning(400 + (digit * 50), pan, 200);

                // Mowa po krótkim opóźnieniu
                setTimeout(() => {
                    if ('speechSynthesis' in window) {
                        const utterance = new SpeechSynthesisUtterance(digit.toString());
                        utterance.lang = 'pl-PL';
                        utterance.rate = 0.6;
                        utterance.volume = 0.9;
                        utterance.pitch = 1.0;

                        window.speechSynthesis.speak(utterance);
                    }
                }, 300);

                if (index === sequence.length - 1) {
                    setTimeout(onComplete, 2000);
                }
            }, index * 1500);
        });
    }, [generateNoise, initializeAudioContext, playWithPanning]);

    // Sprawdzanie sekwencji cyfr
    const checkDigitSequence = useCallback(() => {
        const correct = JSON.stringify(lateralizationState.digitSequence);
        const user = JSON.stringify(lateralizationState.userDigitSequence);
        const isCorrect = correct === user;

        console.log(`🔍 SPRAWDZENIE SEKWENCJI:`);
        console.log(`Prawidłowa: [${lateralizationState.digitSequence.join(', ')}]`);
        console.log(`Podana: [${lateralizationState.userDigitSequence.join(', ')}]`);
        console.log(`Wynik: ${isCorrect ? '✅ POPRAWNE' : '❌ BŁĘDNE'}`);

        updateAdaptive(isCorrect);

        setLateralizationState(prev => ({
            ...prev,
            digitSequence: [],
            userDigitSequence: [],
            currentDigitIndex: 0
        }));
    }, [lateralizationState, updateAdaptive]);

    // Dodawanie cyfry do sekwencji użytkownika
    const addDigitToSequence = useCallback((digit) => {
        setLateralizationState(prev => {
            const newSequence = [...prev.userDigitSequence, digit];
            console.log(`➕ Dodano cyfrę: ${digit}, sekwencja: [${newSequence.join(', ')}]`);
            return {
                ...prev,
                userDigitSequence: newSequence
            };
        });
    }, []);

    // Format czasu
    const formatTime = (seconds) => {
        const mins = Math.floor(seconds / 60);
        const secs = seconds % 60;
        return `${mins}:${secs.toString().padStart(2, '0')}`;
    };

    // SNR do koloru
    const getSNRColor = (snr) => {
        if (snr < -10) return 'text-red-600';
        if (snr < 0) return 'text-orange-600';
        if (snr < 10) return 'text-yellow-600';
        if (snr < 20) return 'text-green-600';
        return 'text-blue-600';
    };

    // Definicje modułów z uzasadnieniami terapeutycznymi
    const modules = {
        speechInNoise: {
            name: 'Mowa w Szumie',
            icon: <Mic />,
            description: 'Rozpoznawanie mowy przy obecności szumu tła',
            therapeutic: {
                goal: 'Rozwój zdolności selektywnej uwagi słuchowej',
                neurobiology: 'Wzmacnia funkcje kory słuchowej i mechanizmy maskowania wstecznego',
                clinicalValue: 'Kluczowe dla funkcjonowania w środowisku klasowym i społecznym'
            }
        },
        soundRecognition: {
            name: 'Rozpoznawanie Dźwięków',
            icon: <Volume2 />,
            description: 'Identyfikacja dźwięków środowiskowych',
            therapeutic: {
                goal: 'Rozwój dyskryminacji słuchowej i pamięci dźwiękowej',
                neurobiology: 'Aktywuje korteks słuchowy wtórny odpowiedzialny za rozpoznawanie wzorców',
                clinicalValue: 'Podstawa dla rozwoju umiejętności językowych i czytania'
            }
        },
        lateralization: {
            name: 'Lateralizacja',
            icon: <Headphones />,
            description: 'Ćwiczenia przestrzennego słyszenia',
            therapeutic: {
                goal: 'Rozwój binauralnego przetwarzania i lokalizacji dźwięku',
                neurobiology: 'Wzmacnia połączenia między półkulami mózgu przez corpus callosum',
                clinicalValue: 'Kluczowe dla umiejętności słuchania w hałasie i uwagi skoncentrowanej'
            }
        },
        audioMotor: {
            name: 'Audio-Motor',
            icon: <Target />,
            description: 'Integracja słuchu z ruchem',
            therapeutic: {
                goal: 'Synchronizacja procesów słuchowych z motorycznymi',
                neurobiology: 'Integruje korę słuchową z korą motoryczną przez system lustrzanych neuronów',
                clinicalValue: 'Wspiera rozwój mowy, rytmu i koordynacji ruchowej'
            }
        }
    };

    return (
        <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex flex-col pt-16">
            <Navbar currentView={currentView} setCurrentView={setCurrentView} />

            {currentView === 'privacy' ? (
                <main className="flex-grow">
                    <PrivacyPolicy />
                </main>
            ) : (
                <main id="aplikacja" className="flex-grow max-w-7xl mx-auto w-full p-4 md:p-6 lg:p-8">
                    {/* Header (Panel Główny) */}
                    <header className="bg-white rounded-xl shadow-md p-6 mb-8 mt-4">
                        <div className="flex flex-col md:flex-row items-center justify-between gap-4">
                            <div className="text-center md:text-left">
                                <h1 className="text-3xl font-bold text-gray-800">
                                    🎧 Trening APD
                                </h1>
                                <p className="text-gray-600 mt-1">System terapii zaburzeń przetwarzania słuchowego</p>
                            </div>

                            <div className="flex items-center gap-4">
                                <div className="text-center">
                                    <div className="flex items-center gap-2 text-gray-600">
                                        <Timer />
                                        <span>{formatTime(sessionTime)}</span>
                                    </div>
                                    <div className="text-xs text-gray-500">Czas sesji</div>
                                </div>

                                <button
                                    onClick={() => setShowParentPanel(!showParentPanel)}
                                    className="bg-blue-500 text-white px-4 py-2 rounded-lg hover:bg-blue-600 flex items-center gap-2"
                                >
                                    <BarChart3 />
                                    Panel Terapeuty
                                </button>
                            </div>
                        </div>

                        {/* GLOBALNY SUWAK SNR */}
                        <div className="mt-6 bg-gray-50 rounded-lg p-4">
                            <div className="flex items-center justify-between mb-3">
                                <h3 className="font-semibold text-gray-800">🎛️ Globalny SNR Control</h3>
                                <div className="flex items-center gap-3">
                                    <span className="text-sm font-medium">AUTO</span>
                                    <label className="relative inline-flex items-center cursor-pointer">
                                        <input
                                            type="checkbox"
                                            checked={useManualSNR}
                                            onChange={(e) => setUseManualSNR(e.target.checked)}
                                            className="sr-only peer"
                                        />
                                        <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                                    </label>
                                    <span className="text-sm font-medium">MANUAL</span>
                                </div>
                            </div>

                            {useManualSNR && (
                                <div className="space-y-2">
                                    <div className="flex items-center gap-4">
                                        <span className="text-sm font-medium min-w-16">SNR:</span>
                                        <div className="flex-1 relative">
                                            <input
                                                type="range"
                                                min="-20"
                                                max="30"
                                                step="0.5"
                                                value={manualSNR}
                                                onChange={(e) => setManualSNR(parseFloat(e.target.value))}
                                                className="w-full h-3 rounded-lg appearance-none cursor-pointer"
                                                style={{
                                                    background: 'linear-gradient(to right, #ef4444 0%, #f97316 25%, #eab308 50%, #22c55e 75%, #3b82f6 100%)'
                                                }}
                                            />
                                        </div>
                                        <span className={`text-lg font-bold min-w-20 ${getSNRColor(manualSNR)}`}>
                                            {manualSNR.toFixed(1)}dB
                                        </span>
                                    </div>
                                    <div className="text-xs text-gray-500 text-center">
                                        💡 Manual SNR wyłącza adaptacyjny algorytm trudności
                                    </div>
                                </div>
                            )}

                            {!useManualSNR && (
                                <div className="text-center">
                                    <span className={`text-lg font-bold ${getSNRColor(adaptiveState.currentSNR)}`}>
                                        Auto SNR: {adaptiveState.currentSNR.toFixed(1)}dB
                                    </span>
                                    <div className="text-xs text-gray-500 mt-1">
                                        🤖 Adaptacja: {adaptiveState.correctStreak} poprawnych | {adaptiveState.reversals} odwróceń
                                    </div>
                                </div>
                            )}
                        </div>
                    </header>

                    <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
                        {/* Sidebar - wybór modułów */}
                        <div className="lg:col-span-1">
                            <div className="bg-white rounded-lg shadow-md p-4">
                                <h2 className="text-lg font-semibold text-gray-800 mb-4">Moduły Terapeutyczne</h2>

                                {Object.entries(modules).map(([key, module]) => (
                                    <button
                                        key={key}
                                        onClick={() => setCurrentModule(key)}
                                        className={`w-full mb-3 p-4 rounded-lg text-left transition-all ${currentModule === key
                                                ? 'bg-blue-500 text-white shadow-lg'
                                                : 'bg-gray-50 text-gray-700 hover:bg-gray-100'
                                            }`}
                                    >
                                        <div className="flex items-center gap-3">
                                            {module.icon}
                                            <div>
                                                <div className="font-semibold">{module.name}</div>
                                                <div className="text-xs opacity-75">{module.description}</div>
                                            </div>
                                        </div>
                                    </button>
                                ))}
                            </div>

                            {/* Kalibracja dźwięku */}
                            <div className="bg-white rounded-lg shadow-md p-4 mt-4">
                                <h3 className="font-semibold text-gray-800 mb-3">🔊 Kalibracja</h3>

                                {!volumeCalibrated ? (
                                    <div className="space-y-3">
                                        <p className="text-sm text-gray-600">
                                            Ustaw wygodny poziom głośności
                                        </p>
                                        <button
                                            onClick={() => {
                                                if ('speechSynthesis' in window) {
                                                    const utterance = new SpeechSynthesisUtterance('To jest test dźwięku');
                                                    utterance.lang = 'pl-PL';
                                                    window.speechSynthesis.speak(utterance);
                                                }
                                            }}
                                            className="w-full bg-green-500 text-white py-2 rounded hover:bg-green-600"
                                        >
                                            🔊 Test Dźwięku
                                        </button>
                                        <button
                                            onClick={() => setVolumeCalibrated(true)}
                                            className="w-full bg-blue-500 text-white py-2 rounded hover:bg-blue-600"
                                        >
                                            ✅ Gotowe
                                        </button>
                                    </div>
                                ) : (
                                    <div className="text-center">
                                        <div className="text-green-600 text-2xl mb-2">✅</div>
                                        <p className="text-sm text-gray-600">Dźwięk skalibrowany</p>
                                        <button
                                            onClick={() => setVolumeCalibrated(false)}
                                            className="text-xs text-blue-500 hover:underline mt-2"
                                        >
                                            Ponowna kalibracja
                                        </button>
                                    </div>
                                )}
                            </div>
                        </div>

                        {/* Główny obszar ćwiczeń */}
                        <div className="lg:col-span-3">
                            {!volumeCalibrated ? (
                                <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-8 text-center">
                                    <div className="text-4xl mb-4">🎧</div>
                                    <h3 className="text-xl font-semibold text-yellow-800 mb-2">
                                        Najpierw skalibruj dźwięk
                                    </h3>
                                    <p className="text-yellow-700">
                                        Użyj panelu po lewej stronie, aby ustawić odpowiedni poziom głośności
                                    </p>
                                </div>
                            ) : (
                                <div className="space-y-6">
                                    {/* Panel uzasadnienia terapeutycznego */}
                                    <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                                        <div className="flex items-start gap-3">
                                            <Info />
                                            <div>
                                                <h4 className="font-semibold text-blue-800 mb-2">
                                                    👩‍⚕️ Uzasadnienie: {modules[currentModule].name}
                                                </h4>
                                                <div className="text-sm text-blue-700 space-y-1">
                                                    <p><strong>Cel:</strong> {modules[currentModule].therapeutic.goal}</p>
                                                    <p><strong>Neurobiologia:</strong> {modules[currentModule].therapeutic.neurobiology}</p>
                                                    <p><strong>Wartość kliniczna:</strong> {modules[currentModule].therapeutic.clinicalValue}</p>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    {/* 🎤 MODUŁ: MOWA W SZUMIE */}
                                    {currentModule === 'speechInNoise' && (
                                        <div className="space-y-6">
                                            <div className="bg-green-50 rounded-lg p-4">
                                                <h3 className="text-lg font-semibold text-green-800 mb-4">
                                                    🎤 Rozumienie Mowy w Szumie
                                                </h3>

                                                {/* Wybór typu szumu */}
                                                <div className="bg-white rounded-lg p-4 mb-4">
                                                    <h4 className="font-semibold mb-3">🔊 Typ szumu tła:</h4>
                                                    <div className="grid grid-cols-2 gap-2">
                                                        {[
                                                            { type: 'white', name: 'Biały Szum', desc: 'Równomierne widmo', emoji: '⚪' },
                                                            { type: 'pink', name: 'Różowy Szum', desc: 'Naturalniejszy', emoji: '🌸' },
                                                            { type: 'brown', name: 'Brązowy Szum', desc: 'Głębokie częstotliwości', emoji: '🟤' },
                                                            { type: 'babble', name: 'Babble Noise', desc: 'Głosy w tle', emoji: '👥' }
                                                        ].map(noise => (
                                                            <button
                                                                key={noise.type}
                                                                onClick={() => setSpeechInNoiseState(prev => ({ ...prev, noiseType: noise.type }))}
                                                                className={`p-3 rounded-lg text-left transition-all ${speechInNoiseState.noiseType === noise.type
                                                                        ? 'bg-green-500 text-white shadow-lg'
                                                                        : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                                                                    }`}
                                                            >
                                                                <div className="font-semibold text-sm">{noise.emoji} {noise.name}</div>
                                                                <div className="text-xs opacity-75">{noise.desc}</div>
                                                            </button>
                                                        ))}
                                                    </div>
                                                    <div className="text-xs text-gray-500 mt-2 text-center">
                                                        💡 Dwukanałowe audio: szum startuje natychmiast, mowa po 2s opóźnieniu
                                                    </div>
                                                </div>

                                                {!speechInNoiseState.currentSentence ? (
                                                    <button
                                                        onClick={startSpeechInNoise}
                                                        className="w-full bg-green-600 text-white px-6 py-4 rounded-lg text-lg font-semibold hover:bg-green-700"
                                                    >
                                                        ▶️ Start Ćwiczenia
                                                    </button>
                                                ) : (
                                                    <div className="space-y-4">
                                                        <div className="bg-white rounded-lg p-4 text-center">
                                                            <p className="text-gray-600 mb-4">
                                                                Wpisz usłyszane zdanie:
                                                            </p>

                                                            <input
                                                                type="text"
                                                                value={speechInNoiseState.userInput}
                                                                onChange={(e) => setSpeechInNoiseState(prev => ({
                                                                    ...prev,
                                                                    userInput: e.target.value
                                                                }))}
                                                                className="w-full p-3 border border-gray-300 rounded-lg text-lg"
                                                                placeholder="Wpisz usłyszane zdanie..."
                                                                autoFocus
                                                            />
                                                        </div>

                                                        <div className="flex gap-4 justify-center">
                                                            <button
                                                                onClick={() => playParallelChannelsTest(
                                                                    speechInNoiseState.noiseType,
                                                                    speechInNoiseState.currentSentence,
                                                                    useManualSNR ? manualSNR : adaptiveState.currentSNR
                                                                )}
                                                                className="bg-blue-500 text-white px-6 py-3 rounded-lg font-semibold hover:bg-blue-600"
                                                            >
                                                                🔄 Powtórz
                                                            </button>

                                                            <button
                                                                onClick={checkSpeechAnswer}
                                                                disabled={!speechInNoiseState.userInput.trim()}
                                                                className="bg-green-500 text-white px-6 py-3 rounded-lg font-semibold hover:bg-green-600 disabled:bg-gray-300"
                                                            >
                                                                ✅ Sprawdź
                                                            </button>
                                                        </div>

                                                        <div className="bg-yellow-100 border border-yellow-300 rounded-lg p-4">
                                                            <p className="text-sm text-yellow-800">
                                                                <strong>👩‍⚕️ Dla terapeuty:</strong>
                                                                Prawidłowe zdanie: "{speechInNoiseState.currentSentence}"
                                                            </p>
                                                        </div>
                                                    </div>
                                                )}
                                            </div>
                                        </div>
                                    )}

                                    {/* 🔊 MODUŁ: ROZPOZNAWANIE DŹWIĘKÓW */}
                                    {currentModule === 'soundRecognition' && (
                                        <div className="space-y-6">
                                            <div className="bg-purple-50 rounded-lg p-4">
                                                <h3 className="text-lg font-semibold text-purple-800 mb-4">
                                                    🔊 Rozpoznawanie Dźwięków Środowiskowych
                                                </h3>

                                                {/* Wybór typu szumu */}
                                                <div className="bg-white rounded-lg p-4 mb-4">
                                                    <h4 className="font-semibold mb-3">🔊 Typ szumu tła:</h4>
                                                    <div className="grid grid-cols-2 gap-2">
                                                        {[
                                                            { type: 'white', name: 'Biały Szum', desc: 'Równomierne widmo', emoji: '⚪' },
                                                            { type: 'pink', name: 'Różowy Szum', desc: 'Naturalniejszy', emoji: '🌸' },
                                                            { type: 'brown', name: 'Brązowy Szum', desc: 'Głębokie częstotliwości', emoji: '🟤' },
                                                            { type: 'babble', name: 'Babble Noise', desc: 'Głosy w tle', emoji: '👥' }
                                                        ].map(noise => (
                                                            <button
                                                                key={noise.type}
                                                                onClick={() => setSoundRecognitionState(prev => ({ ...prev, noiseType: noise.type }))}
                                                                className={`p-3 rounded-lg text-left transition-all ${soundRecognitionState.noiseType === noise.type
                                                                        ? 'bg-purple-500 text-white shadow-lg'
                                                                        : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                                                                    }`}
                                                            >
                                                                <div className="font-semibold text-sm">{noise.emoji} {noise.name}</div>
                                                                <div className="text-xs opacity-75">{noise.desc}</div>
                                                            </button>
                                                        ))}
                                                    </div>
                                                    <div className="text-xs text-gray-500 mt-2 text-center">
                                                        🎧 Każdy dźwięk odtwarzany z wybranym szumem tła
                                                    </div>
                                                </div>

                                                {soundRecognitionState.options.length === 0 ? (
                                                    <button
                                                        onClick={startSoundRecognition}
                                                        className="w-full bg-purple-600 text-white px-6 py-4 rounded-lg text-lg font-semibold hover:bg-purple-700"
                                                    >
                                                        ▶️ Odtwórz Dźwięk
                                                    </button>
                                                ) : (
                                                    <div className="space-y-4">
                                                        <p className="text-center text-gray-600 mb-4">
                                                            Który dźwięk usłyszałeś?
                                                        </p>

                                                        <div className="grid grid-cols-2 gap-4">
                                                            {soundRecognitionState.options.map((sound) => (
                                                                <button
                                                                    key={sound.name}
                                                                    onClick={() => {
                                                                        const isCorrect = sound.name === soundRecognitionState.correctSound;
                                                                        updateAdaptive(isCorrect);
                                                                        setSoundRecognitionState(prev => ({
                                                                            ...prev,
                                                                            options: [],
                                                                            correctSound: ''
                                                                        }));
                                                                    }}
                                                                    className="bg-white p-4 rounded-lg border-2 border-gray-200 hover:border-purple-400 transition-colors"
                                                                >
                                                                    <div className="text-3xl mb-2">{sound.image}</div>
                                                                    <div className="font-semibold">{sound.name}</div>
                                                                </button>
                                                            ))}
                                                        </div>

                                                        <div className="bg-yellow-100 border border-yellow-300 rounded-lg p-4">
                                                            <p className="text-sm text-yellow-800">
                                                                <strong>👩‍⚕️ Dla terapeuty:</strong>
                                                                Prawidłowa odpowiedź: "{soundRecognitionState.correctSound}"
                                                            </p>
                                                        </div>
                                                    </div>
                                                )}
                                            </div>
                                        </div>
                                    )}

                                    {/* 👂 MODUŁ: LATERALIZACJA - ROZBUDOWANY */}
                                    {currentModule === 'lateralization' && (
                                        <div className="space-y-6">
                                            <div className="bg-indigo-50 rounded-lg p-4">
                                                <h3 className="text-lg font-semibold text-indigo-800 mb-4">
                                                    👂 Lateralizacja i Przestrzenne Słyszenie
                                                </h3>

                                                {/* Wybór trybu */}
                                                <div className="bg-white rounded-lg p-4 mb-4">
                                                    <h4 className="font-semibold mb-3">Wybierz tryb ćwiczeń:</h4>
                                                    <div className="flex gap-4">
                                                        <button
                                                            onClick={() => setLateralizationState(prev => ({
                                                                ...prev,
                                                                mode: 'simple'
                                                            }))}
                                                            className={`px-4 py-2 rounded-lg font-medium ${lateralizationState.mode === 'simple'
                                                                    ? 'bg-indigo-500 text-white'
                                                                    : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                                                                }`}
                                                        >
                                                            🎯 Proste Dźwięki
                                                        </button>
                                                        <button
                                                            onClick={() => setLateralizationState(prev => ({
                                                                ...prev,
                                                                mode: 'sequence'
                                                            }))}
                                                            className={`px-4 py-2 rounded-lg font-medium ${lateralizationState.mode === 'sequence'
                                                                    ? 'bg-indigo-500 text-white'
                                                                    : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                                                                }`}
                                                        >
                                                            🔢 Sekwencje Cyfr
                                                        </button>
                                                    </div>
                                                </div>

                                                {/* Tryb prosty */}
                                                {lateralizationState.mode === 'simple' && (
                                                    <div className="space-y-4">
                                                        {!lateralizationState.currentEar ? (
                                                            <button
                                                                onClick={startSimpleLateralization}
                                                                className="w-full bg-indigo-600 text-white px-6 py-4 rounded-lg text-lg font-semibold hover:bg-indigo-700"
                                                            >
                                                                ▶️ Odtwórz Dźwięk
                                                            </button>
                                                        ) : (
                                                            <div className="space-y-4">
                                                                <p className="text-center text-gray-600">
                                                                    Z której strony usłyszałeś dźwięk?
                                                                </p>

                                                                <div className="flex gap-4 justify-center">
                                                                    <button
                                                                        onClick={() => {
                                                                            const isCorrect = lateralizationState.currentEar === 'Lewe ucho';
                                                                            updateAdaptive(isCorrect);
                                                                            setLateralizationState(prev => ({
                                                                                ...prev,
                                                                                currentEar: '',
                                                                                panningValue: 0
                                                                            }));
                                                                        }}
                                                                        className="bg-blue-500 text-white px-8 py-3 rounded-lg font-semibold hover:bg-blue-600"
                                                                    >
                                                                        👂 Lewe Ucho
                                                                    </button>

                                                                    <button
                                                                        onClick={() => {
                                                                            const isCorrect = lateralizationState.currentEar === 'Prawe ucho';
                                                                            updateAdaptive(isCorrect);
                                                                            setLateralizationState(prev => ({
                                                                                ...prev,
                                                                                currentEar: '',
                                                                                panningValue: 0
                                                                            }));
                                                                        }}
                                                                        className="bg-red-500 text-white px-8 py-3 rounded-lg font-semibold hover:bg-red-600"
                                                                    >
                                                                        👂 Prawe Ucho
                                                                    </button>
                                                                </div>

                                                                <div className="bg-yellow-100 border border-yellow-300 rounded-lg p-4">
                                                                    <p className="text-sm text-yellow-800">
                                                                        <strong>👩‍⚕️ Dla terapeuty:</strong>
                                                                        Prawidłowa odpowiedź: "{lateralizationState.currentEar}"
                                                                    </p>
                                                                </div>
                                                            </div>
                                                        )}
                                                    </div>
                                                )}

                                                {/* NOWY: Tryb sekwencji cyfr */}
                                                {lateralizationState.mode === 'sequence' && (
                                                    <div className="space-y-4">
                                                        {/* Ustawienia długości */}
                                                        <div className="bg-white rounded-lg p-4">
                                                            <h4 className="font-semibold mb-3">⚙️ Ustawienia sekwencji:</h4>
                                                            <div className="flex items-center gap-4">
                                                                <span className="text-sm font-medium">Długość:</span>
                                                                <div className="flex gap-2">
                                                                    {[2, 3, 4, 5, 6, 7, 8].map(num => (
                                                                        <button
                                                                            key={num}
                                                                            onClick={() => setLateralizationState(prev => ({
                                                                                ...prev,
                                                                                sequenceLength: num
                                                                            }))}
                                                                            className={`w-8 h-8 rounded ${lateralizationState.sequenceLength === num
                                                                                    ? 'bg-indigo-500 text-white'
                                                                                    : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                                                                                }`}
                                                                        >
                                                                            {num}
                                                                        </button>
                                                                    ))}
                                                                </div>
                                                            </div>
                                                            <div className="text-xs text-gray-500 mt-2">
                                                                🔢 Cyfry odtwarzane alternująco: L-R-L-R... z szumem w tle
                                                            </div>
                                                        </div>

                                                        {lateralizationState.digitSequence.length === 0 ? (
                                                            <button
                                                                onClick={startDigitSequence}
                                                                className="w-full bg-indigo-600 text-white px-6 py-4 rounded-lg text-lg font-semibold hover:bg-indigo-700"
                                                            >
                                                                ▶️ Odtwórz Sekwencję Cyfr ({lateralizationState.sequenceLength} cyfr)
                                                            </button>
                                                        ) : (
                                                            <div className="space-y-4">
                                                                <div className="bg-white rounded-lg p-4 text-center">
                                                                    <p className="text-gray-600 mb-4">
                                                                        Wpisz cyfry w kolejności (L-R-L-R...):
                                                                    </p>

                                                                    <div className="mb-4">
                                                                        <strong>Twoja sekwencja:</strong> [{lateralizationState.userDigitSequence.join(', ')}]
                                                                    </div>

                                                                    {/* Klawiatura cyfr */}
                                                                    <div className="grid grid-cols-5 gap-2 max-w-md mx-auto mb-4">
                                                                        {[0, 1, 2, 3, 4, 5, 6, 7, 8, 9].map(digit => (
                                                                            <button
                                                                                key={digit}
                                                                                onClick={() => addDigitToSequence(digit)}
                                                                                disabled={lateralizationState.userDigitSequence.length >= lateralizationState.digitSequence.length}
                                                                                className="bg-blue-500 text-white text-2xl py-3 px-4 rounded-lg font-bold hover:bg-blue-600 disabled:bg-gray-300"
                                                                            >
                                                                                {digit}
                                                                            </button>
                                                                        ))}
                                                                    </div>
                                                                </div>

                                                                <div className="flex gap-4 justify-center">
                                                                    <button
                                                                        onClick={() => setLateralizationState(prev => ({
                                                                            ...prev,
                                                                            userDigitSequence: prev.userDigitSequence.slice(0, -1)
                                                                        }))}
                                                                        disabled={lateralizationState.userDigitSequence.length === 0}
                                                                        className="bg-orange-500 text-white px-6 py-3 rounded-lg font-semibold hover:bg-orange-600 disabled:bg-gray-300"
                                                                    >
                                                                        ⬅️ Cofnij
                                                                    </button>

                                                                    <button
                                                                        onClick={checkDigitSequence}
                                                                        disabled={lateralizationState.userDigitSequence.length !== lateralizationState.digitSequence.length}
                                                                        className="bg-green-500 text-white px-6 py-3 rounded-lg font-semibold hover:bg-green-600 disabled:bg-gray-300"
                                                                    >
                                                                        ✅ Sprawdź Sekwencję
                                                                    </button>
                                                                </div>

                                                                <div className="bg-yellow-100 border border-yellow-300 rounded-lg p-4">
                                                                    <p className="text-sm text-yellow-800">
                                                                        <strong>👩‍⚕️ Dla terapeuty:</strong>
                                                                        Prawidłowa sekwencja: [{lateralizationState.digitSequence.join(', ')}]
                                                                        <br />
                                                                        <span className="text-xs">
                                                                            🎧 Wzór L-R: {lateralizationState.digitSequence.map((d, i) =>
                                                                                `${d}(${i % 2 === 0 ? 'L' : 'R'})`
                                                                            ).join(' → ')}
                                                                        </span>
                                                                    </p>
                                                                </div>
                                                            </div>
                                                        )}
                                                    </div>
                                                )}
                                            </div>
                                        </div>
                                    )}

                                    {/* 🏃 MODUŁ: AUDIO + MOTOR */}
                                    {currentModule === 'audioMotor' && (
                                        <div className="space-y-6">
                                            <div className="bg-red-50 rounded-lg p-4">
                                                <h3 className="text-lg font-semibold text-red-800 mb-4">
                                                    🏃 Integracja Słuchu i Ruchu
                                                </h3>

                                                <button
                                                    onClick={() => {
                                                        const command = audioMotorState.commands[
                                                            Math.floor(Math.random() * audioMotorState.commands.length)
                                                        ];

                                                        setAudioMotorState(prev => ({
                                                            ...prev,
                                                            currentCommand: command,
                                                            parentCheck: false
                                                        }));

                                                        if ('speechSynthesis' in window) {
                                                            const utterance = new SpeechSynthesisUtterance(command);
                                                            utterance.lang = 'pl-PL';
                                                            utterance.rate = 0.8;
                                                            window.speechSynthesis.speak(utterance);
                                                        }
                                                    }}
                                                    className="w-full bg-red-600 text-white px-6 py-4 rounded-lg text-lg font-semibold hover:bg-red-700"
                                                >
                                                    ▶️ Odtwórz Polecenie Ruchowe
                                                </button>
                                            </div>

                                            {audioMotorState.currentCommand && (
                                                <div className="bg-gray-50 rounded-lg p-6">
                                                    <div className="text-center mb-6">
                                                        <h4 className="text-2xl font-bold text-gray-800 mb-2">
                                                            {audioMotorState.currentCommand}
                                                        </h4>
                                                        <p className="text-gray-600">Dziecko powinno wykonać to polecenie</p>
                                                    </div>

                                                    <div className="bg-yellow-100 border border-yellow-300 rounded-lg p-4 mb-4">
                                                        <p className="text-sm text-yellow-800">
                                                            <strong>👩‍⚕️ Dla terapeuty:</strong>
                                                            Oceń wykonanie ruchu przez dziecko. Zwróć uwagę na: szybkość reakcji, precyzję ruchu, zrozumienie polecenia.
                                                        </p>
                                                    </div>

                                                    <div className="flex gap-4 justify-center">
                                                        <button
                                                            onClick={() => {
                                                                updateAdaptive(true);
                                                                setAudioMotorState(prev => ({
                                                                    ...prev,
                                                                    currentCommand: '',
                                                                    parentCheck: false
                                                                }));
                                                            }}
                                                            className="bg-green-500 text-white px-8 py-3 rounded-lg font-semibold hover:bg-green-600"
                                                        >
                                                            ✅ Wykonał Poprawnie
                                                        </button>

                                                        <button
                                                            onClick={() => {
                                                                updateAdaptive(false);
                                                                setAudioMotorState(prev => ({
                                                                    ...prev,
                                                                    currentCommand: '',
                                                                    parentCheck: false
                                                                }));
                                                            }}
                                                            className="bg-red-500 text-white px-8 py-3 rounded-lg font-semibold hover:bg-red-600"
                                                        >
                                                            ❌ Nie Wykonał / Błędnie
                                                        </button>
                                                    </div>
                                                </div>
                                            )}
                                        </div>
                                    )}
                                </div>
                            )}
                        </div>
                    </div>

                    {/* Panel terapeuty */}
                    {showParentPanel && (
                        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
                            <div className="bg-white rounded-lg p-6 max-w-2xl w-full max-h-96 overflow-y-auto">
                                <div className="flex justify-between items-center mb-4">
                                    <h3 className="text-xl font-bold text-gray-800">
                                        📊 Panel Terapeuty
                                    </h3>
                                    <button
                                        onClick={() => setShowParentPanel(false)}
                                        className="text-gray-500 hover:text-gray-700"
                                    >
                                        ❌
                                    </button>
                                </div>

                                <div className="grid grid-cols-2 gap-4 mb-6">
                                    <div className="bg-blue-50 p-4 rounded-lg">
                                        <h4 className="font-semibold text-blue-800">Czas sesji</h4>
                                        <p className="text-2xl font-bold text-blue-600">{formatTime(sessionTime)}</p>
                                    </div>

                                    <div className="bg-green-50 p-4 rounded-lg">
                                        <h4 className="font-semibold text-green-800">Aktualny SNR</h4>
                                        <p className={`text-2xl font-bold ${getSNRColor(useManualSNR ? manualSNR : adaptiveState.currentSNR)}`}>
                                            {(useManualSNR ? manualSNR : adaptiveState.currentSNR).toFixed(1)}dB
                                        </p>
                                    </div>

                                    <div className="bg-purple-50 p-4 rounded-lg">
                                        <h4 className="font-semibold text-purple-800">Seria poprawnych</h4>
                                        <p className="text-2xl font-bold text-purple-600">{adaptiveState.correctStreak}</p>
                                    </div>

                                    <div className="bg-orange-50 p-4 rounded-lg">
                                        <h4 className="font-semibold text-orange-800">Zmęczenie</h4>
                                        <p className="text-2xl font-bold text-orange-600">{fatigueLevel.toFixed(0)}%</p>
                                    </div>
                                </div>

                                <div className="bg-gray-50 p-4 rounded-lg mb-4">
                                    <h4 className="font-semibold text-gray-800 mb-2">📈 Historia SNR</h4>
                                    <div className="text-sm text-gray-600">
                                        {adaptiveState.history.length > 0 ? (
                                            <p>Ostatnie 10 wartości: {adaptiveState.history.slice(-10).map(snr => snr.toFixed(1)).join(', ')}dB</p>
                                        ) : (
                                            <p>Brak danych historycznych</p>
                                        )}
                                    </div>
                                </div>

                                <div className="bg-blue-50 p-4 rounded-lg mb-4">
                                    <h4 className="font-semibold text-blue-800 mb-2">🔊 System Szumów</h4>
                                    <div className="text-sm text-blue-700">
                                        <p><strong>Aktywny typ szumu:</strong> {speechInNoiseState.noiseType} (mowa) | {soundRecognitionState.noiseType} (dźwięki)</p>
                                        <p><strong>Kanały audio:</strong> Dwukanałowe stereo z kontrolą SNR</p>
                                        <p><strong>Timing:</strong> Szum natychmiast → Mowa po 2s opóźnieniu</p>
                                    </div>
                                </div>

                                <div className="mt-4 flex gap-2">
                                    <button
                                        onClick={() => {
                                            const report = {
                                                sessionTime: formatTime(sessionTime),
                                                currentSNR: useManualSNR ? manualSNR : adaptiveState.currentSNR,
                                                correctStreak: adaptiveState.correctStreak,
                                                reversals: adaptiveState.reversals,
                                                history: adaptiveState.history,
                                                module: currentModule,
                                                noiseTypes: {
                                                    speech: speechInNoiseState.noiseType,
                                                    sounds: soundRecognitionState.noiseType
                                                },
                                                timestamp: new Date().toLocaleString('pl-PL')
                                            };

                                            const blob = new Blob([JSON.stringify(report, null, 2)], {
                                                type: 'application/json'
                                            });
                                            const url = URL.createObjectURL(blob);
                                            const a = document.createElement('a');
                                            a.href = url;
                                            a.download = `raport-apd-${new Date().toISOString().split('T')[0]}.json`;
                                            a.click();
                                        }}
                                        className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600 flex items-center gap-2"
                                    >
                                        <Download />
                                        Eksport Raportu
                                    </button>
                                </div>
                            </div>
                        </div>
                    )}

                    {/* Przycisk przerwy */}
                    {fatigueLevel > 80 && (
                        <div className="fixed bottom-4 right-4 bg-red-500 text-white p-4 rounded-lg shadow-lg">
                            <p className="font-semibold">⚠️ Czas na przerwę!</p>
                            <button
                                onClick={() => setFatigueLevel(0)}
                                className="bg-white text-red-500 px-3 py-1 rounded mt-2 text-sm"
                            >
                                Zrób przerwę
                            </button>
                        </div>
                    )}

                    {/* Skrypt informujący o konieczności przerwy */}
                    {fatigueLevel > 80 && (
                        <div className="fixed bottom-24 right-4 bg-red-500 text-white p-4 rounded-lg shadow-lg z-40">
                            <p className="font-semibold">⚠️ Czas na przerwę!</p>
                            <button
                                onClick={() => setFatigueLevel(0)}
                                className="bg-white text-red-500 px-3 py-1 rounded mt-2 text-sm font-medium hover:bg-gray-100 transition-colors"
                            >
                                Zrób przerwę
                            </button>
                        </div>
                    )}

                    {currentView === 'home' && <SEOContent />}
                </main>
            )}

            <Footer setCurrentView={setCurrentView} />
            <CookiesBanner />
        </div>
    );
}

export default TreningAPD;