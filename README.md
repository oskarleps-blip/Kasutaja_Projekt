Jah, ikka! Korralik `README.md` on koolitöös väga oluline, sest see selgitab õpetajale, mida sinu projekt teeb ja kuidas seda käivitada.

Siin on sulle valmis faili sisu. Kopeeri see ja salvesta nimega **`README.md`**.

---

# Windowsi Kasutajate Haldusskriptid

See projekt koosneb PowerShell skriptidest, mille eesmärk on automatiseerida Windowsi kohalike kasutajate (Local Users) loomist ja kustutamist CSV faili põhjal. Skriptid on loodud töötama Windows 10/11 keskkonnas.

## Failide kirjeldus

Projektis on kaks peamist skripti:

1. **`Loo_kasutajad.ps1`**
* Genereerib suvalised kasutajaandmed (Eesnimi, Perenimi, Parool, Kirjeldus).
* Eemaldab nimedest täpitähed, et vältida ühilduvusprobleeme (nt *Tõnu* -> *Tonu*).
* Salvestab andmed faili `new_users_accounts.csv`.


2. **`Admin_Tegevused.ps1`**
* See on peamine haldusskript, mida tuleb käivitada **Administraatorina**.
* Võimaldab kahte tegevust:
1. **Lisa kasutajad:** Loeb CSV faili ja loob kasutajad süsteemi.
2. **Kustuta kasutajad:** Eemaldab kasutajad ja nende kodukaustad.





## Nõuded süsteemile

* Windows 10 või Windows 11
* PowerShell 5.1 või uuem
* Administraatori õigused (teise skripti jaoks)

## Kuidas kasutada

### 1. Ettevalmistus

Enne skriptide käivitamist veendu, et PowerShell lubab skripte jooksutada. Käivita PowerShell administraatorina ja sisesta:

```powershell
Set-ExecutionPolicy RemoteSigned

```

### 2. Andmete genereerimine

Käivita esimene skript (tavakasutajana või adminina):

```powershell
.\Loo_kasutajad.ps1

```

*Tulemus:* Tekib fail `new_users_accounts.csv` 5 uue kasutajaga.

### 3. Kasutajate haldus

Käivita teine skript **Administraatorina** (paremklõps -> "Run as Administrator"):

```powershell
.\Admin_Tegevused.ps1

```

Vali menüüst tegevus:

* Vajuta **1**, et lisada kasutajad süsteemi.
* Vajuta **2**, et kustutada kasutajaid (kustutatakse ka `C:\Users\Nimi` kaust).

## Funktsionaalsus ja kontrollid

Skript sisaldab järgmisi kontrolle ja omadusi:

* **Sisselogimise nõue:** Kasutajale määratakse säte *"User must change password at next logon"* (kasutades `net user` käsku).
* **Duplikaatide kontroll:** Ei loo kasutajat, kui nimi on juba olemas.
* **Pikkuse kontroll:** Annab veateate, kui kasutajanimi on pikem kui 20 tähemärki.
* **Kirjelduse lühendamine:** Kui kirjeldus on pikem kui 48 märki, lühendatakse seda automaatselt.
* **Grupikuuluvus:** Uued kasutajad lisatakse gruppi `Users`.
* **Puhas kood:** Skriptid ei kasuta täpitähti ega keerulisi kodeeringuid, tagamaks töökindluse igas arvutis.

## Autor

[oskar leps]
