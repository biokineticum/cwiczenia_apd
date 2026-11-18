const STORAGE_KEY = 'apdRewardsV1';

export const BADGE_DEFS = [
  {
    id: 'first_star',
    name: 'Pierwsza gwiazdka',
    description: 'Ukończ pierwszą poprawną próbę',
    check: (s) => s.totalCorrect >= 1,
  },
  {
    id: 'ten_correct',
    name: 'Dziesięć trafień',
    description: 'Zbierz 10 poprawnych odpowiedzi',
    check: (s) => s.totalCorrect >= 10,
  },
  {
    id: 'fifty_correct',
    name: 'Słuchacz',
    description: 'Zbierz 50 poprawnych odpowiedzi',
    check: (s) => s.totalCorrect >= 50,
  },
  {
    id: 'streak_3',
    name: '3 dni z rzędu',
    description: 'Ćwicz trzy dni pod rząd',
    check: (s) => s.bestStreak >= 3,
  },
  {
    id: 'streak_7',
    name: 'Tydzień treningu',
    description: 'Ćwicz siedem dni pod rząd',
    check: (s) => s.bestStreak >= 7,
  },
  {
    id: 'points_100',
    name: '100 punktów',
    description: 'Zdobądź łącznie 100 punktów',
    check: (s) => s.points >= 100,
  },
  {
    id: 'points_500',
    name: '500 punktów',
    description: 'Zdobądź łącznie 500 punktów',
    check: (s) => s.points >= 500,
  },
  {
    id: 'explorer',
    name: 'Odkrywca modułów',
    description: 'Spróbuj wszystkich czterech modułów',
    check: (s) => Object.keys(s.modulesTried || {}).length >= 4,
  },
];

const defaultState = () => ({
  points: 0,
  totalCorrect: 0,
  totalAttempts: 0,
  currentStreak: 0,
  bestStreak: 0,
  lastPracticeDate: null,
  badges: [],
  modulesTried: {},
  sessionPoints: 0,
});

function todayKey() {
  return new Date().toISOString().slice(0, 10);
}

function yesterdayKey() {
  const d = new Date();
  d.setDate(d.getDate() - 1);
  return d.toISOString().slice(0, 10);
}

export function loadRewards() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return defaultState();
    return { ...defaultState(), ...JSON.parse(raw) };
  } catch {
    return defaultState();
  }
}

export function saveRewards(state) {
  try {
    const { sessionPoints, ...persisted } = state;
    localStorage.setItem(STORAGE_KEY, JSON.stringify(persisted));
  } catch {
    /* quota / private mode */
  }
}

function unlockBadges(state) {
  const earned = new Set(state.badges);
  const newly = [];
  for (const badge of BADGE_DEFS) {
    if (!earned.has(badge.id) && badge.check(state)) {
      earned.add(badge.id);
      newly.push(badge);
    }
  }
  return { badges: [...earned], newly };
}

/**
 * Record one trial. Correct answers earn points; daily streak updates on any practice.
 * Mistakes do not reduce points (clinically gentler).
 */
export function recordTrial(state, { correct, moduleId, pointsIfCorrect = 10 }) {
  const today = todayKey();
  let currentStreak = state.currentStreak;
  let bestStreak = state.bestStreak;

  if (state.lastPracticeDate !== today) {
    if (state.lastPracticeDate === yesterdayKey()) {
      currentStreak = (state.currentStreak || 0) + 1;
    } else {
      currentStreak = 1;
    }
  }
  bestStreak = Math.max(bestStreak, currentStreak);

  const gained = correct ? pointsIfCorrect : 0;
  const next = {
    ...state,
    points: state.points + gained,
    sessionPoints: (state.sessionPoints || 0) + gained,
    totalCorrect: state.totalCorrect + (correct ? 1 : 0),
    totalAttempts: state.totalAttempts + 1,
    currentStreak,
    bestStreak,
    lastPracticeDate: today,
    modulesTried: {
      ...state.modulesTried,
      [moduleId]: true,
    },
  };

  const { badges, newly } = unlockBadges(next);
  next.badges = badges;
  saveRewards(next);
  return { state: next, gained, newBadges: newly };
}

export function getBadgeInfo(id) {
  return BADGE_DEFS.find((b) => b.id === id);
}
