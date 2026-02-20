import React, { useState, useEffect } from 'react';

function CookiesBanner() {
    const [isVisible, setIsVisible] = useState(false);

    useEffect(() => {
        const consent = localStorage.getItem('domoweApdCookiesConsent');
        if (!consent) {
            setIsVisible(true);
        }
    }, []);

    const handleAccept = () => {
        localStorage.setItem('domoweApdCookiesConsent', 'true');
        setIsVisible(false);
    };

    if (!isVisible) return null;

    return (
        <div className="fixed bottom-0 left-0 right-0 bg-gray-900 text-white p-4 shadow-lg z-[60] flex flex-col sm:flex-row items-center justify-between gap-4 text-sm md:text-base border-t border-gray-700">
            <div className="flex-1 text-center sm:text-left">
                Strona korzysta z plików cookies w celu prawidłowego działania oraz wyświetlania reklam Google AdSense.
                Dzięki temu aplikacja pozostaje darmowa. Korzystając z serwisu, wyrażasz na to zgodę.
            </div>
            <button
                onClick={handleAccept}
                className="bg-blue-600 hover:bg-blue-500 text-white font-semibold py-2 px-6 rounded-lg transition-colors whitespace-nowrap shadow-md focus:outline-none focus:ring-2 focus:ring-blue-400"
            >
                Rozumiem i Akceptuję
            </button>
        </div>
    );
}

export default CookiesBanner;
