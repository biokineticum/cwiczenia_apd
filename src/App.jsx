import React, { useState, useEffect, useRef, useCallback } from 'react';
import { Play, Pause, RotateCcw, Star, Volume2, Headphones, Brain, Target, Settings, Award, BarChart3, Timer, User, Download, Mic } from 'lucide-react';

const useSessionStats = (key, initialValue) => {
  const [stats, setStats] = useState(initialValue);
  
  useEffect(() => {
    const saved = localStorage.getItem(`apd_${key}`);
    if (saved) {
      setStats(JSON.parse(saved));
    }
  }, [key]);
  
  const updateStats = (newStats) => {
    const updated = typeof newStats === 'function' ? newStats(stats) : newStats;
    setStats(updated);
    localStorage.setItem(`apd_${key}`, JSON.stringify(updated));
  };
  
  return [stats, updateStats];
};

export default function KompletnyTreningAPD() {
  // Stan główny
  const [currentModule, setCurrentModule] = useState('speechInNoise');
  const [isPlaying, setIsPlaying] = useState(false);
  const [sessionTime, setSessionTime] = useState(0);
  const [fatigueLevel, setFatigueLevel] = useState(0);
  const [showParentPanel, setShowParentPanel] = useState(false);
  const [volumeCalibrated, setVolumeCalibrated] = useState(false);
  
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
    currentSNR: 15,
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
  
  // Sekwencje słuchowe
  const [sequenceState, setSequenceState] = useState({
    currentSequence: [],
    userSequence: [],
    sequenceLength: 3,
    stimulusType: 'words'
  });
  
  // Lateralizacja
  const [lateralizationState, setLateralizationState] = useState({
    currentEar: 'left',
    panningValue: -1
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
      'Podnieś lewą nogę'
    ],
    parentCheck: false
  });
  
  const audioContext = useRef(null);
  const sessionTimer = useRef(null);
  
  // Biblioteki danych
  const polishSentences = [
    'Kot siedzi na macie',
    'Pies biegnie po trawie',
    'Słońce świeci jasno',
    'Mama gotuje obiad',
    'Dzieci bawią się w ogrodzie',
    'Auto jedzie szybko',
    'Ptaki śpiewają rano',
    'Deszcz pada na dach',
    'Kwiaty rosną w doniczce',
    'Tata czyta gazetę'
  ];

  const sequenceWords = ['DOM', 'KOT', 'PIES', 'AUTO', 'SŁOŃCE', 'WODA', 'DRZEWO', 'MAMA'];
  const sequenceDigits = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];

  // Funkcje audio
  const initializeAudioContext = useCallback(() => {
    if (!audioContext.current) {
      audioContext.current = new (window.AudioContext || window.webkitAudioContext)();
    }
    return audioContext.current;
  }, []);

  // Generator szumów
  const generateNoise = (ctx, type, duration = 10) => {
    console.log(`T=${(Date.now() - window.testStartTime) / 1000}: GENEROWANIE SZUMU ${type.toUpperCase()}`);
    
    const bufferSize = ctx.sampleRate * duration;
    const noiseBuffer = ctx.createBuffer(2, bufferSize, ctx.sampleRate);

    for (let channel = 0; channel < noiseBuffer.numberOfChannels; channel++) {
      const channelData = noiseBuffer.getChannelData(channel);
      
      switch(type) {
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
          
        case 'classroom':
          for (let i = 0; i < bufferSize; i++) {
            let sample = (Math.random() * 2 - 1) * 0.4;
            // Dodaj losowe "bubbly" dźwięki symulujące rozmowy
            if (Math.random() < 0.001) {
              sample += Math.sin(i * 0.01 * Math.random()) * 0.3;
            }
            channelData[i] = sample;
          }
          break;
          
        case 'street':
          for (let i = 0; i < bufferSize; i++) {
            let sample = (Math.random() * 2 - 1) * 0.3;
            // Symuluj przejeżdżające samochody
            const carFreq = 0.0001 + Math.random() * 0.0002;
            if (Math.sin(i * carFreq) > 0.7) {
              sample += Math.sin(i * 0.005) * 0.4;
            }
            channelData[i] = sample;
          }
          break;
          
        case 'cafe':
          for (let i = 0; i < bufferSize; i++) {
            let sample = (Math.random() * 2 - 1) * 0.25;
            // Losowe "klinki" naczyń
            if (Math.random() < 0.0003) {
              sample += Math.sin(i * 0.1) * 0.6;
            }
            // Niski gwar rozmów
            sample += Math.sin(i * 0.001) * 0.1;
            channelData[i] = sample;
          }
          break;
          
        case 'rain':
          for (let i = 0; i < bufferSize; i++) {
            let sample = (Math.random() * 2 - 1) * 0.4;
            // Modulacja symulująca krople
            const modulation = Math.sin(i * 0.01) * 0.5 + 0.5;
            channelData[i] = sample * modulation;
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
  };

  // Odtwarzanie z panningiem
  const playWithPanning = (frequency, pan = 0, duration = 1000) => {
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
  };

  // Test równoległych kanałów - KLUCZ APLIKACJI!
  const playParallelChannelsTest = (noiseType, speechText, snr = 10) => {
    window.testStartTime = Date.now(); // Śledzenie czasu dla logów
    
    const ctx = initializeAudioContext();
    console.log(`T=0.000: ROZPOCZYNAM TEST RÓWNOLEGŁYCH KANAŁÓW`);
    console.log(`T=0.000: Szum: ${noiseType}, SNR: ${snr}dB, Tekst: "${speechText}"`);
    
    // KANAŁ 1: SZUM - startuje NATYCHMIAST
    const noiseBuffer = generateNoise(ctx, noiseType, 10);
    const noiseSource = ctx.createBufferSource();
    const noiseGain = ctx.createGain();
    
    noiseSource.buffer = noiseBuffer;
    
    // Oblicz poziom szumu na podstawie SNR
    const noiseLevel = Math.pow(10, -snr/20) * 0.5;
    noiseGain.gain.setValueAtTime(noiseLevel, ctx.currentTime);
    console.log(`T=0.000: SZUM ${noiseType.toUpperCase()} ROZPOCZĘTY - poziom: ${noiseLevel.toFixed(3)}`);
    
    noiseSource.connect(noiseGain);
    noiseGain.connect(ctx.destination);
    noiseSource.start(ctx.currentTime);
    noiseSource.stop(ctx.currentTime + 10);
    
    // KANAŁ 2: MOWA - startuje po 2-2.5 sekundach (gdy szum już gra!)
    const speechDelay = 2 + Math.random() * 0.5; // 2-2.5s
    console.log(`T=${speechDelay.toFixed(3)}: MOWA ZAPLANOWANA`);
    
    setTimeout(() => {
      console.log(`T=${(Date.now() - window.testStartTime) / 1000}: MOWA START - "${speechText}"`);
      
      // Użyj Web Speech API dla mowy
      if ('speechSynthesis' in window) {
        const utterance = new SpeechSynthesisUtterance(speechText);
        utterance.lang = 'pl-PL';
        utterance.rate = 0.8;
        utterance.volume = 0.7; // Sygnał na poziomie odniesienia
        
        utterance.onstart = () => {
          console.log(`T=${(Date.now() - window.testStartTime) / 1000}: SYNTEZA MOWY ROZPOCZĘTA`);
        };
        
        utterance.onend = () => {
          console.log(`T=${(Date.now() - window.testStartTime) / 1000}: SYNTEZA MOWY ZAKOŃCZONA`);
        };
        
        window.speechSynthesis.speak(utterance);
      } else {
        console.log(`T=${(Date.now() - window.testStartTime) / 1000}: BRAK SPEECH SYNTHESIS - symulacja mowy`);
        // Fallback: ton reprezentujący mowę
        const speechTone = ctx.createOscillator();
        const speechGain = ctx.createGain();
        
        speechTone.frequency.setValueAtTime(200, ctx.currentTime);
        speechTone.type = 'sawtooth';
        speechGain.gain.setValueAtTime(0.4, ctx.currentTime);
        
        speechTone.connect(speechGain);
        speechGain.connect(ctx.destination);
        speechTone.start();
        speechTone.stop(ctx.currentTime + 3);
      }
    }, speechDelay * 1000);
    
    // Log końcowy
    setTimeout(() => {
      console.log(`T=${(Date.now() - window.testStartTime) / 1000}: TEST ZAKOŃCZONY - równoległe kanały przez ${speechDelay + 3}s`);
    }, (speechDelay + 4) * 1000);
  };

  // Test dźwięków zwierząt z szumem
  const playSoundWithNoise = (soundText, noiseType, snr = 15) => {
    window.testStartTime = Date.now();
    
    const ctx = initializeAudioContext();
    console.log(`T=0.000: TEST DŹWIĘKU Z SZUMEM: "${soundText}"`);
    
    // Szum startuje natychmiast
    const noiseBuffer = generateNoise(ctx, noiseType, 8);
    const noiseSource = ctx.createBufferSource();
    const noiseGain = ctx.createGain();
    
    noiseSource.buffer = noiseBuffer;
    const noiseLevel = Math.pow(10, -snr/20) * 0.4;
    noiseGain.gain.setValueAtTime(noiseLevel, ctx.currentTime);
    
    noiseSource.connect(noiseGain);
    noiseGain.connect(ctx.destination);
    noiseSource.start(ctx.currentTime);
    noiseSource.stop(ctx.currentTime + 8);
    
    console.log(`T=0.000: SZUM ZWIERZĘCY ${noiseType.toUpperCase()} ROZPOCZĘTY`);
    
    // Dźwięk zwierzęcia po 2s
    setTimeout(() => {
      console.log(`T=${(Date.now() - window.testStartTime) / 1000}: DŹWIĘK ZWIERZĘCIA: "${soundText}"`);
      
      if ('speechSynthesis' in window) {
        const utterance = new SpeechSynthesisUtterance(soundText);
        utterance.lang = 'pl-PL';
        utterance.rate = 1.2;
        utterance.volume = 0.8;
        utterance.pitch = 1.5; // Wyższy ton dla dźwięków zwierząt
        
        window.speechSynthesis.speak(utterance);
      }
    }, 2000);
  };

  // Sekwencje słuchowe
  const playSequence = (sequence, type) => {
    const ctx = initializeAudioContext();
    
    sequence.forEach((item, index) => {
      setTimeout(() => {
        if (type === 'tones') {
          const freq = 200 + (item * 100);
          playWithPanning(freq, 0, 500);
        } else {
          // Mowa
          const utterance = new SpeechSynthesisUtterance(item);
          utterance.lang = 'pl-PL';
          utterance.rate = 0.9;
          window.speechSynthesis.speak(utterance);
        }
      }, index * 1000);
    });
  };

  // Algorytm adaptacyjny 2-down-1-up
  const updateAdaptive = (correct) => {
    setAdaptiveState(prev => {
      const newHistory = [...prev.history, {
        timestamp: Date.now(),
        snr: prev.currentSNR,
        correct,
      }];
      
      let newSNR = prev.currentSNR;
      let newStreak = correct ? prev.correctStreak + 1 : 0;
      let newReversals = prev.reversals;
      let newStepSize = prev.stepSize;
      
      if (correct) {
        // 2 poprawne z rzędu = zwiększ trudność (zmniejsz SNR)
        if (newStreak >= 2) {
          newSNR = Math.max(-20, prev.currentSNR - newStepSize);
          newStreak = 0;
          newReversals++;
          
          // Zmniejsz krok po 4 odwróceniach
          if (newReversals > 4) {
            newStepSize = Math.max(0.5, newStepSize * 0.7);
          }
        }
      } else {
        // 1 błąd = zmniejsz trudność (zwiększ SNR)
        newSNR = Math.min(30, prev.currentSNR + newStepSize);
        newStreak = 0;
        newReversals++;
        
        if (newReversals > 4) {
          newStepSize = Math.max(0.5, newStepSize * 0.7);
        }
      }
      
      return {
        correctStreak: newStreak,
        reversals: newReversals,
        currentSNR: Math.round(newSNR * 10) / 10,
        stepSize: newStepSize,
        history: newHistory
      };
    });
  };

  // Timer sesji
  useEffect(() => {
    if (isPlaying) {
      sessionTimer.current = setInterval(() => {
        setSessionTime(prev => prev + 1);
        setFatigueLevel(prev => Math.min(100, prev + 0.1));
      }, 1000);
    } else {
      clearInterval(sessionTimer.current);
    }
    
    return () => clearInterval(sessionTimer.current);
  }, [isPlaying]);

  // Format czasu
  const formatTime = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  // Eksport CSV
  const exportToCsv = () => {
    const csvContent = [
      ['Data', 'Moduł', 'SNR', 'Poprawne', 'Czas sesji'],
      ...adaptiveState.history.map(entry => [
        new Date(entry.timestamp).toLocaleDateString(),
        currentModule,
        entry.snr,
        entry.correct ? 'Tak' : 'Nie',
        formatTime(sessionTime)
      ])
    ].map(row => row.join(',')).join('\n');
    
    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `trening_apd_${new Date().toISOString().split('T')[0]}.csv`;
    a.click();
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-purple-50 p-4">
      {/* Kalibracja głośności */}
      {!volumeCalibrated && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-8 max-w-md">
            <h3 className="text-xl font-bold mb-4">Kalibracja Głośności</h3>
            <p className="text-gray-600 mb-4">
              Ustaw głośność tak, aby dźwięk był komfortowo słyszalny.
            </p>
            <button
              onClick={() => playWithPanning(1000, 0, 500)}
              className="bg-blue-500 text-white px-4 py-2 rounded mr-2"
            >
              Test dźwięku
            </button>
            <button
              onClick={() => setVolumeCalibrated(true)}
              className="bg-green-500 text-white px-4 py-2 rounded"
            >
              Gotowe
            </button>
            <p className="text-xs text-gray-500 mt-4">
              💡 Zalecane: słuchawki nauszne
            </p>
          </div>
        </div>
      )}
      
      {/* Header */}
      <div className="text-center mb-6">
        <h1 className="text-3xl font-bold text-gray-800 mb-2">
          Amatorski Trening Słuchu dla Dzieci
        </h1>
        <p className="text-gray-600">Równoległe kanały audio - szum + sygnał</p>
      </div>
      
      {/* Status bar */}
      <div className="bg-white rounded-lg p-4 mb-6 shadow-sm">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-6">
            <div className="flex items-center gap-2">
              <Timer size={20} className="text-blue-500" />
              <span>Czas: {formatTime(sessionTime)}</span>
            </div>
            <div className="flex items-center gap-2">
              <span>Zmęczenie:</span>
              <div className="w-24 h-2 bg-gray-200 rounded">
                <div 
                  className={`h-full rounded transition-all ${
                    fatigueLevel < 40 ? 'bg-green-400' : 
                    fatigueLevel < 70 ? 'bg-yellow-400' : 'bg-red-400'
                  }`}
                  style={{ width: `${fatigueLevel}%` }}
                />
              </div>
            </div>
            <div className="text-sm text-gray-600">
              SNR: {adaptiveState.currentSNR}dB
            </div>
          </div>
          
          <div className="flex gap-2">
            <button
              onClick={() => setShowParentPanel(!showParentPanel)}
              className="bg-gray-500 text-white px-4 py-2 rounded hover:bg-gray-600"
            >
              <User size={16} className="inline mr-1" />
              Panel Rodzica
            </button>
            <button
              onClick={exportToCsv}
              className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
            >
              <Download size={16} className="inline mr-1" />
              Eksport CSV
            </button>
          </div>
        </div>
      </div>

      {/* Panel Rodzica */}
      {showParentPanel && (
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mb-6">
          <h3 className="font-bold mb-3">📊 Panel dla Rodzica/Terapeuty</h3>
          <div className="grid grid-cols-3 gap-4 mb-4">
            <div className="bg-white p-3 rounded">
              <div className="text-2xl font-bold text-green-600">
                {Math.round((adaptiveState.history.filter(h => h.correct).length / Math.max(1, adaptiveState.history.length)) * 100)}%
              </div>
              <div className="text-sm text-gray-600">Skuteczność</div>
            </div>
            <div className="bg-white p-3 rounded">
              <div className="text-2xl font-bold text-blue-600">{adaptiveState.currentSNR}dB</div>
              <div className="text-sm text-gray-600">Aktualny SNR</div>
            </div>
            <div className="bg-white p-3 rounded">
              <div className="text-2xl font-bold text-purple-600">{adaptiveState.history.length}</div>
              <div className="text-sm text-gray-600">Próby łącznie</div>
            </div>
          </div>
          <div className="text-sm text-gray-600 mb-2">
            <strong>Interpretacja SNR:</strong> Im niższy SNR, tym trudniejsze zadanie. 
            Wartości poniżej 0dB oznaczają że szum jest głośniejszy niż sygnał.
          </div>
          <div className="text-sm text-gray-600">
            <strong>Algorytm:</strong> 2-poprawne-w-dół, 1-błędne-w-górę (staircase adaptacyjne)
          </div>
        </div>
      )}

      {/* Nawigacja modułów */}
      <div className="flex flex-wrap gap-2 mb-6 justify-center">
        {[
          { id: 'speechInNoise', name: '🗣️ Mowa w szumie', icon: Mic },
          { id: 'soundRecognition', name: '🎵 Rozpoznawanie dźwięków', icon: Volume2 },
          { id: 'auditorySequencing', name: '🔢 Sekwencje słuchowe', icon: BarChart3 },
          { id: 'lateralization', name: '👂 Lateralizacja', icon: Headphones },
          { id: 'audioMotor', name: '🏃 Słuch + ruch', icon: Target }
        ].map(module => (
          <button
            key={module.id}
            onClick={() => setCurrentModule(module.id)}
            className={`px-4 py-2 rounded-lg font-semibold transition-all ${
              currentModule === module.id
                ? 'bg-blue-600 text-white shadow-lg'
                : 'bg-white text-gray-700 hover:bg-blue-50 border border-gray-200'
            }`}
          >
            <module.icon size={16} className="inline mr-2" />
            {module.name}
          </button>
        ))}
      </div>

      {/* Moduly treningowe */}
      <div className="bg-white rounded-lg p-6 shadow-sm">
        {/* Modul: Mowa w szumie */}
        {currentModule === 'speechInNoise' && (
          <div className="space-y-6">
            <div className="bg-blue-50 rounded-lg p-4">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-blue-800">
                  SNR: {adaptiveState.currentSNR}dB
                </h3>
                <div className="text-sm text-gray-600">
                  🎵 Równoległe kanały: mowa + szum
                </div>
              </div>
              
              <div className="bg-white border border-blue-200 rounded-lg p-3 mb-4">
                <div className="flex items-center justify-between mb-2">
                  <label className="text-sm font-semibold text-blue-700">Typ szumu tła:</label>
                  <select
                    value={speechInNoiseState.noiseType}
                    onChange={(e) => setSpeechInNoiseState(prev => ({ ...prev, noiseType: e.target.value }))}
                    className="px-2 py-1 text-sm border rounded focus:border-blue-400"
                  >
                    <option value="white">🎵 Biały (równomierny)</option>
                    <option value="pink">🌸 Różowy (naturalny)</option>
                    <option value="brown">🌳 Brązowy (głębokie tony)</option>
                    <option value="classroom">🏫 Gwar szkolny</option>
                    <option value="street">🚗 Ruch uliczny</option>
                    <option value="cafe">☕ Tło kawiarni</option>
                    <option value="rain">🌧️ Odgłos deszczu</option>
                  </select>
                </div>
                <p className="text-xs text-blue-600">
                  Różne typy szumu symulują rzeczywiste środowiska akustyczne
                </p>
              </div>
              
              <div className="bg-yellow-100 border border-yellow-300 rounded-lg p-3 mb-4">
                <p className="text-sm text-yellow-800">
                  🔊 <strong>T=0s:</strong> {speechInNoiseState.noiseType} szum rozpoczyna<br/>
                  🗣️ <strong>T=2s:</strong> Zdanie wypowiadane PODCZAS szumu<br/>
                  ⏱️ <strong>Test:</strong> 10 sekund równoległego odtwarzania
                </p>
              </div>
              
              <button
                onClick={() => {
                  const sentence = polishSentences[Math.floor(Math.random() * polishSentences.length)];
                  setSpeechInNoiseState(prev => ({
                    ...prev,
                    currentSentence: sentence,
                    sentenceWords: sentence.toLowerCase().split(' '),
                    userInput: ''
                  }));
                  
                  playParallelChannelsTest(speechInNoiseState.noiseType, sentence, adaptiveState.currentSNR);
                }}
                className="bg-blue-600 text-white px-6 py-3 rounded-lg font-semibold hover:bg-blue-700 transition-colors"
              >
                ▶️ Rozpocznij Test Równoległych Kanałów
              </button>
            </div>
            
            {speechInNoiseState.currentSentence && (
              <div className="bg-gray-50 rounded-lg p-4">
                <h4 className="font-semibold mb-3">Wpisz usłyszane zdanie:</h4>
                <input
                  type="text"
                  value={speechInNoiseState.userInput}
                  onChange={(e) => setSpeechInNoiseState(prev => ({ ...prev, userInput: e.target.value }))}
                  className="w-full p-3 border rounded-lg text-lg"
                  placeholder="Wpisz co usłyszałeś..."
                />
                
                <div className="flex gap-4 mt-4">
                  <button
                    onClick={() => {
                      const correct = speechInNoiseState.userInput.toLowerCase().trim() === 
                                    speechInNoiseState.currentSentence.toLowerCase();
                      updateAdaptive(correct);
                      
                      setSpeechInNoiseState(prev => ({
                        ...prev,
                        currentSentence: '',
                        userInput: ''
                      }));
                    }}
                    className="bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600"
                  >
                    ✅ Sprawdź
                  </button>
                  
                  <button
                    onClick={() => setSpeechInNoiseState(prev => ({ ...prev, currentSentence: '', userInput: '' }))}
                    className="bg-gray-500 text-white px-4 py-2 rounded hover:bg-gray-600"
                  >
                    ↻ Reset
                  </button>
                </div>
                
                <div className="mt-4 text-sm text-gray-600">
                  <strong>Wzór:</strong> {speechInNoiseState.currentSentence}
                </div>
              </div>
            )}
          </div>
        )}

        {/* Modul: Rozpoznawanie dźwięków */}
        {currentModule === 'soundRecognition' && (
          <div className="space-y-6">
            <div className="bg-green-50 rounded-lg p-4">
              <h3 className="text-lg font-semibold text-green-800 mb-4">
                🎵 Rozpoznawanie Dźwięków w Szumie
              </h3>
              
              <div className="bg-yellow-100 border border-yellow-300 rounded-lg p-3 mb-4">
                <p className="text-sm text-yellow-800">
                  🔊 <strong>T=0s:</strong> Szum {soundRecognitionState.noiseType} rozpoczyna<br/>
                  🐕 <strong>T=2s:</strong> Dźwięk zwierzęcia PODCZAS szumu<br/>
                  🎯 <strong>SNR:</strong> {soundRecognitionState.currentSNR}dB
                </p>
              </div>
              
              <button
                onClick={() => {
                  const randomSound = soundRecognitionState.soundsLibrary[
                    Math.floor(Math.random() * soundRecognitionState.soundsLibrary.length)
                  ];
                  
                  // Wybierz 4 losowe opcje, w tym poprawną
                  const wrongOptions = soundRecognitionState.soundsLibrary
                    .filter(s => s !== randomSound)
                    .sort(() => 0.5 - Math.random())
                    .slice(0, 3);
                  
                  const allOptions = [...wrongOptions, randomSound]
                    .sort(() => 0.5 - Math.random());
                  
                  setSoundRecognitionState(prev => ({
                    ...prev,
                    options: allOptions,
                    correctSound: randomSound.name
                  }));
                  
                  playSoundWithNoise(randomSound.sound, soundRecognitionState.noiseType, soundRecognitionState.currentSNR);
                }}
                className="bg-green-600 text-white px-6 py-3 rounded-lg font-semibold hover:bg-green-700"
              >
                ▶️ Zagraj Dźwięk z Szumem
              </button>
            </div>
            
            {soundRecognitionState.options.length > 0 && (
              <div className="bg-gray-50 rounded-lg p-4">
                <h4 className="font-semibold mb-4 text-center">Który dźwięk usłyszałeś?</h4>
                <div className="grid grid-cols-2 gap-4">
                  {soundRecognitionState.options.map((sound, index) => (
                    <button
                      key={index}
                      onClick={() => {
                        const correct = sound.name === soundRecognitionState.correctSound;
                        updateAdaptive(correct);
                        
                        setTimeout(() => {
                          setSoundRecognitionState(prev => ({
                            ...prev,
                            options: [],
                            correctSound: ''
                          }));
                        }, 1500);
                      }}
                      className="bg-white border-4 border-green-200 rounded-xl p-6 hover:border-green-400 text-center transition-all transform hover:scale-105 shadow-lg"
                    >
                      <div className="text-6xl mb-3">{sound.image}</div>
                      <div className="text-lg font-semibold text-gray-700">{sound.name}</div>
                    </button>
                  ))}
                </div>
              </div>
            )}
            
            {soundRecognitionState.options.length === 0 && (
              <div className="text-center text-gray-500 py-8">
                Kliknij przycisk wyżej żeby zacząć test!
              </div>
            )}
          </div>
        )}

        {/* Modul: Sekwencje słuchowe */}
        {currentModule === 'auditorySequencing' && (
          <div className="space-y-6">
            <div className="bg-purple-50 rounded-lg p-4">
              <h3 className="text-lg font-semibold text-purple-800 mb-4">
                🔢 Zapamiętaj Sekwencję
              </h3>
              
              <div className="flex gap-4 mb-4">
                <select
                  value={sequenceState.stimulusType}
                  onChange={(e) => setSequenceState(prev => ({ ...prev, stimulusType: e.target.value }))}
                  className="px-3 py-2 border rounded"
                >
                  <option value="words">📝 Słowa</option>
                  <option value="digits">🔢 Cyfry</option>
                  <option value="tones">🎵 Tony</option>
                </select>
                
                <select
                  value={sequenceState.sequenceLength}
                  onChange={(e) => setSequenceState(prev => ({ ...prev, sequenceLength: parseInt(e.target.value) }))}
                  className="px-3 py-2 border rounded"
                >
                  <option value={3}>3 elementy</option>
                  <option value={4}>4 elementy</option>
                  <option value={5}>5 elementów</option>
                </select>
              </div>
              
              <button
                onClick={() => {
                  const source = sequenceState.stimulusType === 'digits' ? sequenceDigits : sequenceWords;
                  const sequence = [];
                  for (let i = 0; i < sequenceState.sequenceLength; i++) {
                    sequence.push(source[Math.floor(Math.random() * source.length)]);
                  }
                  
                  setSequenceState(prev => ({
                    ...prev,
                    currentSequence: sequence,
                    userSequence: []
                  }));
                  
                  playSequence(sequence, sequenceState.stimulusType);
                }}
                className="bg-purple-600 text-white px-6 py-3 rounded-lg font-semibold hover:bg-purple-700"
              >
                ▶️ Odtwórz Sekwencję
              </button>
            </div>
            
            {sequenceState.currentSequence.length > 0 && (
              <div className="bg-gray-50 rounded-lg p-4">
                <h4 className="font-semibold mb-4">Powtórz sekwencję w tej samej kolejności:</h4>
                
                <div className="grid grid-cols-3 gap-2 mb-4">
                  {(sequenceState.stimulusType === 'digits' ? sequenceDigits : sequenceWords).map(item => (
                    <button
                      key={item}
                      onClick={() => {
                        if (sequenceState.userSequence.length < sequenceState.currentSequence.length) {
                          setSequenceState(prev => ({
                            ...prev,
                            userSequence: [...prev.userSequence, item]
                          }));
                        }
                      }}
                      className="bg-white border-2 border-purple-200 rounded-lg p-3 hover:border-purple-400 transition-colors"
                    >
                      {item} {sequenceState.stimulusType === 'words' ? '📝' : '🔢'}
                    </button>
                  ))}
                </div>
                
                <div className="bg-white border rounded-lg p-3 mb-4">
                  <div className="text-sm text-gray-600 mb-2">Twoja sekwencja:</div>
                  <div className="flex gap-2">
                    {sequenceState.userSequence.map((item, index) => (
                      <span key={index} className="bg-purple-100 px-3 py-1 rounded">
                        {item}
                      </span>
                    ))}
                  </div>
                </div>
                
                {sequenceState.userSequence.length === sequenceState.currentSequence.length && (
                  <button
                    onClick={() => {
                      const correct = JSON.stringify(sequenceState.userSequence) === 
                                    JSON.stringify(sequenceState.currentSequence);
                      updateAdaptive(correct);
                      
                      setSequenceState(prev => ({
                        ...prev,
                        currentSequence: [],
                        userSequence: []
                      }));
                    }}
                    className="bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600"
                  >
                    ✅ Sprawdź
                  </button>
                )}
              </div>
            )}
          </div>
        )}

        {/* Modul: Lateralizacja */}
        {currentModule === 'lateralization' && (
          <div className="space-y-6">
            <div className="bg-orange-50 rounded-lg p-4">
              <h3 className="text-lg font-semibold text-orange-800 mb-4">
                👂 Test Lateralizacji (Lewe/Prawe Ucho)
              </h3>
              
              <button
                onClick={() => {
                  const pan = Math.random() > 0.5 ? -1 : 1;
                  const ear = pan < 0 ? 'left' : 'right';
                  
                  setLateralizationState({
                    currentEar: ear,
                    panningValue: pan
                  });
                  
                  playWithPanning(800, pan, 1000);
                }}
                className="bg-orange-600 text-white px-6 py-3 rounded-lg font-semibold hover:bg-orange-700"
              >
                ▶️ Odtwórz Dźwięk
              </button>
            </div>
            
            {lateralizationState.currentEar && (
              <div className="bg-gray-50 rounded-lg p-4">
                <h4 className="font-semibold mb-4 text-center">Z której strony słyszysz dźwięk?</h4>
                
                <div className="flex gap-8 justify-center">
                  <button
                    onClick={() => {
                      const correct = lateralizationState.currentEar === 'left';
                      updateAdaptive(correct);
                      setLateralizationState({ currentEar: '', panningValue: 0 });
                    }}
                    className="bg-white border-4 border-orange-200 rounded-xl p-8 hover:border-orange-400 text-center transition-all transform hover:scale-105"
                  >
                    <div className="text-6xl mb-2">👈</div>
                    <div className="text-xl font-semibold">Lewe ucho</div>
                  </button>
                  
                  <button
                    onClick={() => {
                      const correct = lateralizationState.currentEar === 'right';
                      updateAdaptive(correct);
                      setLateralizationState({ currentEar: '', panningValue: 0 });
                    }}
                    className="bg-white border-4 border-orange-200 rounded-xl p-8 hover:border-orange-400 text-center transition-all transform hover:scale-105"
                  >
                    <div className="text-6xl mb-2">👉</div>
                    <div className="text-xl font-semibold">Prawe ucho</div>
                  </button>
                </div>
              </div>
            )}
          </div>
        )}

        {/* Modul: Audio + Motor */}
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
                  
                  // Odtwórz polecenie
                  const utterance = new SpeechSynthesisUtterance(command);
                  utterance.lang = 'pl-PL';
                  utterance.rate = 0.8;
                  window.speechSynthesis.speak(utterance);
                }}
                className="bg-red-600 text-white px-6 py-3 rounded-lg font-semibold hover:bg-red-700"
              >
                ▶️ Odtwórz Polecenie
              </button>
            </div>
            
            {audioMotorState.currentCommand && (
              <div className="bg-gray-50 rounded-lg p-4">
                <div className="text-center mb-6">
                  <h4 className="text-2xl font-bold text-gray-800 mb-2">
                    {audioMotorState.currentCommand}
                  </h4>
                  <p className="text-gray-600">Wykonaj polecenie!</p>
                </div>
                
                <div className="bg-yellow-100 border border-yellow-300 rounded-lg p-4 mb-4">
                  <p className="text-sm text-yellow-800">
                    <strong>Dla rodzica/terapeuty:</strong> Oceń czy dziecko poprawnie wykonało polecenie
                  </p>
                </div>
                
                <div className="flex gap-4 justify-center">
                  <button
                    onClick={() => {
                      updateAdaptive(true);
                      setAudioMotorState(prev => ({ ...prev, currentCommand: '', parentCheck: false }));
                    }}
                    className="bg-green-500 text-white px-6 py-3 rounded-lg font-semibold hover:bg-green-600"
                  >
                    ✅ Wykonał poprawnie
                  </button>
                  
                  <button
                    onClick={() => {
                      updateAdaptive(false);
                      setAudioMotorState(prev => ({ ...prev, currentCommand: '', parentCheck: false }));
                    }}
                    className="bg-red-500 text-white px-6 py-3 rounded-lg font-semibold hover:bg-red-600"
                  >
                    ❌ Nie wykonał / błędnie
                  </button>
                </div>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Przycisk przerwy przy wysokim zmęczeniu */}
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
    </div>
  );
}