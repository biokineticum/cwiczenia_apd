import React, { useEffect } from 'react';

/**
 * Short, kid-friendly result banner after a trial.
 * kind: 'success' | 'error' | null
 */
function FeedbackBanner({ kind, message, onDone, durationMs = 2200 }) {
  useEffect(() => {
    if (!kind) return undefined;
    const t = setTimeout(() => onDone?.(), durationMs);
    return () => clearTimeout(t);
  }, [kind, message, onDone, durationMs]);

  if (!kind) return null;

  const styles =
    kind === 'success'
      ? 'bg-emerald-600 border-emerald-700'
      : 'bg-rose-600 border-rose-700';

  return (
    <div
      className={`fixed bottom-24 md:bottom-6 left-4 right-4 md:left-1/2 md:right-auto md:-translate-x-1/2 md:max-w-md z-[65] text-white rounded-2xl px-5 py-4 shadow-lg border ${styles}`}
      role="status"
      aria-live="polite"
    >
      <p className="text-center font-semibold text-base sm:text-lg">{message}</p>
    </div>
  );
}

export default FeedbackBanner;
