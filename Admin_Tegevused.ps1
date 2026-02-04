# =============================================================================
# TEINE SKRIPT: ADMINISTRAATORI TEGEVUSED
# =============================================================================

# 1. KODEERING JA ADMIN KONTROLL
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Käivita see skript ADMINISTRAATORINA!"
    exit
}

# SEADISTUSED
$CsvFail = "new_users_accounts.csv"
# Neid kasutajaid me ei puutu kunagi (kaitstud + sina ise)
$VaikimisiKasutajad = @("Administrator", "Guest", "DefaultAccount", "WDAGUtilityAccount", $env:USERNAME)

# 2. MENÜÜ (Ülesande järgi 2 valikut)
Write-Host "`nVALI TEGEVUS:" -ForegroundColor Cyan
Write-Host "1. Lisa kõik kasutajad failist '$CsvFail'"
Write-Host "2. Kustuta üks kasutaja"
$Valik = Read-Host "Sinu valik (1 või 2)"

# =============================================================================
# TEGEVUS 1: LISAMINE
# =============================================================================
if ($Valik -eq "1") {
    
    if (-not (Test-Path $CsvFail)) {
        Write-Error "CSV faili ei leitud! Käivita enne esimene skript."
        exit
    }

    $Kasutajad = Import-Csv -Path $CsvFail -Delimiter ';' -Encoding UTF8

    foreach ($Rida in $Kasutajad) {
        $Kasutajanimi = $Rida.Kasutajanimi
        $Taisnimi     = "$($Rida.Eesnimi) $($Rida.Perenimi)"
        $Parool       = $Rida.Parool
        $Kirjeldus    = $Rida.Kirjeldus
        
        Write-Host "Töötlen: $Kasutajanimi..." -NoNewline

        # --- KONTROLLID ---
        
        # 1. Kasutaja on juba olemas (Duplikaat)
        if (Get-LocalUser -Name $Kasutajanimi -ErrorAction SilentlyContinue) {
            Write-Host " [VIGA] Ei saa lisada: Kasutaja on juba olemas." -ForegroundColor Red
            continue
        }

        # 2. Kasutajanimi on liiga pikk (> 20 märki) -> Ülesande nõue: Ütle põhjus ja jäta vahele
        if ($Kasutajanimi.Length -gt 20) {
            Write-Host " [VIGA] Ei saa lisada: Nimi on liiga pikk (>20)." -ForegroundColor Red
            continue
        }

        # 3. Kirjeldus on liiga pikk (> 48 märki) -> Ülesande nõue: Lühenda
        if ($Kirjeldus.Length -gt 48) {
            $Kirjeldus = $Kirjeldus.Substring(0, 48)
            Write-Host " [INFO] Kirjeldus oli pikk, lühendasin..." -ForegroundColor Yellow -NoNewline
        }

        # --- LOOMINE ---
        try {
            $SecurePassword = ConvertTo-SecureString $Parool -AsPlainText -Force

            # 1. Loome kasutaja (ilma parooli aegumise lipukesteta siin, et vältida vigu)
            New-LocalUser -Name $Kasutajanimi `
                          -Password $SecurePassword `
                          -FullName $Taisnimi `
                          -Description $Kirjeldus `
                          -ErrorAction Stop | Out-Null
            
            # 2. Sunnime parooli vahetust (See käsk töötab kooliarvutites kindlamini)
            # /logonpasswordchg:yes tähendab "User must change password at next logon"
            net user $Kasutajanimi /logonpasswordchg:yes | Out-Null

            # 3. Lisame gruppi Users (Nõue)
            Add-LocalGroupMember -Group "Users" -Member $Kasutajanimi -ErrorAction Stop

            Write-Host " [OK] Lisatud." -ForegroundColor Green
        }
        catch {
            Write-Host " [VIGA] Tehniline tõrge: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # LÕPUS: Näita tulemust
    Write-Host "`n--- Süsteemis olevad lisatud kasutajad ---" -ForegroundColor Cyan
    Get-LocalUser | Where-Object { $_.Name -notin $VaikimisiKasutajad } | Select-Object Name, Description | Format-Table -AutoSize

# =============================================================================
# TEGEVUS 2: KUSTUTAMINE (ÜKS või KÕIK)
# =============================================================================
} elseif ($Valik -eq "2") {
    
    # Leiame kõik, keda tohib kustutada
    $Kustutatavad = Get-LocalUser | Where-Object { $_.Name -notin $VaikimisiKasutajad }
    
    if (-not $Kustutatavad) {
        Write-Host "Süsteemis pole ühtegi lisatud kasutajat, keda kustutada." -ForegroundColor Red
        exit
    }

    # Kuvame nimekirja
    $Kustutatavad | Select-Object Name, Description | Format-Table -AutoSize

    Write-Host "Sisesta kasutajanimi, keda kustutada." 
    Write-Host "(Vihje: Kirjuta 'koik' kui soovid testimiseks platsi puhtaks lüüa)" -ForegroundColor DarkGray
    $Sisestus = Read-Host "Sinu valik"

    # --- SALAJANE VALIK: KUSTUTA KÕIK (Sinu testimise jaoks) ---
    if ($Sisestus.ToLower() -eq "koik") {
        
        Write-Host "Kustutan KÕIK lisatud kasutajad..." -ForegroundColor Magenta
        foreach ($User in $Kustutatavad) {
            try {
                Remove-LocalUser -Name $User.Name -ErrorAction Stop
                Write-Host " - Kustutatud: $($User.Name)" -ForegroundColor Green
                
                # Kodukaust kustutada
                $KoduKaust = "C:\Users\$($User.Name)"
                if (Test-Path $KoduKaust) { 
                    Remove-Item -Path $KoduKaust -Recurse -Force -ErrorAction SilentlyContinue 
                }
            }
            catch {
                Write-Host " - Viga $($User.Name): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        Write-Host "Valmis. Kõik testkasutajad eemaldatud."

    # --- TAVALINE VALIK: KUSTUTA ÜKS (Ülesande nõue) ---
    } else {
        $KustutatavNimi = $Sisestus

        # Kontrollime, et ei kustutaks keelatud kasutajaid
        if ($KustutatavNimi -in $VaikimisiKasutajad) {
            Write-Warning "Seda kasutajat ei tohi kustutada!"
            exit
        }

        if (Get-LocalUser -Name $KustutatavNimi -ErrorAction SilentlyContinue) {
            try {
                # 1. Kustuta kasutaja
                Remove-LocalUser -Name $KustutatavNimi -ErrorAction Stop
                Write-Host "Kasutaja '$KustutatavNimi' on kustutatud." -ForegroundColor Green
                
                # 2. Kustuta kodukaust (Nõue: "tekitatakse kaust mis on vaja ka kustutada")
                $KoduKaust = "C:\Users\$KustutatavNimi"
                if (Test-Path $KoduKaust) {
                    Remove-Item -Path $KoduKaust -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Host "Kodukaust '$KoduKaust' eemaldatud." -ForegroundColor Green
                }
            } catch { Write-Error "Viga: $($_.Exception.Message)" }
        } else {
            Write-Host "Sellist kasutajat ei leitud." -ForegroundColor Red
        }
    }
}