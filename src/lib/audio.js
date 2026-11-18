/**
 * Web Audio helpers for APD training.
 * Note: speechSynthesis stays outside the Web Audio graph — SNR is relative noise level, not clinical SNR.
 */

let sharedCtx = null;
const activeSources = new Set();

export function getAudioContext() {
  if (!sharedCtx) {
    const Ctx = window.AudioContext || window.webkitAudioContext;
    if (!Ctx) return null;
    sharedCtx = new Ctx();
  }
  return sharedCtx;
}

/** Call from a user gesture (tap) so mobile browsers allow playback. */
export async function unlockAudio() {
  const ctx = getAudioContext();
  if (!ctx) return false;
  try {
    if (ctx.state === 'suspended') {
      await ctx.resume();
    }
    return ctx.state === 'running';
  } catch {
    return false;
  }
}

export function stopSpeech() {
  if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
    window.speechSynthesis.cancel();
  }
}

export function stopAllNoise() {
  for (const source of activeSources) {
    try {
      source.stop();
    } catch {
      /* already stopped */
    }
  }
  activeSources.clear();
}

export function stopAllAudio() {
  stopSpeech();
  stopAllNoise();
}

function trackSource(source) {
  activeSources.add(source);
  source.onended = () => {
    activeSources.delete(source);
  };
}

export function generateNoiseBuffer(ctx, type, duration = 10) {
  const bufferSize = Math.floor(ctx.sampleRate * duration);
  const noiseBuffer = ctx.createBuffer(2, bufferSize, ctx.sampleRate);

  for (let channel = 0; channel < noiseBuffer.numberOfChannels; channel++) {
    const channelData = noiseBuffer.getChannelData(channel);

    switch (type) {
      case 'pink': {
        let b0 = 0;
        let b1 = 0;
        let b2 = 0;
        let b3 = 0;
        let b4 = 0;
        let b5 = 0;
        let b6 = 0;
        for (let i = 0; i < bufferSize; i++) {
          const white = Math.random() * 2 - 1;
          b0 = 0.99886 * b0 + white * 0.0555179;
          b1 = 0.99332 * b1 + white * 0.0750759;
          b2 = 0.969 * b2 + white * 0.153852;
          b3 = 0.8665 * b3 + white * 0.3104856;
          b4 = 0.55 * b4 + white * 0.5329522;
          b5 = -0.7616 * b5 - white * 0.016898;
          const pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362;
          b6 = white * 0.115926;
          channelData[i] = pink * 0.11;
        }
        break;
      }
      case 'brown': {
        let lastOut = 0;
        for (let i = 0; i < bufferSize; i++) {
          const white = Math.random() * 2 - 1;
          const brown = (lastOut + 0.02 * white) / 1.02;
          lastOut = brown;
          channelData[i] = brown * 3.5;
        }
        break;
      }
      case 'babble': {
        for (let i = 0; i < bufferSize; i++) {
          const freq = 200 + Math.random() * 2000;
          const time = i / ctx.sampleRate;
          channelData[i] =
            Math.sin(2 * Math.PI * freq * time) * 0.15 * (Math.random() * 0.5 + 0.5);
        }
        break;
      }
      case 'white':
      default: {
        for (let i = 0; i < bufferSize; i++) {
          channelData[i] = (Math.random() * 2 - 1) * 0.3;
        }
      }
    }
  }

  return noiseBuffer;
}

/**
 * Relative noise gain from a "SNR-like" slider.
 * Higher snr → quieter noise. Not a calibrated clinical SNR.
 */
export function relativeNoiseGain(snrDb, scale = 0.5) {
  return Math.pow(10, -snrDb / 20) * scale;
}

export function playNoise(ctx, type, duration, gainValue) {
  const noiseBuffer = generateNoiseBuffer(ctx, type, duration);
  const noiseSource = ctx.createBufferSource();
  const noiseGain = ctx.createGain();
  noiseSource.buffer = noiseBuffer;
  noiseGain.gain.setValueAtTime(gainValue, ctx.currentTime);
  noiseSource.connect(noiseGain);
  noiseGain.connect(ctx.destination);
  trackSource(noiseSource);
  noiseSource.start(ctx.currentTime);
  noiseSource.stop(ctx.currentTime + duration);
  return noiseSource;
}

export function speakText(text, { lang = 'pl-PL', rate = 0.8, volume = 0.75, pitch = 1 } = {}) {
  return new Promise((resolve) => {
    if (!('speechSynthesis' in window)) {
      resolve(false);
      return;
    }
    stopSpeech();
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = lang;
    utterance.rate = rate;
    utterance.volume = volume;
    utterance.pitch = pitch;
    utterance.onend = () => resolve(true);
    utterance.onerror = () => resolve(false);
    window.speechSynthesis.speak(utterance);
  });
}

/** Speak words one-by-one with a short gap (auditory sequence training). */
export function speakWordSequence(
  words,
  { lang = 'pl-PL', rate = 0.75, volume = 0.8, gapMs = 400 } = {}
) {
  return new Promise((resolve) => {
    if (!('speechSynthesis' in window) || !words?.length) {
      resolve(false);
      return;
    }
    stopSpeech();
    let index = 0;

    const speakNext = () => {
      if (index >= words.length) {
        resolve(true);
        return;
      }
      const utterance = new SpeechSynthesisUtterance(String(words[index]));
      utterance.lang = lang;
      utterance.rate = rate;
      utterance.volume = volume;
      utterance.onend = () => {
        index += 1;
        if (index >= words.length) {
          resolve(true);
          return;
        }
        setTimeout(speakNext, gapMs);
      };
      utterance.onerror = () => resolve(false);
      window.speechSynthesis.speak(utterance);
    };

    speakNext();
  });
}

export function playTone(ctx, frequency, pan = 0, durationMs = 1000, gain = 0.28) {
  const oscillator = ctx.createOscillator();
  const gainNode = ctx.createGain();
  const panNode = ctx.createStereoPanner();

  oscillator.frequency.setValueAtTime(frequency, ctx.currentTime);
  oscillator.type = 'sine';
  panNode.pan.setValueAtTime(pan, ctx.currentTime);
  gainNode.gain.setValueAtTime(gain, ctx.currentTime);
  gainNode.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + durationMs / 1000);

  oscillator.connect(panNode);
  panNode.connect(gainNode);
  gainNode.connect(ctx.destination);

  trackSource(oscillator);
  oscillator.start();
  oscillator.stop(ctx.currentTime + durationMs / 1000);
}

/** Normalize Polish user text for loose word matching. */
export function normalizeAnswer(text) {
  return text
    .toLowerCase()
    .normalize('NFC')
    .replace(/[?!.,;:"„”]/g, '')
    .trim()
    .split(/\s+/)
    .filter(Boolean);
}

export function scoreSpeechAnswer(userInput, targetWords, threshold = 0.7) {
  const userWords = normalizeAnswer(userInput);
  const targets = targetWords.map((w) => w.toLowerCase().replace(/[?!.,;:]/g, ''));
  let correctWords = 0;
  userWords.forEach((word) => {
    if (targets.includes(word)) correctWords += 1;
  });
  const accuracy = targets.length === 0 ? 0 : correctWords / targets.length;
  return { accuracy, correctWords, isCorrect: accuracy >= threshold };
}

/** Exact-order match for word / digit auditory sequences. */
export function scoreExactSequence(userInputOrWords, targetWords) {
  const userWords = Array.isArray(userInputOrWords)
    ? userInputOrWords.map((w) => String(w).toLowerCase().trim())
    : normalizeAnswer(userInputOrWords);
  const targets = targetWords.map((w) => String(w).toLowerCase().trim());
  const isCorrect =
    userWords.length === targets.length &&
    userWords.every((word, i) => word === targets[i]);
  let correctInOrder = 0;
  for (let i = 0; i < Math.min(userWords.length, targets.length); i += 1) {
    if (userWords[i] === targets[i]) correctInOrder += 1;
    else break;
  }
  return {
    isCorrect,
    correctInOrder,
    accuracy: targets.length === 0 ? 0 : correctInOrder / targets.length,
  };
}
