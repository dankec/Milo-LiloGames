# Milo & Lilo — dječje HTML5 igre

Zbirka samostalnih HTML5 igara za djecu. Igre rade izravno u pregledniku i ne traže instalaciju dodatnih paketa.

## Pokretanje

Otvorite željenu `.html` datoteku u web-pregledniku.

## Igre

- [Tajna šume nakon zalaska](milo_lilo_tajna_sume.html) — akcijska avantura: dva lika, dvostruki skok, mystery karte, bobice i noćna obrana kućice.
- [Čarobna pekarnica](carobna_pekarnica.html) — brojanje, boje, oblici, riječi i početna slova uz čitanje zadataka naglas.
- [Glazbena špilja](glazbena_spilja.html) — slobodno sviranje tonova C–D–E–F–G i ponavljanje ritma.
- [Kristalna ekspedicija](milo_lilo_kristalna_ekspedicija.html) — istraživanje, zagonetke i pustolovina s Milom i Lilo.
- [Kristalna ekspedicija — sigurnosna kopija](milo_lilo_kristalna_ekspedicija_backup.html).
- [Čarobna slovarica](carobna_slovarica.html).
- [Čarobna slovarica 2 — Pustolovina](carobna_slovarica_2.html).
- [Čarobna slovarica 3 — Skok u znanje](carobna_slovarica_3_platformer.html).
- [Čarobna slovarica — avantura](carobna_slovarica_avantura.html).

## Tehnologije

Igre su izrađene u HTML-u, CSS-u i JavaScriptu, bez vanjskih ovisnosti. Neke igre koriste govor preglednika za čitanje zadataka.

## Tajna šume nakon zalaska

Otvorite `milo_lilo_tajna_sume.html` u pregledniku. Datoteka radi i bez interneta.

- **←/→ ili A/D:** kretanje; **Shift:** trčanje; **Space:** skok i dvostruki skok.
- **↑/↓ ili W/S:** penjanje i silazak po ljestvama.
- **J ili F:** napad s pomoći pri ciljanju; **E:** Milo/Lilo; **Q:** promjena oružja.
- **P ili Esc:** pauza. Mobitel ima odvojene dodirne tipke; preporučen je vodoravni prikaz.
- Dan traje 135 sekundi, berba bobica 40 sekundi, a noć 90 sekundi (tri vala).
- Bobice ojačavaju kućicu. Gumb **⌂ Do kućice** dostupan je od berbe nadalje.
- Mystery karte daju štit, mjehuriće, ubrzanje, magnet ili trag do špilje. Nakon uspješne noći trajno se otključava bumerang.
- Novčići, kape, najbolja berba i završene noći spremaju se u lokalnoj pohrani tog preglednika. Ako preglednik zabrani pohranu, igra se i dalje može igrati, ali napredak se ne čuva nakon zatvaranja.

Provjera simulacije bez vanjskih paketa: `node tests/tajna_sume.test.cjs`.
