import React, { useState } from 'react';
import { BADGE_DEFS, getBadgeInfo } from '../lib/gamification';

function RewardsBar({ rewards }) {
  const [open, setOpen] = useState(false);
  const earned = rewards.badges || [];

  return (
    <div className="w-full">
      <div className="flex flex-wrap items-center justify-center md:justify-end gap-2 sm:gap-3">
        <div className="flex items-center gap-1.5 bg-amber-50 text-amber-900 px-3 py-2 rounded-xl min-h-[44px] border border-amber-100">
          <span className="text-sm font-semibold" aria-hidden>
            ★
          </span>
          <span className="text-sm font-bold tabular-nums">{rewards.points}</span>
          <span className="text-xs text-amber-700 hidden xs:inline sm:inline">pkt</span>
        </div>
        <div className="flex items-center gap-1.5 bg-teal-50 text-teal-900 px-3 py-2 rounded-xl min-h-[44px] border border-teal-100">
          <span className="text-sm font-semibold" aria-hidden>
            🔥
          </span>
          <span className="text-sm font-bold tabular-nums">{rewards.currentStreak}</span>
          <span className="text-xs text-teal-700">dni</span>
        </div>
        <button
          type="button"
          onClick={() => setOpen((v) => !v)}
          className="flex items-center gap-1.5 bg-white text-slate-700 px-3 py-2 rounded-xl min-h-[44px] border border-slate-200 touch-manipulation"
          aria-expanded={open}
          aria-controls="badges-panel"
        >
          <span className="text-sm font-bold tabular-nums">{earned.length}</span>
          <span className="text-xs">odznaki</span>
        </button>
      </div>

      {open && (
        <div
          id="badges-panel"
          className="mt-3 bg-white border border-slate-200 rounded-xl p-3 text-left shadow-sm max-h-56 overflow-y-auto"
        >
          <p className="text-xs text-slate-500 mb-2">
            Odznaki za regularność i poprawne próby — bez kar za błędy.
          </p>
          <ul className="space-y-2">
            {BADGE_DEFS.map((badge) => {
              const unlocked = earned.includes(badge.id);
              return (
                <li
                  key={badge.id}
                  className={`flex gap-2 text-sm ${unlocked ? 'text-slate-800' : 'text-slate-400'}`}
                >
                  <span aria-hidden>{unlocked ? '🏅' : '○'}</span>
                  <span>
                    <span className="font-medium">{badge.name}</span>
                    <span className="block text-xs opacity-80">{badge.description}</span>
                  </span>
                </li>
              );
            })}
          </ul>
          {rewards.sessionPoints > 0 && (
            <p className="text-xs text-teal-700 mt-3 pt-2 border-t border-slate-100">
              W tej sesji: +{rewards.sessionPoints} pkt
            </p>
          )}
        </div>
      )}
    </div>
  );
}

export function NewBadgeToast({ badges, onDismiss }) {
  if (!badges?.length) return null;
  const info = badges.map((b) => (typeof b === 'string' ? getBadgeInfo(b) : b)).filter(Boolean);

  return (
    <div
      className="fixed top-20 left-4 right-4 sm:left-auto sm:right-4 sm:w-80 z-[70] bg-teal-700 text-white rounded-xl p-4 shadow-lg"
      role="status"
    >
      <div className="flex justify-between gap-3 items-start">
        <div>
          <p className="font-semibold text-sm">Nowa odznaka!</p>
          <ul className="mt-1 text-sm space-y-1">
            {info.map((b) => (
              <li key={b.id}>
                🏅 {b.name}
              </li>
            ))}
          </ul>
        </div>
        <button
          type="button"
          onClick={onDismiss}
          className="min-h-[44px] min-w-[44px] rounded-lg bg-teal-600 touch-manipulation"
          aria-label="Zamknij"
        >
          ✕
        </button>
      </div>
    </div>
  );
}

export default RewardsBar;
