import React from 'react';

function SEOContent() {
    return (
        <section id="czym-jest-apd" className="max-w-4xl mx-auto mt-16 mb-16 bg-white rounded-xl shadow-lg p-8 md:p-12 text-gray-800">
            <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-6 border-b pb-4">Czym są Zaburzenia Przetwarzania Słuchowego (APD)?</h2>

            <p className="text-lg leading-relaxed mb-6">
                Zaburzenia Przetwarzania Słuchowego (Auditory Processing Disorder) to specyficzny problem polegający na tym, że mózg ma trudności z prawidłowym rozpoznawaniem i interpretowaniem dźwięków, mimo że fizyczny narząd słuchu (uszy) działa bez zarzutu. Osoby z APD często słyszą dźwięk, ale go nie rozumieją, zwłaszcza w hałaśliwym otoczeniu.
            </p>

            <h3 className="text-2xl font-semibold text-gray-800 mb-4 mt-8">Dlaczego warto trenować słuch w domu?</h3>
            <p className="text-lg leading-relaxed mb-4">
                Rehabilitacja APD wymaga czasu, cierpliwości i przede wszystkim regularności. Codzienne, krótkie sesje treningowe przynoszą znacznie lepsze efekty niż rzadkie, długie ćwiczenia. Nasza aplikacja <strong>Domowe-APD.pl</strong> została stworzona, aby umożliwić:
            </p>
            <ul className="list-disc list-inside space-y-2 text-lg mb-8 ml-4">
                <li>Wygodny trening w domowym zaciszu, bez stresu i presji czasu.</li>
                <li>Stopniowanie trudności: od prostego różnicowania dźwięków po bardziej złożone zadania słuchowe.</li>
                <li>Poprawę koncentracji słuchowej i pamięci operacyjnej, co przekłada się na lepsze funkcjonowanie w szkole, pracy i życiu codziennym.</li>
            </ul>

            <h3 className="text-2xl font-semibold text-gray-800 mb-4 mt-8">Dla kogo przeznaczone są nasze ćwiczenia?</h3>
            <ul className="list-disc list-inside space-y-2 text-lg mb-8 ml-4">
                <li>Dla dzieci w wieku szkolnym, które mają trudności ze skupieniem uwagi, czytaniem i pisaniem ze słuchu.</li>
                <li>Dla dorosłych, którzy odczuwają zmęczenie w hałaśliwych miejscach (np. w biurze typu open space) i mają problem ze zrozumieniem mowy w tłumie.</li>
                <li>Dla wszystkich, którzy chcą profilaktycznie zadbać o sprawność swojego układu słuchowo-nerwowego.</li>
            </ul>

            <div className="bg-blue-50 border-l-4 border-blue-500 p-6 rounded-r-lg mt-8">
                <p className="text-md text-blue-900 font-medium">
                    <strong>Ważna informacja:</strong> Aplikacja ma charakter treningowy i wspomagający. Nie zastępuje profesjonalnej diagnozy audiologicznej ani terapii prowadzonej przez wykwalifikowanego specjalistę.
                </p>
            </div>
        </section>
    );
}

export default SEOContent;
