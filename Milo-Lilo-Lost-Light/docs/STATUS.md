# Status i QA — 0.2.0-alpha

## Novo
- Otklonjen modalni bug: pauza se može nastaviti.
- Potvrda prije brisanja postojećeg napretka.
- Kontrolne točke i povratak nakon pada/poraza.
- Sakupljeni novčići i nagrade iz škrinja ne mogu se beskonačno farmati nakon restartanja razine.
- Backup + recovery JSON spremanja; dodana kompatibilna polja collected/checkpoints.
- Stvarne sposobnosti: dvostruki skok, štit od jednoga udarca i privlačenje novčića.
- Blago u završnoj razini zahtijeva sva tri dijela mape.
- OGG umjesto WAV za tematsku glazbu (bitno manji repozitorij).
- Android Back otvara/zatvara pauzu.

## Trenutačno testiranje
- Python statičke provjere (vidjeti `python -m unittest discover -s tests -v`).
- Godot parser, interaktivni gameplay i Android instalacija nisu verificirani u ovom okruženju.

## Još preostaje
- Headless Godot 4.7.2 import/smoke u CI.
- Android debug APK build i instalacija na stvarni uređaj.
- Playtest pet razina i optimizacija kontrole/performansi.
- Dinamički UI za vrlo uske uređaje, razrade dana/noći, tutorijala i lokalizacije.
- Release keystore i publikacija dugotrajno potpisanog APK-a (ne spremati ključ u repo).
