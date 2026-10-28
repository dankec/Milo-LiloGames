# Milo & Lilo: Tajna izgubljenog svjetla

Samostalni **Godot 4.7.2** offline 2D projekt za Android, s vlastitim izvornim grafičkim i zvučnim sadržajem. Projekt je neovisan o HTML igrama u nadređenom repozitoriju.

> **Status:** razvojna alpha verzija. Nije još potvrđena instalacija na fizički Android uređaj. Prije tvrdnje da je izdanje spremno potrebno je uspješno izvršiti CI, instalirati APK i proći kontrolni popis testiranja.

## Igranje

Milo (sivi zec) i Lilo (smeđi medvjed) istražuju pet područja i vraćaju svjetlo. Koristite zeca za viši skok, medvjeda za otvaranje kamenih vrata. Tipke na računalu: lijevo/desno ili A/D, Space skok, J akcija, Tab promjena lika, Esc pauza. Na mobitelu koriste se velike dodirne kontrole. Matematički zadaci su 0–10.

## Lokalno pokretanje

1. Instalirajte [Godot 4.7.2 standard](https://godotengine.org/download/archive/4.7.2-stable/) ; Python 3 s Pillow (`pip install Pillow`) potreban je samo za ponovno generiranje grafike.
2. Iz korijena projekta izvršite `python tools/make_art.py` ako grafički resursi nisu prisutni. Izvorni OGG audio sadržaj već je uključen u projekt.
3. Otvorite `project.godot` iz Godota i pokrenite F6/F5.
4. Za Android instalirajte Android SDK, OpenJDK 17 i Godot 4.7.2 export templates. U Godot Export izaberite Android i izradite APK.

## GitHub Actions

Workflow u `../.github/workflows/milo-lilo-android.yml` izravno iz repozitorija gradi *razvojni* Android APK i kao artifact omogućava preuzimanje. Odaberite `Actions > Milo & Lilo Android > Run workflow`. GitHub treba imati omogućen Actions. Ne koristite debug APK za distribuciju preko trgovine.

Potpisivanje trajnog release APK-a treba dodati kroz GitHub Secrets s vlastitim keystoreom. **Nemojte objavljivati privatni ključ.** Za ažuriranja na mobitelu moraju ostati isti application ID i potpis.

## Struktura

- `scripts/` – igra, fizički likovi, UI, razine, napredak i zvuk
- `scenes/` – početna Godot scena
- `assets/` – originalni rasterski likovi, pozadine, kontrole i originalni audio
- `tools/` – reproducibilni generatori originalnih resursa
- `tests/` – statičke provjere konfiguracije i razina
- `docs/` – QA status i razvojni backlog

## Privatnost

Aplikacija je offline, bez oglasa, analitike, login sustava i traženja osjetljivih dozvola.

## Poznata ograničenja alpha verzije

- Nisu provedena testiranja na stvarnom Android uređaju.
- Neke napredne mehanike i vizualni efekti iz potpunog plana zahtijevaju dodatni razvoj, posebice cinematic animacije, prateća AI logika i precizna mobilna optimizacija.
- Igre koje imaju isto ime, ali različite potpise, Android neće instalirati kao nadogradnju bez prethodnog uklanjanja prve aplikacije.
