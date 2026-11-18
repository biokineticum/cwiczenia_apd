import React, { useState, useEffect, useCallback, useRef } from 'react';
import Navbar from './components/Navbar';
import SEOContent from './components/SEOContent';
import PrivacyPolicy from './components/PrivacyPolicy';
import CookiesBanner from './components/CookiesBanner';
import Footer from './components/Footer';
import RewardsBar, { NewBadgeToast } from './components/RewardsBar';
import FeedbackBanner from './components/FeedbackBanner';
import MobileModuleNav from './components/MobileModuleNav';
import TherapistHint from './components/TherapistHint';
import {
  SENTENCES,
  AUDIO_MOTOR_COMMANDS,
  NOISE_OPTIONS,
  MODULE_META,
} from './lib/exerciseData';
import { pickWordSequence, WORD_SEQUENCE_LENGTHS } from './lib/wordPool';
import {
  getAudioContext,
  unlockAudio,
  stopAllAudio,
  playNoise,
  speakText,
  speakWordSequence,
  playTone,
  relativeNoiseGain,
  scoreSpeechAnswer,
  scoreExactSequence,
} from './lib/audio';
import { loadRewards, recordTrial } from './lib/gamification';

const Icon = {
  Timer: () => (
    <svg width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24" aria-hidden>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 7v5l3 2" />
    </svg>
  ),
  Download: () => (
    <svg width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24" aria-hidden>
      <path d="M12 3v12m0 0l4-4m-4 4l-4-4M5 21h14" />
    </svg>
  ),
  Mic: () => (
    <svg width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24" aria-hidden>
      <rect x="9" y="2" width="6" height="12" rx="3" />
      <path d="M5 10a7 7 0 0014 0M12 17v4m-4 0h8" />
    </svg>
  ),
  Volume: () => (
    <svg width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24" aria-hidden>
      <path d="M11 5L6 9H2v6h4l5 4V5z" />
      <path d="M15.5 8.5a5 5 0 010 7" />
    </svg>
  ),
  Headphones: () => (
    <svg width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24" aria-hidden>
      <path d="M3 18v-6a9 9 0 0118 0v6" />
      <path d="M21 19a2 2 0 01-2 2h-1a2 2 0 01-2-2v-3a2 2 0 012-2h3zM3 19a2 2 0 002 2h1a2 2 0 002-2v-3a2 2 0 00-2-2H3z" />
    </svg>
  ),
  Target: () => (
    <svg width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24" aria-hidden>
      <circle cx="12" cy="12" r="9" />
      <circle cx="12" cy="12" r="5" />
      <circle cx="12" cy="12" r="1" />
    </svg>
  ),
  Chart: () => (
    <svg width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24" aria-hidden>
      <path d="M4 19V5M4 19h16M8 17V10M12 17V7M16 17v-4" />
    </svg>
  ),
  Info: () => (
    <svg width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24" aria-hidden>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 8h.01M11 12h1v4h1" />
    </svg>
  ),
};

const MODULE_ICONS = {
  speechInNoise: <Icon.Mic />,
  soundRecognition: <Icon.Volume />,
  lateralization: <Icon.Headphones />,
  audioMotor: <Icon.Target />,
};

const MODULE_SHORT = {
  speechInNoise: 'Mowa',
  soundRecognition: 'Słowa',
  lateralization: 'L/P',
  audioMotor: 'Ruch',
};

function TreningAPD() {
  const [currentView, setCurrentView] = useState('home');
  const [currentModule, setCurrentModule] = useState('speechInNoise');
  const [sessionTime, setSessionTime] = useState(0);
  const [fatigueLevel, setFatigueLevel] = useState(0);
  const [showParentPanel, setShowParentPanel] = useState(false);
  const [volumeCalibrated, setVolumeCalibrated] = useState(false);
  const [manualSNR, setManualSNR] = useState(10);
  const [useManualSNR, setUseManualSNR] = useState(false);
  const [noiseEnabled, setNoiseEnabled] = useState(false);
  const [noiseType, setNoiseType] = useState('white');
  const [hideMotorText, setHideMotorText] = useState(false);

  const [adaptiveState, setAdaptiveState] = useState({
    correctStreak: 0,
    reversals: 0,
    currentSNR: 10,
    stepSize: 2,
    history: [],
  });

  const [speechInNoiseState, setSpeechInNoiseState] = useState({
    currentSentence: '',
    sentenceWords: [],
    userInput: '',
  });

  const [soundRecognitionState, setSoundRecognitionState] = useState({
    targetWords: [],
    userInput: '',
    sequenceLength: 3,
    lengthMode: 'fixed', // 'fixed' | 'random'
  });

  const [lateralizationState, setLateralizationState] = useState({
    mode: 'simple',
    currentEar: '',
    panningValue: 0,
    digitSequence: [],
    userDigitSequence: [],
    sequenceLength: 3,
  });

  const [audioMotorState, setAudioMotorState] = useState({
    currentCommand: '',
  });

  const [rewards, setRewards] = useState(() => ({ ...loadRewards(), sessionPoints: 0 }));
  const [feedback, setFeedback] = useState({ kind: null, message: '' });
  const [newBadges, setNewBadges] = useState([]);
  const digitTimersRef = useRef([]);
  const wordTimersRef = useRef([]);

  useEffect(() => {
    if (currentView !== 'home') return undefined;
    const timer = setInterval(() => {
      setSessionTime((prev) => prev + 1);
      setFatigueLevel((prev) => Math.min(100, prev + 0.08));
    }, 1000);
    return () => clearInterval(timer);
  }, [currentView]);

  useEffect(() => () => {
    stopAllAudio();
    digitTimersRef.current.forEach(clearTimeout);
    wordTimersRef.current.forEach(clearTimeout);
  }, []);

  const showFeedback = useCallback((kind, message) => {
    setFeedback({ kind, message });
  }, []);

  const applyTrialResult = useCallback(
    (isCorrect, moduleId) => {
      let gained = 0;
      let unlocked = [];
      setRewards((prev) => {
        const result = recordTrial(prev, {
          correct: isCorrect,
          moduleId,
          pointsIfCorrect: 10,
        });
        gained = result.gained;
        unlocked = result.newBadges;
        return result.state;
      });
      // Defer toast so state flush from setRewards is not raced by callers
      queueMicrotask(() => {
        if (unlocked.length) setNewBadges(unlocked);
        showFeedback(
          isCorrect ? 'success' : 'error',
          isCorrect
            ? gained
              ? `Brawo! +${gained} pkt`
              : 'Brawo!'
            : 'Spróbuj jeszcze raz — bez pośpiechu'
        );
      });
    },
    [showFeedback]
  );

  const updateAdaptive = useCallback((isCorrect) => {
    setAdaptiveState((prev) => {
      let newSNR = prev.currentSNR;
      let newStepSize = prev.stepSize;
      let newReversals = prev.reversals;

      if (isCorrect) {
        const newStreak = prev.correctStreak + 1;
        if (newStreak >= 2) {
          newSNR = Math.max(-20, newSNR - newStepSize);
          if (
            newSNR !== prev.currentSNR &&
            prev.history.length > 0 &&
            prev.history[prev.history.length - 1] > newSNR
          ) {
            newReversals += 1;
            newStepSize = newReversals >= 2 ? Math.max(0.5, newStepSize / 2) : newStepSize;
          }
        }
        return {
          ...prev,
          correctStreak: newStreak,
          currentSNR: newSNR,
          stepSize: newStepSize,
          reversals: newReversals,
          history: [...prev.history, newSNR],
        };
      }

      newSNR = Math.min(30, newSNR + newStepSize);
      if (prev.history.length > 0 && prev.history[prev.history.length - 1] < newSNR) {
        newReversals += 1;
        newStepSize = newReversals >= 2 ? Math.max(0.5, newStepSize / 2) : newStepSize;
      }
      return {
        ...prev,
        correctStreak: 0,
        currentSNR: newSNR,
        stepSize: newStepSize,
        reversals: newReversals,
        history: [...prev.history, newSNR],
      };
    });
  }, []);

  const effectiveSNR = useManualSNR ? manualSNR : adaptiveState.currentSNR;

  const overlayNoise = useCallback(
    (ctx, durationSec, scale = 0.5) => {
      if (!noiseEnabled || !ctx) return null;
      return playNoise(ctx, noiseType, durationSec, relativeNoiseGain(effectiveSNR, scale));
    },
    [noiseEnabled, noiseType, effectiveSNR]
  );

  const playSpeechStimulus = useCallback(
    async (speechText) => {
      await unlockAudio();
      stopAllAudio();
      const ctx = getAudioContext();
      if (!ctx) return;

      const withNoise = noiseEnabled;
      if (withNoise) {
        overlayNoise(ctx, 10, 0.5);
      }
      const speechDelay = withNoise ? 2000 + Math.random() * 500 : 200;
      const t = setTimeout(() => {
        speakText(speechText, { rate: 0.8, volume: 0.75 });
      }, speechDelay);
      wordTimersRef.current.push(t);
    },
    [noiseEnabled, overlayNoise]
  );

  const playWordSequenceStimulus = useCallback(
    async (words) => {
      await unlockAudio();
      stopAllAudio();
      wordTimersRef.current.forEach(clearTimeout);
      wordTimersRef.current = [];

      const ctx = getAudioContext();
      if (!ctx) return;

      const approxDuration = Math.max(8, words.length * 2.2);
      if (noiseEnabled) {
        overlayNoise(ctx, approxDuration, 0.4);
      }
      const startDelay = noiseEnabled ? 1200 : 150;
      const t = setTimeout(() => {
        speakWordSequence(words, { rate: 0.75, volume: 0.85, gapMs: 450 });
      }, startDelay);
      wordTimersRef.current.push(t);
    },
    [noiseEnabled, overlayNoise]
  );

  const playWithPanning = useCallback(
    async (frequency, pan = 0, duration = 1000) => {
      await unlockAudio();
      const ctx = getAudioContext();
      if (!ctx) return;
      if (noiseEnabled) {
        overlayNoise(ctx, Math.max(2, duration / 1000 + 0.5), 0.35);
      }
      playTone(ctx, frequency, pan, duration);
    },
    [noiseEnabled, overlayNoise]
  );

  const startSpeechInNoise = useCallback(async () => {
    await unlockAudio();
    const sentence = SENTENCES[Math.floor(Math.random() * SENTENCES.length)];
    const words = sentence.toLowerCase().split(' ');
    setSpeechInNoiseState((prev) => ({
      ...prev,
      currentSentence: sentence,
      sentenceWords: words,
      userInput: '',
    }));
    playSpeechStimulus(sentence);
  }, [playSpeechStimulus]);

  const checkSpeechAnswer = useCallback(() => {
    const { isCorrect } = scoreSpeechAnswer(
      speechInNoiseState.userInput,
      speechInNoiseState.sentenceWords
    );
    updateAdaptive(isCorrect);
    applyTrialResult(isCorrect, 'speechInNoise');
    setSpeechInNoiseState((prev) => ({
      ...prev,
      currentSentence: '',
      sentenceWords: [],
      userInput: '',
    }));
  }, [speechInNoiseState, updateAdaptive, applyTrialResult]);

  const startWordSequence = useCallback(async () => {
    await unlockAudio();
    const length =
      soundRecognitionState.lengthMode === 'random'
        ? WORD_SEQUENCE_LENGTHS[Math.floor(Math.random() * WORD_SEQUENCE_LENGTHS.length)]
        : soundRecognitionState.sequenceLength;
    const targetWords = pickWordSequence(length);
    setSoundRecognitionState((prev) => ({
      ...prev,
      targetWords,
      userInput: '',
      sequenceLength: length,
    }));
    playWordSequenceStimulus(targetWords);
  }, [soundRecognitionState.lengthMode, soundRecognitionState.sequenceLength, playWordSequenceStimulus]);

  const checkWordSequence = useCallback(() => {
    const { isCorrect } = scoreExactSequence(
      soundRecognitionState.userInput,
      soundRecognitionState.targetWords
    );
    updateAdaptive(isCorrect);
    applyTrialResult(isCorrect, 'soundRecognition');
    setSoundRecognitionState((prev) => ({
      ...prev,
      targetWords: [],
      userInput: '',
    }));
  }, [soundRecognitionState, updateAdaptive, applyTrialResult]);

  const startSimpleLateralization = useCallback(async () => {
    await unlockAudio();
    stopAllAudio();
    const ears = ['Lewe ucho', 'Prawe ucho'];
    const selectedEar = ears[Math.floor(Math.random() * ears.length)];
    const pan = selectedEar === 'Lewe ucho' ? -1 : 1;
    setLateralizationState((prev) => ({
      ...prev,
      currentEar: selectedEar,
      panningValue: pan,
    }));
    playWithPanning(800, pan, 1000);
  }, [playWithPanning]);

  const playDigitSequenceWithPanning = useCallback(
    async (sequence, onComplete) => {
      await unlockAudio();
      stopAllAudio();
      digitTimersRef.current.forEach(clearTimeout);
      digitTimersRef.current = [];

      const ctx = getAudioContext();
      if (!ctx) return;

      if (noiseEnabled) {
        overlayNoise(ctx, sequence.length * 2, 0.35);
      }

      sequence.forEach((digit, index) => {
        const t = setTimeout(() => {
          const pan = index % 2 === 0 ? -1 : 1;
          playTone(ctx, 400 + digit * 50, pan, 200);
          const t2 = setTimeout(() => {
            speakText(String(digit), { rate: 0.6, volume: 0.9 });
          }, 300);
          digitTimersRef.current.push(t2);
          if (index === sequence.length - 1) {
            const t3 = setTimeout(onComplete, 2000);
            digitTimersRef.current.push(t3);
          }
        }, index * 1500);
        digitTimersRef.current.push(t);
      });
    },
    [noiseEnabled, overlayNoise]
  );

  const startDigitSequence = useCallback(async () => {
    const length = lateralizationState.sequenceLength;
    const sequence = Array.from({ length }, () => Math.floor(Math.random() * 10));
    setLateralizationState((prev) => ({
      ...prev,
      mode: 'sequence',
      digitSequence: sequence,
      userDigitSequence: [],
    }));
    playDigitSequenceWithPanning(sequence, () => {});
  }, [lateralizationState.sequenceLength, playDigitSequenceWithPanning]);

  const checkDigitSequence = useCallback(() => {
    const isCorrect =
      JSON.stringify(lateralizationState.digitSequence) ===
      JSON.stringify(lateralizationState.userDigitSequence);
    updateAdaptive(isCorrect);
    applyTrialResult(isCorrect, 'lateralization');
    setLateralizationState((prev) => ({
      ...prev,
      digitSequence: [],
      userDigitSequence: [],
    }));
  }, [lateralizationState, updateAdaptive, applyTrialResult]);

  const addDigitToSequence = useCallback((digit) => {
    setLateralizationState((prev) => ({
      ...prev,
      userDigitSequence: [...prev.userDigitSequence, digit],
    }));
  }, []);

  const formatTime = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const getSNRColor = (snr) => {
    if (snr < -10) return 'text-red-600';
    if (snr < 0) return 'text-orange-600';
    if (snr < 10) return 'text-yellow-700';
    if (snr < 20) return 'text-green-700';
    return 'text-sky-700';
  };

  const modules = Object.fromEntries(
    Object.entries(MODULE_META).map(([key, meta]) => [
      key,
      {
        ...meta,
        icon: MODULE_ICONS[key],
        shortName: MODULE_SHORT[key],
      },
    ])
  );

  const selectModule = async (key) => {
    await unlockAudio();
    stopAllAudio();
    setCurrentModule(key);
  };

  const primaryBtn =
    'w-full min-h-[52px] px-5 py-3.5 rounded-xl text-base font-semibold touch-manipulation active:scale-[0.98] transition';
  const secondaryBtn =
    'min-h-[48px] px-5 py-3 rounded-xl font-semibold touch-manipulation active:scale-[0.98] transition';

  return (
    <div className="min-h-screen bg-gradient-to-b from-sky-50 via-slate-50 to-teal-50 flex flex-col pt-14 md:pt-16 pb-24 md:pb-8">
      <Navbar currentView={currentView} setCurrentView={setCurrentView} />

      {currentView === 'privacy' ? (
        <main className="flex-grow">
          <PrivacyPolicy />
        </main>
      ) : (
        <main id="aplikacja" className="flex-grow max-w-7xl mx-auto w-full px-3 sm:px-4 md:px-6 lg:px-8">
          <header className="bg-white/90 backdrop-blur rounded-2xl shadow-sm border border-slate-100 p-4 sm:p-6 mb-4 sm:mb-6 mt-3 sm:mt-4">
            <div className="flex flex-col gap-4">
              <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3">
                <div className="text-center sm:text-left">
                  <h1 className="text-2xl sm:text-3xl font-bold text-slate-800 tracking-tight">
                    Trening APD
                  </h1>
                  <p className="text-slate-600 mt-1 text-sm sm:text-base">
                    Ćwiczenia wspomagające przetwarzanie słuchowe (nie diagnostyka)
                  </p>
                </div>
                <div className="flex items-center justify-center sm:justify-end gap-2 flex-wrap">
                  <div className="text-center px-3 py-2 rounded-xl bg-slate-50 min-h-[44px] flex flex-col justify-center">
                    <div className="flex items-center justify-center gap-1.5 text-slate-700 text-sm font-medium">
                      <Icon.Timer />
                      <span className="tabular-nums">{formatTime(sessionTime)}</span>
                    </div>
                    <div className="text-[10px] text-slate-500">Czas sesji</div>
                  </div>
                  <button
                    type="button"
                    onClick={() => setShowParentPanel(true)}
                    className={`${secondaryBtn} bg-slate-800 text-white px-4 flex items-center gap-2`}
                  >
                    <Icon.Chart />
                    <span className="text-sm">Panel</span>
                  </button>
                </div>
              </div>

              <RewardsBar rewards={rewards} />

              <div className="bg-slate-50 rounded-xl p-3 sm:p-4 border border-slate-100 space-y-3">
                <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                  <div>
                    <h3 className="font-semibold text-slate-800 text-sm sm:text-base">
                      Szum tła (opcjonalny)
                    </h3>
                    <p className="text-[11px] text-slate-500 mt-0.5">
                      Działa we wszystkich modułach. Wyłączony = czyste ćwiczenie.
                    </p>
                  </div>
                  <div className="flex items-center justify-center gap-3">
                    <span className={`text-xs font-medium ${!noiseEnabled ? 'text-teal-700' : 'text-slate-500'}`}>
                      WYŁ.
                    </span>
                    <label className="relative inline-flex items-center cursor-pointer min-h-[44px] min-w-[44px] justify-center">
                      <input
                        type="checkbox"
                        checked={noiseEnabled}
                        onChange={(e) => setNoiseEnabled(e.target.checked)}
                        className="sr-only peer"
                        aria-label="Włącz lub wyłącz szum tła"
                      />
                      <div className="w-11 h-6 bg-slate-200 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-teal-400 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[11px] after:left-[6px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-teal-600" />
                    </label>
                    <span className={`text-xs font-medium ${noiseEnabled ? 'text-teal-700' : 'text-slate-500'}`}>
                      WŁ.
                    </span>
                  </div>
                </div>

                {noiseEnabled ? (
                  <>
                    <NoisePicker value={noiseType} onChange={setNoiseType} accent="teal" />
                    <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
                      <span className="text-xs font-medium text-slate-600">Poziom trudności (względny)</span>
                      <div className="flex items-center justify-center gap-3">
                        <span className="text-xs font-medium text-slate-600">AUTO</span>
                        <label className="relative inline-flex items-center cursor-pointer min-h-[44px] min-w-[44px] justify-center">
                          <input
                            type="checkbox"
                            checked={useManualSNR}
                            onChange={(e) => setUseManualSNR(e.target.checked)}
                            className="sr-only peer"
                            aria-label="Przełącz tryb ręczny poziomu szumu"
                          />
                          <div className="w-11 h-6 bg-slate-200 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-teal-400 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[11px] after:left-[6px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-teal-600" />
                        </label>
                        <span className="text-xs font-medium text-slate-600">RĘCZNY</span>
                      </div>
                    </div>
                    {useManualSNR ? (
                      <div className="space-y-2">
                        <div className="flex items-center gap-3">
                          <input
                            type="range"
                            min="-20"
                            max="30"
                            step="0.5"
                            value={manualSNR}
                            onChange={(e) => setManualSNR(parseFloat(e.target.value))}
                            className="flex-1 h-3 accent-teal-600 cursor-pointer"
                            aria-valuemin={-20}
                            aria-valuemax={30}
                            aria-valuenow={manualSNR}
                            aria-label="Względny poziom szumu"
                          />
                          <span className={`text-base font-bold min-w-[4.5rem] tabular-nums ${getSNRColor(manualSNR)}`}>
                            {manualSNR.toFixed(1)}*
                          </span>
                        </div>
                        <p className="text-[11px] text-slate-500 text-center">
                          *Względny poziom szumu vs TTS — nie kalibrowany SNR kliniczny.
                        </p>
                      </div>
                    ) : (
                      <div className="text-center">
                        <span className={`text-lg font-bold tabular-nums ${getSNRColor(adaptiveState.currentSNR)}`}>
                          Auto: {adaptiveState.currentSNR.toFixed(1)}*
                        </span>
                        <p className="text-[11px] text-slate-500 mt-1">
                          Adaptacja: {adaptiveState.correctStreak} poprawnych · {adaptiveState.reversals} odwróceń
                        </p>
                      </div>
                    )}
                  </>
                ) : (
                  <p className="text-sm text-slate-600 text-center py-1">
                    Szum wyłączony — bodźce bez nakładki.
                  </p>
                )}
              </div>
            </div>
          </header>

          <div className="grid grid-cols-1 lg:grid-cols-4 gap-4 sm:gap-6">
            <aside className="hidden md:block lg:col-span-1 space-y-4">
              <div className="bg-white rounded-2xl shadow-sm border border-slate-100 p-4">
                <h2 className="text-lg font-semibold text-slate-800 mb-3">Moduły</h2>
                {Object.entries(modules).map(([key, module]) => (
                  <button
                    key={key}
                    type="button"
                    onClick={() => selectModule(key)}
                    className={`w-full mb-2 p-4 rounded-xl text-left transition touch-manipulation min-h-[56px] ${
                      currentModule === key
                        ? 'bg-teal-600 text-white shadow-md'
                        : 'bg-slate-50 text-slate-700 hover:bg-slate-100'
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      {module.icon}
                      <div>
                        <div className="font-semibold text-sm">{module.name}</div>
                        <div className="text-xs opacity-80">{module.description}</div>
                      </div>
                    </div>
                  </button>
                ))}
              </div>

              <CalibrationPanel
                volumeCalibrated={volumeCalibrated}
                setVolumeCalibrated={setVolumeCalibrated}
              />
            </aside>

            <div className="lg:col-span-3 space-y-4">
              <div className="md:hidden">
                <CalibrationPanel
                  volumeCalibrated={volumeCalibrated}
                  setVolumeCalibrated={setVolumeCalibrated}
                  compact
                />
              </div>

              {!volumeCalibrated ? (
                <div className="bg-amber-50 border border-amber-200 rounded-2xl p-6 sm:p-8 text-center">
                  <div className="text-4xl mb-3" aria-hidden>
                    🎧
                  </div>
                  <h3 className="text-xl font-semibold text-amber-900 mb-2">Najpierw kalibracja</h3>
                  <p className="text-amber-800 text-sm sm:text-base">
                    Załóż słuchawki stereo, odtwórz test i ustaw wygodną głośność urządzenia. Potem
                    potwierdź „Gotowe”.
                  </p>
                </div>
              ) : (
                <div className="space-y-4">
                  <div className="bg-sky-50 border border-sky-100 rounded-2xl p-4">
                    <div className="flex items-start gap-3">
                      <span className="text-sky-700 mt-0.5">
                        <Icon.Info />
                      </span>
                      <div className="text-sm text-sky-900 space-y-1">
                        <h4 className="font-semibold">{modules[currentModule].name}</h4>
                        <p>
                          <strong>Cel:</strong> {modules[currentModule].therapeutic.goal}
                        </p>
                        <p>
                          <strong>Jak ćwiczyć:</strong> {modules[currentModule].therapeutic.focus}
                        </p>
                        <p className="text-sky-800/90 text-xs sm:text-sm">
                          {modules[currentModule].therapeutic.note}
                        </p>
                      </div>
                    </div>
                  </div>

                  {currentModule === 'speechInNoise' && (
                    <section className="bg-emerald-50/80 rounded-2xl p-4 sm:p-5 border border-emerald-100">
                      <h3 className="text-lg font-semibold text-emerald-900 mb-2">Mowa w szumie</h3>
                      <p className="text-xs text-emerald-800 mb-3">
                        Szum: {noiseEnabled ? `włączony (${noiseType})` : 'wyłączony — czysta mowa'}.
                        Sterowanie globalne w nagłówku.
                      </p>
                      {!speechInNoiseState.currentSentence ? (
                        <button
                          type="button"
                          onClick={startSpeechInNoise}
                          className={`${primaryBtn} bg-emerald-600 text-white hover:bg-emerald-700`}
                        >
                          Start ćwiczenia
                        </button>
                      ) : (
                        <div className="space-y-4 mt-2">
                          <label className="block">
                            <span className="text-sm text-slate-600 mb-2 block">
                              Wpisz usłyszane zdanie
                            </span>
                            <input
                              type="text"
                              value={speechInNoiseState.userInput}
                              onChange={(e) =>
                                setSpeechInNoiseState((prev) => ({
                                  ...prev,
                                  userInput: e.target.value,
                                }))
                              }
                              enterKeyHint="done"
                              className="w-full min-h-[52px] p-3 border border-slate-300 rounded-xl text-base bg-white"
                              placeholder="Usłyszane zdanie…"
                              autoComplete="off"
                              autoCorrect="off"
                              autoCapitalize="off"
                            />
                          </label>
                          <div className="flex flex-col sm:flex-row gap-3">
                            <button
                              type="button"
                              onClick={() => playSpeechStimulus(speechInNoiseState.currentSentence)}
                              className={`${secondaryBtn} flex-1 bg-sky-600 text-white`}
                            >
                              Powtórz
                            </button>
                            <button
                              type="button"
                              onClick={checkSpeechAnswer}
                              disabled={!speechInNoiseState.userInput.trim()}
                              className={`${secondaryBtn} flex-1 bg-emerald-600 text-white disabled:bg-slate-300`}
                            >
                              Sprawdź
                            </button>
                          </div>
                          <TherapistHint>
                            Prawidłowe zdanie: „{speechInNoiseState.currentSentence}”
                          </TherapistHint>
                        </div>
                      )}
                    </section>
                  )}

                  {currentModule === 'soundRecognition' && (
                    <section className="bg-violet-50/80 rounded-2xl p-4 sm:p-5 border border-violet-100">
                      <h3 className="text-lg font-semibold text-violet-900 mb-2">
                        Sekwencje słów
                      </h3>
                      <p className="text-xs text-violet-800 mb-3">
                        Pula ~230 polskich słów. Usłysz 3–5 słów i wpisz je w kolejności.
                        Szum: {noiseEnabled ? 'włączony' : 'wyłączony'}.
                      </p>

                      <div className="bg-white rounded-xl p-3 mb-4 space-y-3">
                        <div className="flex flex-wrap gap-2">
                          <button
                            type="button"
                            onClick={() =>
                              setSoundRecognitionState((prev) => ({
                                ...prev,
                                lengthMode: 'fixed',
                              }))
                            }
                            className={`min-h-[44px] px-3 rounded-xl text-sm font-medium touch-manipulation ${
                              soundRecognitionState.lengthMode === 'fixed'
                                ? 'bg-violet-600 text-white'
                                : 'bg-slate-100 text-slate-700'
                            }`}
                          >
                            Stała długość
                          </button>
                          <button
                            type="button"
                            onClick={() =>
                              setSoundRecognitionState((prev) => ({
                                ...prev,
                                lengthMode: 'random',
                              }))
                            }
                            className={`min-h-[44px] px-3 rounded-xl text-sm font-medium touch-manipulation ${
                              soundRecognitionState.lengthMode === 'random'
                                ? 'bg-violet-600 text-white'
                                : 'bg-slate-100 text-slate-700'
                            }`}
                          >
                            Losowa 3–5
                          </button>
                        </div>
                        {soundRecognitionState.lengthMode === 'fixed' && (
                          <div className="flex items-center gap-2 flex-wrap">
                            <span className="text-sm text-slate-600">Liczba słów:</span>
                            {WORD_SEQUENCE_LENGTHS.map((num) => (
                              <button
                                key={num}
                                type="button"
                                onClick={() =>
                                  setSoundRecognitionState((prev) => ({
                                    ...prev,
                                    sequenceLength: num,
                                  }))
                                }
                                className={`min-w-[44px] min-h-[44px] rounded-lg font-semibold touch-manipulation ${
                                  soundRecognitionState.sequenceLength === num
                                    ? 'bg-violet-600 text-white'
                                    : 'bg-slate-100 text-slate-700'
                                }`}
                              >
                                {num}
                              </button>
                            ))}
                          </div>
                        )}
                      </div>

                      {soundRecognitionState.targetWords.length === 0 ? (
                        <button
                          type="button"
                          onClick={startWordSequence}
                          className={`${primaryBtn} bg-violet-600 text-white hover:bg-violet-700`}
                        >
                          Odtwórz sekwencję
                          {soundRecognitionState.lengthMode === 'fixed'
                            ? ` (${soundRecognitionState.sequenceLength})`
                            : ' (3–5)'}
                        </button>
                      ) : (
                        <div className="space-y-4">
                          <label className="block">
                            <span className="text-sm text-slate-600 mb-2 block">
                              Wpisz usłyszane słowa w kolejności (oddziel spacją)
                            </span>
                            <input
                              type="text"
                              value={soundRecognitionState.userInput}
                              onChange={(e) =>
                                setSoundRecognitionState((prev) => ({
                                  ...prev,
                                  userInput: e.target.value,
                                }))
                              }
                              enterKeyHint="done"
                              className="w-full min-h-[52px] p-3 border border-slate-300 rounded-xl text-base bg-white"
                              placeholder="np. dom kot woda"
                              autoComplete="off"
                              autoCorrect="off"
                              autoCapitalize="off"
                            />
                          </label>
                          <div className="flex flex-col sm:flex-row gap-3">
                            <button
                              type="button"
                              onClick={() =>
                                playWordSequenceStimulus(soundRecognitionState.targetWords)
                              }
                              className={`${secondaryBtn} flex-1 bg-sky-600 text-white`}
                            >
                              Powtórz
                            </button>
                            <button
                              type="button"
                              onClick={checkWordSequence}
                              disabled={!soundRecognitionState.userInput.trim()}
                              className={`${secondaryBtn} flex-1 bg-violet-600 text-white disabled:bg-slate-300`}
                            >
                              Sprawdź
                            </button>
                          </div>
                          <TherapistHint>
                            Sekwencja: {soundRecognitionState.targetWords.join(' · ')}
                          </TherapistHint>
                        </div>
                      )}
                    </section>
                  )}

                  {currentModule === 'lateralization' && (
                    <section className="bg-indigo-50/80 rounded-2xl p-4 sm:p-5 border border-indigo-100">
                      <h3 className="text-lg font-semibold text-indigo-900 mb-2">Lateralizacja</h3>
                      <p className="text-xs text-indigo-800 mb-3">
                        Wymagane słuchawki stereo. Na głośniku telefonu L/P nie działa poprawnie.
                        Szum: {noiseEnabled ? 'włączony (nagłówek)' : 'wyłączony'}.
                      </p>
                      <div className="bg-white rounded-xl p-3 mb-4">
                        <div className="grid grid-cols-2 gap-2">
                          {[
                            { id: 'simple', label: 'Proste L/P' },
                            { id: 'sequence', label: 'Sekwencje cyfr' },
                          ].map((mode) => (
                            <button
                              key={mode.id}
                              type="button"
                              onClick={() =>
                                setLateralizationState((prev) => ({ ...prev, mode: mode.id }))
                              }
                              className={`min-h-[48px] rounded-xl font-medium touch-manipulation ${
                                lateralizationState.mode === mode.id
                                  ? 'bg-indigo-600 text-white'
                                  : 'bg-slate-100 text-slate-700'
                              }`}
                            >
                              {mode.label}
                            </button>
                          ))}
                        </div>
                      </div>

                      {lateralizationState.mode === 'simple' && (
                        <div className="space-y-4">
                          {!lateralizationState.currentEar ? (
                            <button
                              type="button"
                              onClick={startSimpleLateralization}
                              className={`${primaryBtn} bg-indigo-600 text-white`}
                            >
                              Odtwórz dźwięk
                            </button>
                          ) : (
                            <div className="space-y-4">
                              <p className="text-center text-slate-600">Z której strony?</p>
                              <div className="grid grid-cols-2 gap-3">
                                {[
                                  { ear: 'Lewe ucho', label: 'Lewe', color: 'bg-sky-600' },
                                  { ear: 'Prawe ucho', label: 'Prawe', color: 'bg-rose-600' },
                                ].map((opt) => (
                                  <button
                                    key={opt.ear}
                                    type="button"
                                    onClick={() => {
                                      const isCorrect = lateralizationState.currentEar === opt.ear;
                                      updateAdaptive(isCorrect);
                                      applyTrialResult(isCorrect, 'lateralization');
                                      setLateralizationState((prev) => ({
                                        ...prev,
                                        currentEar: '',
                                        panningValue: 0,
                                      }));
                                    }}
                                    className={`${opt.color} text-white min-h-[64px] rounded-xl font-semibold text-lg touch-manipulation`}
                                  >
                                    {opt.label}
                                  </button>
                                ))}
                              </div>
                              <TherapistHint>
                                Prawidłowa odpowiedź: {lateralizationState.currentEar}
                              </TherapistHint>
                            </div>
                          )}
                        </div>
                      )}

                      {lateralizationState.mode === 'sequence' && (
                        <div className="space-y-4">
                          <div className="bg-white rounded-xl p-3">
                            <p className="text-sm font-medium mb-2">Długość sekwencji</p>
                            <div className="flex flex-wrap gap-2">
                              {[2, 3, 4, 5, 6, 7, 8].map((num) => (
                                <button
                                  key={num}
                                  type="button"
                                  onClick={() =>
                                    setLateralizationState((prev) => ({
                                      ...prev,
                                      sequenceLength: num,
                                    }))
                                  }
                                  className={`min-w-[44px] min-h-[44px] rounded-lg font-semibold touch-manipulation ${
                                    lateralizationState.sequenceLength === num
                                      ? 'bg-indigo-600 text-white'
                                      : 'bg-slate-100 text-slate-700'
                                  }`}
                                >
                                  {num}
                                </button>
                              ))}
                            </div>
                          </div>

                          {lateralizationState.digitSequence.length === 0 ? (
                            <button
                              type="button"
                              onClick={startDigitSequence}
                              className={`${primaryBtn} bg-indigo-600 text-white`}
                            >
                              Odtwórz sekwencję ({lateralizationState.sequenceLength})
                            </button>
                          ) : (
                            <div className="space-y-4">
                              <p className="text-center text-slate-600 text-sm">
                                Wpisz cyfry w kolejności (L–P–L–P…)
                              </p>
                              <p className="text-center font-mono text-lg">
                                [{lateralizationState.userDigitSequence.join(', ')}]
                              </p>
                              <div className="grid grid-cols-5 gap-2 max-w-sm mx-auto">
                                {[0, 1, 2, 3, 4, 5, 6, 7, 8, 9].map((digit) => (
                                  <button
                                    key={digit}
                                    type="button"
                                    onClick={() => addDigitToSequence(digit)}
                                    disabled={
                                      lateralizationState.userDigitSequence.length >=
                                      lateralizationState.digitSequence.length
                                    }
                                    className="bg-indigo-600 text-white text-xl min-h-[52px] rounded-xl font-bold touch-manipulation disabled:bg-slate-300"
                                  >
                                    {digit}
                                  </button>
                                ))}
                              </div>
                              <div className="flex flex-col sm:flex-row gap-3">
                                <button
                                  type="button"
                                  onClick={() =>
                                    setLateralizationState((prev) => ({
                                      ...prev,
                                      userDigitSequence: prev.userDigitSequence.slice(0, -1),
                                    }))
                                  }
                                  disabled={lateralizationState.userDigitSequence.length === 0}
                                  className={`${secondaryBtn} flex-1 bg-amber-500 text-white disabled:bg-slate-300`}
                                >
                                  Cofnij
                                </button>
                                <button
                                  type="button"
                                  onClick={checkDigitSequence}
                                  disabled={
                                    lateralizationState.userDigitSequence.length !==
                                    lateralizationState.digitSequence.length
                                  }
                                  className={`${secondaryBtn} flex-1 bg-emerald-600 text-white disabled:bg-slate-300`}
                                >
                                  Sprawdź
                                </button>
                              </div>
                              <TherapistHint>
                                Sekwencja: [{lateralizationState.digitSequence.join(', ')}]
                                <br />
                                <span className="text-xs">
                                  Wzór L/P:{' '}
                                  {lateralizationState.digitSequence
                                    .map((d, i) => `${d}(${i % 2 === 0 ? 'L' : 'P'})`)
                                    .join(' → ')}
                                </span>
                              </TherapistHint>
                            </div>
                          )}
                        </div>
                      )}
                    </section>
                  )}

                  {currentModule === 'audioMotor' && (
                    <section className="bg-rose-50/80 rounded-2xl p-4 sm:p-5 border border-rose-100">
                      <h3 className="text-lg font-semibold text-rose-900 mb-2">Audio–motor</h3>
                      <p className="text-xs text-rose-800 mb-3">
                        Szum: {noiseEnabled ? 'włączony (nagłówek)' : 'wyłączony'}.
                      </p>
                      <label className="flex items-center gap-3 mb-4 min-h-[48px] text-sm text-slate-700">
                        <input
                          type="checkbox"
                          checked={hideMotorText}
                          onChange={(e) => setHideMotorText(e.target.checked)}
                          className="w-5 h-5 accent-rose-600"
                        />
                        Ukryj tekst polecenia (tylko słuch)
                      </label>
                      <button
                        type="button"
                        onClick={async () => {
                          await unlockAudio();
                          stopAllAudio();
                          const command =
                            AUDIO_MOTOR_COMMANDS[
                              Math.floor(Math.random() * AUDIO_MOTOR_COMMANDS.length)
                            ];
                          setAudioMotorState({ currentCommand: command });
                          const ctx = getAudioContext();
                          if (noiseEnabled && ctx) {
                            overlayNoise(ctx, 6, 0.35);
                          }
                          const delay = noiseEnabled ? 800 : 100;
                          setTimeout(() => speakText(command, { rate: 0.8 }), delay);
                        }}
                        className={`${primaryBtn} bg-rose-600 text-white`}
                      >
                        Odtwórz polecenie ruchowe
                      </button>

                      {audioMotorState.currentCommand && (
                        <div className="mt-4 bg-white rounded-xl p-5 space-y-4">
                          {!hideMotorText && (
                            <h4 className="text-xl sm:text-2xl font-bold text-center text-slate-800">
                              {audioMotorState.currentCommand}
                            </h4>
                          )}
                          {hideMotorText && (
                            <p className="text-center text-slate-500 text-sm">
                              Polecenie odtworzone — wykonaj ruch ze słuchu.
                            </p>
                          )}
                          <TherapistHint label="Wskazówki dla oceniającego">
                            Oceń szybkość reakcji, precyzję i zrozumienie. Polecenie:{' '}
                            {audioMotorState.currentCommand}
                          </TherapistHint>
                          <div className="flex flex-col sm:flex-row gap-3">
                            <button
                              type="button"
                              onClick={() => {
                                updateAdaptive(true);
                                applyTrialResult(true, 'audioMotor');
                                setAudioMotorState({ currentCommand: '' });
                              }}
                              className={`${secondaryBtn} flex-1 bg-emerald-600 text-white`}
                            >
                              Wykonał poprawnie
                            </button>
                            <button
                              type="button"
                              onClick={() => {
                                updateAdaptive(false);
                                applyTrialResult(false, 'audioMotor');
                                setAudioMotorState({ currentCommand: '' });
                              }}
                              className={`${secondaryBtn} flex-1 bg-rose-600 text-white`}
                            >
                              Błędnie / nie wykonał
                            </button>
                          </div>
                        </div>
                      )}
                    </section>
                  )}
                </div>
              )}
            </div>
          </div>

          {showParentPanel && (
            <div
              className="fixed inset-0 bg-black/50 flex items-end sm:items-center justify-center p-0 sm:p-4 z-50"
              role="dialog"
              aria-modal="true"
              aria-labelledby="therapist-panel-title"
              onClick={(e) => {
                if (e.target === e.currentTarget) setShowParentPanel(false);
              }}
            >
              <div className="bg-white rounded-t-2xl sm:rounded-2xl p-5 sm:p-6 max-w-2xl w-full max-h-[85vh] overflow-y-auto">
                <div className="flex justify-between items-center mb-4">
                  <h3 id="therapist-panel-title" className="text-xl font-bold text-slate-800">
                    Panel terapeuty / rodzica
                  </h3>
                  <button
                    type="button"
                    onClick={() => setShowParentPanel(false)}
                    className="min-h-[44px] min-w-[44px] rounded-lg text-slate-500 touch-manipulation"
                    aria-label="Zamknij panel"
                  >
                    ✕
                  </button>
                </div>

                <div className="grid grid-cols-2 gap-3 mb-4">
                  <StatCard title="Czas sesji" value={formatTime(sessionTime)} tone="sky" />
                  <StatCard
                    title="Poziom szumu"
                    value={`${effectiveSNR.toFixed(1)} dB*`}
                    tone="emerald"
                  />
                  <StatCard title="Seria poprawnych" value={adaptiveState.correctStreak} tone="violet" />
                  <StatCard title="Punkty (łącznie)" value={rewards.points} tone="amber" />
                </div>

                <div className="bg-slate-50 p-3 rounded-xl mb-3 text-sm text-slate-600">
                  Historia poziomu:{' '}
                  {adaptiveState.history.length
                    ? adaptiveState.history.slice(-10).map((s) => s.toFixed(1)).join(', ')
                    : 'brak'}
                </div>

                <p className="text-xs text-slate-500 mb-4">
                  Wyniki zapisują się lokalnie w przeglądarce. Aplikacja nie stawia diagnozy APD.
                </p>

                <button
                  type="button"
                  onClick={() => {
                    const report = {
                      sessionTime: formatTime(sessionTime),
                      noiseEnabled,
                      noiseType: noiseEnabled ? noiseType : null,
                      relativeNoiseLevel: noiseEnabled ? effectiveSNR : null,
                      correctStreak: adaptiveState.correctStreak,
                      reversals: adaptiveState.reversals,
                      history: adaptiveState.history,
                      rewards: {
                        points: rewards.points,
                        streak: rewards.currentStreak,
                        badges: rewards.badges,
                      },
                      module: currentModule,
                      timestamp: new Date().toLocaleString('pl-PL'),
                      disclaimer:
                        'Opcjonalny względny poziom szumu — nie kalibrowany SNR kliniczny. Trening wspomagający, nie diagnostyka.',
                    };
                    const blob = new Blob([JSON.stringify(report, null, 2)], {
                      type: 'application/json',
                    });
                    const url = URL.createObjectURL(blob);
                    const a = document.createElement('a');
                    a.href = url;
                    a.download = `raport-apd-${new Date().toISOString().split('T')[0]}.json`;
                    a.click();
                    URL.revokeObjectURL(url);
                  }}
                  className={`${secondaryBtn} bg-sky-600 text-white inline-flex items-center gap-2`}
                >
                  <Icon.Download />
                  Eksport raportu
                </button>
              </div>
            </div>
          )}

          {fatigueLevel > 80 && (
            <div className="fixed bottom-24 md:bottom-6 left-4 right-4 md:left-auto md:right-4 md:w-72 z-40 bg-rose-600 text-white p-4 rounded-2xl shadow-lg">
              <p className="font-semibold">Czas na krótką przerwę</p>
              <p className="text-sm text-rose-100 mt-1">Lepsze krótkie sesje niż zmęczenie.</p>
              <button
                type="button"
                onClick={() => setFatigueLevel(0)}
                className="bg-white text-rose-700 min-h-[44px] px-4 rounded-xl mt-3 text-sm font-medium w-full touch-manipulation"
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

      {currentView === 'home' && (
        <MobileModuleNav
          modules={modules}
          currentModule={currentModule}
          onSelect={selectModule}
        />
      )}

      <FeedbackBanner
        kind={feedback.kind}
        message={feedback.message}
        onDone={() => setFeedback({ kind: null, message: '' })}
      />
      <NewBadgeToast badges={newBadges} onDismiss={() => setNewBadges([])} />
    </div>
  );
}

function NoisePicker({ value, onChange, accent = 'emerald' }) {
  const active =
    accent === 'violet'
      ? 'bg-violet-600 text-white'
      : accent === 'indigo'
        ? 'bg-indigo-600 text-white'
        : accent === 'teal'
          ? 'bg-teal-600 text-white'
          : 'bg-emerald-600 text-white';

  return (
    <div className="bg-white rounded-xl p-3">
      <h4 className="font-semibold mb-2 text-sm text-slate-800">Typ szumu</h4>
      <div className="grid grid-cols-2 gap-2">
        {NOISE_OPTIONS.map((noise) => (
          <button
            key={noise.type}
            type="button"
            onClick={() => onChange(noise.type)}
            className={`p-3 rounded-xl text-left min-h-[56px] sm:min-h-[64px] touch-manipulation ${
              value === noise.type ? active : 'bg-slate-100 text-slate-700'
            }`}
          >
            <div className="font-semibold text-sm">
              <span aria-hidden>{noise.emoji} </span>
              {noise.name}
            </div>
            <div className="text-xs opacity-80">{noise.desc}</div>
          </button>
        ))}
      </div>
    </div>
  );
}

function CalibrationPanel({ volumeCalibrated, setVolumeCalibrated, compact = false }) {
  return (
    <div
      className={`bg-white rounded-2xl shadow-sm border border-slate-100 ${
        compact ? 'p-3 mb-2' : 'p-4'
      }`}
    >
      <h3 className="font-semibold text-slate-800 mb-2 text-sm sm:text-base">Kalibracja</h3>
      {!volumeCalibrated ? (
        <div className={`space-y-2 ${compact ? 'flex flex-col sm:flex-row sm:items-stretch gap-2 space-y-0' : ''}`}>
          <p className={`text-sm text-slate-600 ${compact ? 'sm:hidden' : ''}`}>
            Słuchawki stereo · wygodna głośność
          </p>
          <button
            type="button"
            onClick={async () => {
              await unlockAudio();
              speakText('To jest test dźwięku. Ustaw wygodną głośność.', { rate: 0.85 });
            }}
            className="w-full min-h-[48px] bg-emerald-600 text-white rounded-xl font-medium touch-manipulation"
          >
            Test dźwięku
          </button>
          <button
            type="button"
            onClick={async () => {
              await unlockAudio();
              setVolumeCalibrated(true);
            }}
            className="w-full min-h-[48px] bg-sky-600 text-white rounded-xl font-medium touch-manipulation"
          >
            Gotowe
          </button>
        </div>
      ) : (
        <div className="flex items-center justify-between gap-2">
          <p className="text-sm text-emerald-700 font-medium">Gotowe do ćwiczeń</p>
          <button
            type="button"
            onClick={() => setVolumeCalibrated(false)}
            className="text-sm text-sky-700 min-h-[44px] px-2 touch-manipulation underline"
          >
            Ponów
          </button>
        </div>
      )}
    </div>
  );
}

function StatCard({ title, value, tone }) {
  const tones = {
    sky: 'bg-sky-50 text-sky-800',
    emerald: 'bg-emerald-50 text-emerald-800',
    violet: 'bg-violet-50 text-violet-800',
    amber: 'bg-amber-50 text-amber-900',
  };
  return (
    <div className={`p-3 rounded-xl ${tones[tone] || tones.sky}`}>
      <h4 className="text-xs font-semibold opacity-80">{title}</h4>
      <p className="text-xl font-bold tabular-nums mt-1">{value}</p>
    </div>
  );
}

export default TreningAPD;
