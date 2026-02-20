import React from 'react';

function PrivacyPolicy() {
    return (
        <div className="max-w-4xl mx-auto mt-24 mb-24 bg-white rounded-xl shadow-lg p-8 md:p-12 text-gray-800">
            <h1 className="text-3xl md:text-4xl font-bold text-gray-900 mb-8 border-b pb-4">Polityka Prywatności serwisu Domowe-APD.pl</h1>

            <section className="mb-8">
                <h2 className="text-2xl font-semibold text-gray-800 mb-4 mt-8">1. Bezpieczeństwo i przetwarzanie danych</h2>
                <p className="text-lg leading-relaxed">
                    Ochrona prywatności użytkowników to nasz priorytet. Nasza aplikacja służy do treningu słuchowego.
                    <strong> Nie gromadzimy, nie zapisujemy i nie analizujemy żadnych wrażliwych danych medycznych.</strong>
                    Wyniki Twoich ćwiczeń są przetwarzane wyłącznie lokalnie w Twojej przeglądarce i nie są wysyłane na nasze serwery.
                </p>
            </section>

            <section className="mb-8">
                <h2 className="text-2xl font-semibold text-gray-800 mb-4 mt-8">2. Pliki Cookies (Ciasteczka)</h2>
                <p className="text-lg leading-relaxed">
                    Strona Domowe-APD.pl używa plików cookies w celu zapewnienia prawidłowego działania serwisu oraz w celach analitycznych i marketingowych. Możesz zarządzać ustawieniami cookies z poziomu swojej przeglądarki.
                </p>
            </section>

            <section className="mb-8">
                <h2 className="text-2xl font-semibold text-gray-800 mb-4 mt-8">3. Reklamy Google AdSense</h2>
                <p className="text-lg leading-relaxed mb-4">
                    Aby nasza aplikacja mogła pozostać darmowa, korzystamy z systemu reklamowego Google AdSense:
                </p>
                <ul className="list-disc list-inside space-y-2 text-lg ml-4">
                    <li>Zewnętrzni dostawcy, w tym Google, używają plików cookie do wyświetlania reklam na podstawie poprzednich odwiedzin użytkownika w tej lub innych witrynach.</li>
                    <li>Wykorzystanie plików cookie do wyświetlania reklam umożliwia firmie Google i jej partnerom wyświetlanie spersonalizowanych reklam.</li>
                    <li>Możesz zrezygnować ze spersonalizowanych reklam, odwiedzając stronę <a href="https://myadcenter.google.com" target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline">Ustawienia reklam Google</a> lub stronę <a href="http://www.aboutads.info" target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline">www.aboutads.info</a>.</li>
                </ul>
            </section>

            <section className="mb-8">
                <h2 className="text-2xl font-semibold text-gray-800 mb-4 mt-8">4. Kontakt</h2>
                <p className="text-lg leading-relaxed">
                    W przypadku pytań dotyczących funkcjonowania aplikacji lub prywatności, prosimy o kontakt pod adresem:{' '}
                    <a href="mailto:kontakt@domowe-apd.pl" className="text-blue-600 hover:underline font-medium">
                        kontakt@domowe-apd.pl
                    </a>
                </p>
            </section>
        </div>
    );
}

export default PrivacyPolicy;
