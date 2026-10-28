# Milo & Lilo: Tajna izgubljenog svjetla

Samostalni **Godot 4.7.2** offline 2D projekt za Android, s vlastitim izvornim grafičkim i zvučnim sadržajem. Projekt je neovisan o HTML igrama u nadređenom repozitoriju.

> **Status:** razvojna alpha verzija. Nije još potvrđena instalacija na fizički Android uređaj. Prije tvrdnje da je izdanje spremno potrebno je uspješno izvršiti CI, instalirati APK i proći kontrolni popis testiranja.

## Igranje

Milo (sivi zec) i Lilo (smeđi medvjed) istražuju pet područja i vraćaju svjetlo. Koristite zeca za viši skok, medvjeda za otvaranje kamenih vrata. Tipke na računalu: lijevo/desno ili A/D, Space skok, J akcija, Tab promjena lika, Esc pauza. Na mobitelu koriste se velike dodirne kontrole. Matematički zadaci su 0–10.

## Android prikaz i orijentacija

Igra je predviđena za **vodoravni prikaz (Landscape)**. U `project.godot` postavljeno je
`display/window/handheld/orientation=0` (Godotov `SCREEN_LANDSCAPE`), uz 1280 × 720
logički viewport i `canvas_items` skaliranje. Pokretanje aplikacije na mobitelu
prebacuje prikaz u vodoravni način; portretni prikaz nije podržan.

**v0.2.1-alpha:** ispravak prethodnog slučajnog `orientation=1` (Portrait).
Android debug APK-ovi iz različitih GitHub Actions izvođenja koriste različite
potpisne ključeve. Ako se novi APK ne može instalirati preko prethodnog, deinstalirajte
prethodnu razvojnu aplikaciju (lokalno spremljeni napredak tada se briše),
pa instalirajte novi APK. Za buduće nadogradnje bez gubitka podataka treba trajni
release keystore izvan javnog repozitorija.

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

## Verzija 0.3.0-alpha — jedan lik, upravljanje prstom

- Na zaslonu je **samo jedan lik**. Tipka za promjenu lika odmah mijenja
  Mila u Lila ili obratno na istom mjestu, uključujući promjenu skoka,
  trčanja i sposobnosti. Brzina i pozicija ostaju očuvane i u zraku.
- Lijevo je **pomični joystick**: dotakni bilo koje mjesto u lijevom donjem
  dijelu ekrana i povuci lijevo ili desno. Povlačenje gore pokreće skok.
- Desno su i dalje tri tipke: promjena lika, akcija i zasebna tipka za skok.
  Mogu se koristiti istodobno s joystickom (multitouch).
- Joystick se gasi za vrijeme pauze, matematičkog pitanja ili izbornika.
- Samo jedan CharacterBody2D postoji u razini; nema automatskog pratitelja.
- Android je prisilno u Landscape orijentaciji.

**Napomena o instalaciji:** GitHub Actions debug APK generira novi privremeni
potpisni ključ, pa za instaliranje preko stare verzije Android može tražiti
uklanjanje stare razvojne aplikacije. Time se briše njezin lokalni napredak.
Za produkcijsko ažuriranje nužan je trajni sigurno pohranjeni potpisni ključ.
