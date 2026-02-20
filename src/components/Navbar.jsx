import React from 'react';

function Navbar({ currentView, setCurrentView }) {
    const isHome = currentView === 'home';

    const handleAplikacjaClick = (e) => {
        e.preventDefault();
        setCurrentView('home');
        // Scroll to app top immediately or after a render
        setTimeout(() => {
            const appSection = document.getElementById('aplikacja');
            if (appSection) {
                appSection.scrollIntoView({ behavior: 'smooth' });
            } else {
                window.scrollTo({ top: 0, behavior: 'smooth' });
            }
        }, 100);
    };

    const handleAboutClick = (e) => {
        e.preventDefault();
        setCurrentView('home');
        setTimeout(() => {
            const aboutSection = document.getElementById('czym-jest-apd');
            if (aboutSection) {
                aboutSection.scrollIntoView({ behavior: 'smooth' });
            }
        }, 100);
    };

    return (
        <nav className="bg-white shadow-md fixed top-0 left-0 right-0 z-50">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="flex justify-between items-center h-16">
                    <div className="flex items-center">
                        <a 
                            href="#" 
                            onClick={handleAplikacjaClick}
                            className="text-xl font-bold text-blue-600 flex items-center gap-2"
                        >
                            🎧 Domowe-APD.pl
                        </a>
                    </div>
                    <div className="hidden md:flex space-x-8">
                        <a 
                            href="#aplikacja" 
                            onClick={handleAplikacjaClick}
                            className={`text-gray-700 hover:text-blue-600 px-3 py-2 rounded-md text-sm font-medium transition-colors ${isHome ? '' : 'opacity-80'}`}
                        >
                            Aplikacja
                        </a>
                        <a 
                            href="#czym-jest-apd" 
                            onClick={handleAboutClick}
                            className="text-gray-700 hover:text-blue-600 px-3 py-2 rounded-md text-sm font-medium transition-colors"
                        >
                            Czym jest APD?
                        </a>
                        <a 
                            href="#" 
                            onClick={(e) => { e.preventDefault(); setCurrentView('privacy'); window.scrollTo(0,0); }}
                            className={`text-gray-700 hover:text-blue-600 px-3 py-2 rounded-md text-sm font-medium transition-colors ${currentView === 'privacy' ? 'text-blue-600 font-bold' : ''}`}
                        >
                            Polityka Prywatności
                        </a>
                    </div>
                </div>
            </div>
        </nav>
    );
}

export default Navbar;
