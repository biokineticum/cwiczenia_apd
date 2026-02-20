import React from 'react';

function Footer({ setCurrentView }) {
    return (
        <footer className="bg-gray-900 text-white py-6 px-4 mt-auto">
            <div className="max-w-7xl mx-auto flex flex-col md:flex-row justify-between items-center gap-4 text-sm md:text-base">
                <div className="flex items-center space-x-2">
                    <span>© 2026 Domowe-APD.pl</span>
                    <span className="text-gray-500 hidden sm:inline">|</span>
                    <span className="text-gray-400 hidden sm:inline">Trening Słuchowy</span>
                </div>

                <div className="text-gray-400 text-center text-xs md:text-sm max-w-lg">
                    Korzystanie ze strony oznacza akceptację regulaminu i polityki prywatności.
                </div>

                <div className="flex items-center space-x-4">
                    <a
                        href="mailto:kontakt@domowe-apd.pl"
                        className="text-blue-400 hover:text-blue-300 transition-colors"
                        title="Kontakt"
                    >
                        kontakt@domowe-apd.pl
                    </a>
                    <span className="text-gray-600">|</span>
                    <a
                        href="#"
                        onClick={(e) => { e.preventDefault(); setCurrentView('privacy'); window.scrollTo(0, 0); }}
                        className="text-blue-400 hover:text-blue-300 transition-colors"
                    >
                        Polityka Prywatności
                    </a>
                </div>
            </div>
        </footer>
    );
}

export default Footer;
