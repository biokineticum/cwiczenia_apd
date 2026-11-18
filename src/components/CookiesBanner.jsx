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
        <div className="fixed bottom-20 md:bottom-0 left-0 right-0 bg-slate-900 text-white p-4 shadow-lg z-[60] flex flex-col sm:flex-row items-center justify-between gap-3 text-sm border-t border-slate-700 safe-bottom">
            <div className="flex-1 text-center sm:text-left text-slate-100">
                Strona używa cookies (m.in. analityka i AdSense), aby pozostać darmowa.
                Szczegóły w polityce prywatności.
            </div>
            <button
                type="button"
                onClick={handleAccept}
                className="bg-teal-600 hover:bg-teal-500 text-white font-semibold min-h-[48px] py-2 px-6 rounded-xl transition-colors whitespace-nowrap shadow-md focus:outline-none focus:ring-2 focus:ring-teal-300 touch-manipulation"
            >
                Rozumiem i akceptuję
            </button>
        </div>
    );
}

export default CookiesBanner;
