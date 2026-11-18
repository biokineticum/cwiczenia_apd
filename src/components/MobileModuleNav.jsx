import React from 'react';

function MobileModuleNav({ modules, currentModule, onSelect }) {
  return (
    <nav
      className="fixed bottom-0 inset-x-0 z-50 md:hidden bg-white/95 backdrop-blur border-t border-slate-200 safe-bottom"
      aria-label="Moduły ćwiczeń"
    >
      <div className="grid grid-cols-4 gap-0">
        {Object.entries(modules).map(([key, module]) => {
          const active = currentModule === key;
          return (
            <button
              key={key}
              type="button"
              onClick={() => onSelect(key)}
              className={`flex flex-col items-center justify-center gap-0.5 min-h-[64px] px-1 py-2 text-[10px] leading-tight touch-manipulation ${
                active ? 'text-teal-700 bg-teal-50' : 'text-slate-600'
              }`}
              aria-current={active ? 'page' : undefined}
            >
              <span className="scale-110" aria-hidden>
                {module.icon}
              </span>
              <span className="font-medium text-center line-clamp-2">{module.shortName || module.name}</span>
            </button>
          );
        })}
      </div>
    </nav>
  );
}

export default MobileModuleNav;
