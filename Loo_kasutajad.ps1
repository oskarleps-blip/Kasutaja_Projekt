# =============================================================================
# ESIMENE SKRIPT: GENEREERI KASUTAJAD (AINULT LADINA TÄHED)
# =============================================================================

Write-Host "Genereerin 5 uut kasutajat..." -ForegroundColor Cyan

# 1. ANDMEBAAS (Kõik nimed ja sõnad on ilma täpitähtedeta)
$Eesnimed  = @("Mati", "Kati", "Juri", "Tonu", "Ulle", "Sten", "Liis", "Mariel", "Daaniel")
$Perenimed = @("Tamm", "Kask", "Lepik", "Sepp", "Kukk", "Juhkam", "Lehiste", "Lohmus", "Tammik")

$Kirjeldused = @(
    "Vastutab susteemi laiade haldusulesannete eest (sh legacy susteemid).",
    "Haldab susteemi turvaseadeid ja teostab oiseid auditeid.",
    "Loob ja arendab tarkvara, tegeleb susteemi arendusprojektidega.",
    "Vastutab ettevotte finantsjuhtimise eest: eelarved ja analuus.",
    "Vastutab IT-taristu igapaevase toimimise eest."
)

$UuedKasutajad = @()

# 2. GENEREERIMINE
for ($i = 1; $i -le 5; $i++) {
    
    # Valime suvalised andmed
    $Eesnimi   = $Eesnimed | Get-Random
    $Perenimi  = $Perenimed | Get-Random
    $Kirjeldus = $Kirjeldused | Get-Random
    
    # Teeme kasutajanime (väikesed tähed: juri.tamm)
    $Kasutajanimi = "$($Eesnimi.ToLower()).$($Perenimi.ToLower())"

    # Parooli genereerimine (lihtne tähtede ja numbrite jada)
    $Pikkus = Get-Random -Minimum 8 -Maximum 13
    $Tarestik = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    $Parool = ""
    for ($k = 0; $k -lt $Pikkus; $k++) { 
        $Parool += $Tarestik[(Get-Random -Maximum $Tarestik.Length)] 
    }

    # Loome objekti
    $KasutajaObjekt = [PSCustomObject]@{
        Eesnimi      = $Eesnimi
        Perenimi     = $Perenimi
        Kasutajanimi = $Kasutajanimi
        Parool       = $Parool
        Kirjeldus    = $Kirjeldus
    }

    $UuedKasutajad += $KasutajaObjekt
    Write-Host " - Valmis: $Eesnimi $Perenimi ($Kasutajanimi)" -ForegroundColor Gray
}

# 3. SALVESTAMINE (Lihtne CSV)
$FailiNimi = "new_users_accounts.csv"
$UuedKasutajad | Export-Csv -Path $FailiNimi -NoTypeInformation -Delimiter ';'

Write-Host "`nFail '$FailiNimi' on loodud." -ForegroundColor Green