# =============================================================================
# TEINE SKRIPT: ADMINISTRAATORI TEGEVUSED (AINULT LADINA TÄHED)
# =============================================================================

# Admini kontroll
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { 
    Write-Warning "Palun kaivita see skript ADMINISTRAATORINA!"
    exit 
}

$CsvFail = "new_users_accounts.csv"
# Kasutajad, keda me ei puutu
$VaikimisiKasutajad = @("Administrator", "Guest", "DefaultAccount", "WDAGUtilityAccount", $env:USERNAME)

Write-Host "`nVALI TEGEVUS:" -ForegroundColor Cyan
Write-Host "1. Lisa koik kasutajad failist '$CsvFail'"
Write-Host "2. Kustuta kasutaja(d)"
$Valik = Read-Host "Sinu valik (1 voi 2)"

# =============================================================================
# TEGEVUS 1: LISAMINE
# =============================================================================
if ($Valik -eq "1") {
    
    if (-not (Test-Path $CsvFail)) { 
        Write-Error "CSV faili ei leitud! Palun kaivita enne esimene skript."
        exit 
    }

    # Import ilma erilise kodeeringuta (kuna failis on ainult ladina tähed)
    $Kasutajad = Import-Csv -Path $CsvFail -Delimiter ';'

    foreach ($Rida in $Kasutajad) {
        $Kasutajanimi = $Rida.Kasutajanimi
        $Taisnimi     = "$($Rida.Eesnimi) $($Rida.Perenimi)"
        $Parool       = $Rida.Parool
        $Kirjeldus    = $Rida.Kirjeldus
        
        Write-Host "Tootlen: $Kasutajanimi..." -NoNewline

        # --- KONTROLLID ---
        
        # 1. Duplikaat
        if (Get-LocalUser -Name $Kasutajanimi -ErrorAction SilentlyContinue) {
            Write-Host " [VIGA] Ei saa lisada: Kasutaja on juba olemas." -ForegroundColor Red
            continue
        }

        # 2. Liiga pikk nimi (> 20)
        if ($Kasutajanimi.Length -gt 20) {
            Write-Host " [VIGA] Ei saa lisada: Nimi on liiga pikk (>20)." -ForegroundColor Red
            continue
        }

        # 3. Liiga pikk kirjeldus (> 48) -> Luhendamine
        if ($Kirjeldus.Length -gt 48) {
            $Kirjeldus = $Kirjeldus.Substring(0, 48)
            Write-Host " [INFO] Kirjeldus oli pikk, luhendasin..." -ForegroundColor Yellow -NoNewline
        }

        # --- LOOMINE ---
        try {
            $SecurePassword = ConvertTo-SecureString $Parool -AsPlainText -Force

            # Loome kasutaja
            New-LocalUser -Name $Kasutajanimi `
                          -Password $SecurePassword `
                          -FullName $Taisnimi `
                          -Description $Kirjeldus `
                          -ErrorAction Stop | Out-Null
            
            # Sunnime parooli vahetust
            net user $Kasutajanimi /logonpasswordchg:yes | Out-Null

            # Lisame gruppi Users
            Add-LocalGroupMember -Group "Users" -Member $Kasutajanimi -ErrorAction Stop

            Write-Host " [OK] Lisatud." -ForegroundColor Green
        }
        catch {
            Write-Host " [VIGA] Tehniline torge: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host "`n--- Susteemis olevad lisatud kasutajad ---" -ForegroundColor Cyan
    Get-LocalUser | Where-Object { $_.Name -notin $VaikimisiKasutajad } | Select-Object Name, Description | Format-Table -AutoSize

# =============================================================================
# TEGEVUS 2: KUSTUTAMINE
# =============================================================================
} elseif ($Valik -eq "2") {
    
    $Kustutatavad = Get-LocalUser | Where-Object { $_.Name -notin $VaikimisiKasutajad }
    
    if (-not $Kustutatavad) {
        Write-Host "Susteemis pole uhtegi lisatud kasutajat, keda kustutada." -ForegroundColor Red
        exit
    }

    $Kustutatavad | Select-Object Name, Description | Format-Table -AutoSize

    Write-Host "Sisesta kasutajanimi, keda kustutada." 
    Write-Host "(Vihje: Kirjuta 'koik' kui soovid testimiseks platsi puhtaks luua)" -ForegroundColor DarkGray
    $Sisestus = Read-Host "Sinu valik"

    # --- KUSTUTA KÕIK ---
    if ($Sisestus.ToLower() -eq "koik") {
        
        Write-Host "Kustutan KOIK lisatud kasutajad..." -ForegroundColor Magenta
        foreach ($User in $Kustutatavad) {
            try {
                Remove-LocalUser -Name $User.Name -ErrorAction Stop
                
                # Kodukaust
                $KoduKaust = "C:\Users\$($User.Name)"
                if (Test-Path $KoduKaust) { 
                    Remove-Item -Path $KoduKaust -Recurse -Force -ErrorAction SilentlyContinue 
                }

                Write-Host " - Kustutatud: $($User.Name)" -ForegroundColor Green
            }
            catch {
                Write-Host " - Viga $($User.Name): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        Write-Host "Valmis. Koik testkasutajad eemaldatud."

    # --- KUSTUTA ÜKS ---
    } else {
        $KustutatavNimi = $Sisestus

        if ($KustutatavNimi -in $VaikimisiKasutajad) {
            Write-Warning "Seda kasutajat ei tohi kustutada!"
            exit
        }

        if (Get-LocalUser -Name $KustutatavNimi -ErrorAction SilentlyContinue) {
            try {
                Remove-LocalUser -Name $KustutatavNimi -ErrorAction Stop
                
                # Kodukaust
                $KoduKaust = "C:\Users\$KustutatavNimi"
                if (Test-Path $KoduKaust) {
                    Remove-Item -Path $KoduKaust -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Host "Kodukaust '$KoduKaust' eemaldatud." -ForegroundColor Green
                }
                
                Write-Host "Kasutaja '$KustutatavNimi' on kustutatud." -ForegroundColor Green
            } catch { Write-Error "Viga: $($_.Exception.Message)" }
        } else {
            Write-Host "Sellist kasutajat ei leitud." -ForegroundColor Red
        }
    }
}