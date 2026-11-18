import React, { useState, useEffect } from 'react';

function Navbar({ currentView, setCurrentView }) {
  const [menuOpen, setMenuOpen] = useState(false);
  const isHome = currentView === 'home';

  useEffect(() => {
    setMenuOpen(false);
  }, [currentView]);

  const goApp = (e) => {
    e.preventDefault();
    setCurrentView('home');
    setMenuOpen(false);
    setTimeout(() => {
      const appSection = document.getElementById('aplikacja');
      if (appSection) appSection.scrollIntoView({ behavior: 'smooth' });
      else window.scrollTo({ top: 0, behavior: 'smooth' });
    }, 80);
  };

  const goAbout = (e) => {
    e.preventDefault();
    setCurrentView('home');
    setMenuOpen(false);
    setTimeout(() => {
      document.getElementById('czym-jest-apd')?.scrollIntoView({ behavior: 'smooth' });
    }, 80);
  };

  const goPrivacy = (e) => {
    e.preventDefault();
    setCurrentView('privacy');
    setMenuOpen(false);
    window.scrollTo(0, 0);
  };

  const linkClass = (active) =>
    `block min-h-[44px] px-3 py-2 rounded-lg text-sm font-medium transition-colors touch-manipulation ${
      active ? 'text-teal-700 font-semibold' : 'text-slate-700 hover:text-teal-700'
    }`;

  return (
    <nav className="bg-white/95 backdrop-blur shadow-sm fixed top-0 left-0 right-0 z-50 border-b border-slate-100">
      <div className="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-14 md:h-16">
          <a
            href="#aplikacja"
            onClick={goApp}
            className="text-lg sm:text-xl font-bold text-teal-700 flex items-center gap-2 min-h-[44px]"
          >
            <span aria-hidden>🎧</span>
            <span>Domowe-APD.pl</span>
          </a>

          <div className="hidden md:flex items-center gap-2">
            <a href="#aplikacja" onClick={goApp} className={linkClass(isHome)}>
              Aplikacja
            </a>
            <a href="#czym-jest-apd" onClick={goAbout} className={linkClass(false)}>
              Czym jest APD?
            </a>
            <a href="#privacy" onClick={goPrivacy} className={linkClass(currentView === 'privacy')}>
              Polityka prywatności
            </a>
          </div>

          <button
            type="button"
            className="md:hidden min-h-[44px] min-w-[44px] inline-flex items-center justify-center rounded-lg text-slate-700 touch-manipulation"
            aria-expanded={menuOpen}
            aria-controls="mobile-nav"
            aria-label={menuOpen ? 'Zamknij menu' : 'Otwórz menu'}
            onClick={() => setMenuOpen((v) => !v)}
          >
            <svg width="24" height="24" fill="none" stroke="currentColor" strokeWidth="2" viewBox="0 0 24 24">
              {menuOpen ? (
                <path d="M6 6l12 12M18 6L6 18" />
              ) : (
                <path d="M4 7h16M4 12h16M4 17h16" />
              )}
            </svg>
          </button>
        </div>

        {menuOpen && (
          <div id="mobile-nav" className="md:hidden pb-3 space-y-1 border-t border-slate-100 pt-2">
            <a href="#aplikacja" onClick={goApp} className={linkClass(isHome)}>
              Aplikacja
            </a>
            <a href="#czym-jest-apd" onClick={goAbout} className={linkClass(false)}>
              Czym jest APD?
            </a>
            <a href="#privacy" onClick={goPrivacy} className={linkClass(currentView === 'privacy')}>
              Polityka prywatności
            </a>
          </div>
        )}
      </div>
    </nav>
  );
}

export default Navbar;
