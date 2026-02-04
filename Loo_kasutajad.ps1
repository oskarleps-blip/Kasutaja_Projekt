# --- SEADISTUSED ---

# Määrame failinimed sisendiks ja väljundiks
$FirstNameFile = "eesnimed.txt"
$LastNameFile = "perenimed.txt"
$DescriptionFile = "kirjeldused.txt"
$OutputFile = "new_users_accounts.csv"

# --- FUNKTSIOONID ---

# Funktsioon teksti puhastamiseks (eemaldab täpitähed, tühikud jne)
function Clean-Text ($InputText) {
    # Käsitsi asendus 'õ' tähele, kuna automaatika võib sellega eksida
    $InputText = $InputText -replace 'õ', 'o' -replace 'Õ', 'O'
    
    # Normaliseerime teksti (eraldame täpitähed põhitähtedest)
    $Normalized = $InputText.Normalize([Text.NormalizationForm]::FormD)
    
    # Eemaldame kõik märgid, mis ei ole tähed (ehk eemaldame täpid)
    $CleanString = -join ($Normalized.ToCharArray() | Where-Object { 
        [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne [Globalization.UnicodeCategory]::NonSpacingMark 
    })
    
    # Eemaldame tühikud ja sidekriipsud ning teeme kõik väiketähtedeks
    return ($CleanString -replace '[\s-]', '').ToLower()
}

# Funktsioon suvalise parooli genereerimiseks (5-8 märki)
function Generate-Password {
    $Length = Get-Random -Minimum 5 -Maximum 9
    $Chars = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    $Password = -join (1..$Length | ForEach-Object { $Chars[(Get-Random -Maximum $Chars.Length)] })
    return $Password
}

# --- PÕHISKRIPT ---

# Kontrollime, kas vajalikud tekstifailid on olemas
if (-not (Test-Path $FirstNameFile) -or -not (Test-Path $LastNameFile)) {
    Write-Host "VIGA: Andmefailid on puudu! Kontrolli, kas failid asuvad samas kaustas." -ForegroundColor Red
    exit
}

# Loeme failide sisu mällu
$FirstNamesList = Get-Content $FirstNameFile -Encoding UTF8
$LastNamesList = Get-Content $LastNameFile -Encoding UTF8
$DescriptionsList = Get-Content $DescriptionFile -Encoding UTF8

# Loome tühja listi kasutajate hoidmiseks
$UsersList = @()

Write-Host "`nGenerating 5 new users..." -ForegroundColor Cyan
Write-Host "------------------------------------------------------"

# Käivitame tsükli 5 korda
1..5 | ForEach-Object {
    # Valime suvalised andmed listidest
    $RandomFirstName = $FirstNamesList | Get-Random
    $RandomLastName = $LastNamesList | Get-Random
    $RandomDescription = $DescriptionsList | Get-Random

    # Töötleme andmed kasutajanime jaoks
    $CleanFirst = Clean-Text $RandomFirstName
    $CleanLast = Clean-Text $RandomLastName
    $Username = "$CleanFirst.$CleanLast"
    
    # Genereerime parooli
    $Password = Generate-Password

    # Loome uue objekti (NB: omaduste nimed on eesti keeles, sest need lähevad CSV päisesse)
    $NewUser = [PSCustomObject]@{
        Eesnimi      = $RandomFirstName
        Perenimi     = $RandomLastName
        Kasutajanimi = $Username
        Parool       = $Password
        Kirjeldus    = $RandomDescription
    }
    
    # Lisame kasutaja üldisesse listi
    $UsersList += $NewUser
}

# --- VÄLJUND ---

# 1. Kuvame info konsoolis (lõikame kirjelduse lühemaks visuaalse selguse huvides)
$UsersList | Select-Object Eesnimi, Perenimi, Kasutajanimi, Parool, @{Name="Kirjeldus (algus)"; Expression={$_.Kirjeldus.Substring(0, [math]::Min(10, $_.Kirjeldus.Length)) + ".."}} | Format-Table -AutoSize

# 2. Salvestame andmed CSV faili (Eraldaja on semikoolon ';')
$UsersList | Export-Csv -Path $OutputFile -Delimiter ';' -NoTypeInformation -Encoding UTF8

Write-Host "Tehtud! Fail '$OutputFile' on salvestatud." -ForegroundColor Green