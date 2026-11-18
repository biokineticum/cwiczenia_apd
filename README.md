# Trening APD (`cwiczenia_apd`)

**Web app for auditory processing (APD) training support** — speech-in-noise, sound recognition, lateralization, and audio–motor modules with therapist-oriented stats, light rewards, and mobile-first controls.

For audiologists, speech therapists and clinicians working on auditory processing with patients (stereo headphones recommended). **Training aid — not a diagnostic tool.**

Live: [cwiczenia-apd.vercel.app](https://cwiczenia-apd.vercel.app)

## Features

- Background noises: white, pink, brown, babble; relative noise-level control via Web Audio API
- Modules: speech in noise, environmental sounds (starter TTS), L/R lateralization & digit sequences, audio + motor commands
- Mobile-first UI: bottom module nav, large touch targets, stereo-headphone prompts
- Light gamification: points, daily streaks, badges (localStorage only)
- Therapist / parent panel: session stats, export JSON, hidden answer keys
- React + Vite (+ Tailwind CDN)

## Install & run

```bash
git clone https://github.com/biokineticum/cwiczenia_apd.git
cd cwiczenia_apd
npm install
npm run dev
```

```bash
npm run build
npm run preview
```

### Polish summary / Podsumowanie PL

Profesjonalna aplikacja React do terapii i treningu zaburzeń przetwarzania słuchowego (APD): mowa w szumie, rozpoznawanie dźwięków, lateralizacja, audio–motor. Słuchawki stereo wymagane. Kontakt: biokineticum@proton.me. Szczegóły licencji: `license.md`.

---

## Author

**Dariusz Mosler** (Biokineticum) — physiotherapy, biomechanics, sports science  
🌐 [biokineticum.com](https://biokineticum.com) · 📰 [Substack](https://biokineticum.substack.com) · 𝕏 [@Biokineticum](https://x.com/Biokineticum)

