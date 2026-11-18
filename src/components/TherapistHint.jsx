import React, { useState } from 'react';

/** Answer key hidden by default so children cannot read the solution. */
function TherapistHint({ children, label = 'Pokaż klucz (terapeuta / rodzic)' }) {
  const [open, setOpen] = useState(false);

  return (
    <div className="rounded-xl border border-amber-200 bg-amber-50 overflow-hidden">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="w-full min-h-[48px] px-4 py-3 text-left text-sm font-medium text-amber-900 touch-manipulation flex items-center justify-between gap-2"
        aria-expanded={open}
      >
        <span>👩‍⚕️ {label}</span>
        <span className="text-amber-700">{open ? '▾' : '▸'}</span>
      </button>
      {open && (
        <div className="px-4 pb-4 text-sm text-amber-900 border-t border-amber-200 pt-3">
          {children}
        </div>
      )}
    </div>
  );
}

export default TherapistHint;
