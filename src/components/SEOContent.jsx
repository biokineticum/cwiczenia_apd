import React from 'react';

function SEOContent() {
  return (
    <section
      id="czym-jest-apd"
      className="max-w-4xl mx-auto mt-10 mb-12 bg-white rounded-2xl shadow-sm border border-slate-100 p-6 md:p-10 text-slate-800"
    >
      <h2 className="text-2xl md:text-3xl font-bold text-slate-900 mb-4 border-b border-slate-100 pb-3">
        Czym są zaburzenia przetwarzania słuchowego (APD)?
      </h2>

      <p className="text-base md:text-lg leading-relaxed mb-5">
        Zaburzenia przetwarzania słuchowego (Auditory Processing Disorder, APD / CAPD) oznaczają
        trudności mózgu z rozpoznawaniem i interpretacją dźwięków, mimo że obwodowy narząd słuchu
        może działać prawidłowo. Osoby z APD często „słyszą”, ale gorzej rozumieją — zwłaszcza w
        hałasie.
      </p>

      <h3 className="text-xl font-semibold text-slate-800 mb-3 mt-6">
        Po co ćwiczyć słuch w domu?
      </h3>
      <p className="text-base md:text-lg leading-relaxed mb-3">
        Regularne, krótkie sesje treningowe mogą wspierać koncentrację słuchową i nawyk ćwiczeń.
        Aplikacja <strong>Domowe-APD.pl</strong> umożliwia:
      </p>
      <ul className="list-disc list-inside space-y-2 text-base md:text-lg mb-6 ml-1">
        <li>Trening w domu, we własnym tempie.</li>
        <li>Stopniowanie trudności (m.in. poziom szumu, długość sekwencji).</li>
        <li>Ćwiczenia uwagi, pamięci sekwencyjnej i rozumienia poleceń — jako wsparcie, nie zamiast terapii.</li>
      </ul>

      <h3 className="text-xl font-semibold text-slate-800 mb-3 mt-6">Dla kogo?</h3>
      <ul className="list-disc list-inside space-y-2 text-base md:text-lg mb-6 ml-1">
        <li>Dzieci szkolne ćwiczące pod okiem rodzica / logopedy / terapeuty.</li>
        <li>Dorośli, którzy chcą trenować rozumienie mowy w szumie.</li>
        <li>Osoby szukające uzupełnienia terapii — nie samodzielnej diagnozy.</li>
      </ul>

      <div className="bg-sky-50 border-l-4 border-sky-500 p-4 sm:p-5 rounded-r-xl mt-6">
        <p className="text-sm sm:text-base text-sky-950 font-medium">
          <strong>Ważne:</strong> to narzędzie treningowe i edukacyjne. Nie zastępuje diagnozy
          audiologicznej ani terapii prowadzonej przez wykwalifikowanego specjalistę. Nie gwarantuje
          poprawy konkretnych funkcji poznawczych.
        </p>
      </div>
    </section>
  );
}

export default SEOContent;
