#Requires -RunAsAdministrator

# Renkli cikti icin fonksiyonlar
function Write-ColorText {
    param($Text, $Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Show-Header {
    Clear-Host
    Write-ColorText "================================================================" Cyan
    Write-ColorText "          GELISMIS DOSYA ANALIZ SISTEMI v2.0                  " Cyan
    Write-ColorText "          Silinen, Indirilen ve Degistirilen Dosyalar         " Cyan
    Write-ColorText "                                                                " Cyan
    Write-ColorText "                   METOXD Development                        " DarkCyan
    Write-ColorText "================================================================" Cyan
    Write-Host ""
}

function Show-Menu {
    Write-ColorText "======================= ANA MENU =======================" Yellow
    Write-Host ""
    Write-ColorText " [1] " Green -NoNewline; Write-Host "Indirilen Dosyalar (Downloads)"
    Write-ColorText " [2] " Green -NoNewline; Write-Host "Son Degistirilen Dosyalar (Hizli Tarama)"
    Write-ColorText " [3] " Green -NoNewline; Write-Host "Son Degistirilen Dosyalar (TUM SURUCULER - Detayli)"
    Write-ColorText " [4] " Green -NoNewline; Write-Host "Yeni Olusturulan Dosyalar"
    Write-ColorText " [5] " Green -NoNewline; Write-Host "Geri Donusum Kutusu Icerigi"
    Write-ColorText " [6] " Green -NoNewline; Write-Host "Isim Degisikligi Gecmisi (Event Log)"
    Write-ColorText " [7] " Green -NoNewline; Write-Host "Silinmis Dosya Izleri (USN Journal)"
    Write-ColorText " [8] " Green -NoNewline; Write-Host "Gecici Dosyalar (Temp)"
    Write-ColorText " [9] " Green -NoNewline; Write-Host "Tarayici Indirme Gecmisi"
    Write-ColorText " [A] " Cyan -NoNewline; Write-Host "Tum Kategorileri Goster"
    Write-ColorText " [0] " Red -NoNewline; Write-Host "Cikis"
    Write-Host ""
    Write-ColorText "========================================================" Yellow
    Write-Host ""
}

function Get-DownloadedFiles {
    Show-Header
    Write-ColorText "INDIRILEN DOSYALAR ANALIZI" Magenta
    Write-Host ""
    
    $downloadPath = "$env:USERPROFILE\Downloads"
    if (Test-Path $downloadPath) {
        $files = Get-ChildItem -Path $downloadPath -Recurse -File -ErrorAction SilentlyContinue | 
                 Sort-Object LastWriteTime -Descending | Select-Object -First 50
        
        if ($files) {
            Write-ColorText "Son 50 Indirilen Dosya:" Green
            Write-Host ""
            $files | Format-Table @{
                Label="Dosya Adi"; Expression={$_.Name}; Width=40
            }, @{
                Label="Boyut (MB)"; Expression={[math]::Round($_.Length/1MB, 2)}
            }, @{
                Label="Indirilme Tarihi"; Expression={$_.LastWriteTime}
            }, @{
                Label="Tam Yol"; Expression={$_.FullName}; Width=50
            } -AutoSize
        } else {
            Write-ColorText "Indirilen dosya bulunamadi." Yellow
        }
    } else {
        Write-ColorText "Downloads klasoru bulunamadi." Red
    }
    
    Write-Host ""
    Read-Host "Devam etmek icin Enter'a basin"
}

function Get-RecentlyModifiedFiles {
    Show-Header
    Write-ColorText "SON DEGISTIRILEN DOSYALAR (HIZLI TARAMA)" Magenta
    Write-Host ""
    
    $days = Read-Host "Kac gun oncesine kadar tarama yapilsin? (varsayilan: 1)"
    if ([string]::IsNullOrWhiteSpace($days)) { $days = 1 }
    
    Write-ColorText "Son $days gundeki degisiklikler taranyor..." Yellow
    Write-ColorText "Onemli konumlar taranyor (hizli tarama)..." Gray
    Write-Host ""
    
    $cutoffDate = (Get-Date).AddDays(-[int]$days)
    
    $searchPaths = @(
        "$env:USERPROFILE\Desktop",
        "$env:USERPROFILE\Documents",
        "$env:USERPROFILE\Downloads",
        "$env:USERPROFILE\Pictures",
        "$env:USERPROFILE\Videos",
        "$env:USERPROFILE\Music"
    )
    
    $allFiles = @()
    
    foreach ($path in $searchPaths) {
        if (Test-Path $path) {
            Write-ColorText "Taraniyor: $path" DarkGray
            try {
                $files = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue |
                         Where-Object { $_.LastWriteTime -gt $cutoffDate } |
                         Sort-Object LastWriteTime -Descending
                $allFiles += $files
            } catch {
                Write-ColorText "Hata: $path erisilemedi" Red
            }
        }
    }
    
    Write-Host ""
    
    if ($allFiles.Count -gt 0) {
        Write-ColorText "Toplam $($allFiles.Count) degistirilmis dosya bulundu." Green
        Write-ColorText "En son 100 dosya gosteriliyor:" Yellow
        Write-Host ""
        
        $allFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 100 | Format-Table @{
            Label="Dosya Adi"; Expression={$_.Name}; Width=35
        }, @{
            Label="Degistirilme Tarihi"; Expression={$_.LastWriteTime.ToString("dd.MM.yyyy HH:mm:ss")}
        }, @{
            Label="Boyut"; Expression={
                if ($_.Length -gt 1MB) { "{0:N2} MB" -f ($_.Length/1MB) }
                elseif ($_.Length -gt 1KB) { "{0:N2} KB" -f ($_.Length/1KB) }
                else { "$($_.Length) B" }
            }
        }, @{
            Label="Konum"; Expression={$_.DirectoryName}; Width=40
        } -AutoSize
    } else {
        Write-ColorText "Son $days gunde degistirilmis dosya bulunamadi." Yellow
    }
    
    Write-Host ""
    Read-Host "Devam etmek icin Enter'a basin"
}

function Get-AllDrivesModifiedFiles {
    Show-Header
    Write-ColorText "TUM SURUCULER - DETAYLI TARAMA" Magenta
    Write-ColorText "Bu islem uzun surebilir! Lutfen bekleyin..." Yellow
    Write-Host ""
    
    $days = Read-Host "Kac gun oncesine kadar tarama yapilsin? (varsayilan: 3)"
    if ([string]::IsNullOrWhiteSpace($days)) { $days = 3 }
    
    $maxFiles = Read-Host "Her suruculden maksimum kac dosya gosterilsin? (varsayilan: 200)"
    if ([string]::IsNullOrWhiteSpace($maxFiles)) { $maxFiles = 200 }
    
    Write-Host ""
    Write-ColorText "========================================================" Cyan
    Write-ColorText "TUM SURUCULER DETAYLI OLARAK TARANIYOR..." Cyan
    Write-ColorText "========================================================" Cyan
    Write-Host ""
    
    $cutoffDate = (Get-Date).AddDays(-[int]$days)
    
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { 
        $_.Used -gt 0 -and $_.Root -match '^[A-Z]:\\$' 
    }
    
    $totalFiles = @()
    $driveCount = 0
    
    foreach ($drive in $drives) {
        $driveCount++
        $driveLetter = $drive.Name
        
        Write-ColorText "--------------------------------------------------------" Green
        Write-ColorText "SURUCU [$driveLetter] TARANIYOR... ($driveCount/$($drives.Count))" Green
        Write-ColorText "--------------------------------------------------------" Green
        
        try {
            $driveRoot = "$($driveLetter):\"
            
            $driveInfo = Get-PSDrive $driveLetter
            $freeSpace = [math]::Round($driveInfo.Free / 1GB, 2)
            $usedSpace = [math]::Round($driveInfo.Used / 1GB, 2)
            
            Write-Host "  Toplam Kullanilan: " -NoNewline
            Write-ColorText "$usedSpace GB" Yellow
            Write-Host "  Bos Alan: " -NoNewline
            Write-ColorText "$freeSpace GB" Cyan
            Write-Host ""
            
            $startTime = Get-Date
            
            $files = Get-ChildItem -Path $driveRoot -Recurse -File -ErrorAction SilentlyContinue |
                     Where-Object { 
                         $_.LastWriteTime -gt $cutoffDate -and
                         $_.DirectoryName -notmatch '\$Recycle\.Bin' -and
                         $_.DirectoryName -notmatch 'System Volume Information'
                     } |
                     Sort-Object LastWriteTime -Descending |
                     Select-Object -First $maxFiles
            
            $endTime = Get-Date
            $scanDuration = ($endTime - $startTime).TotalSeconds
            
            if ($files) {
                $fileCount = $files.Count
                Write-ColorText "  Bulundu: $fileCount dosya (Tarama suresi: $([math]::Round($scanDuration, 1)) saniye)" Green
                
                $totalFiles += $files
                
                Write-Host ""
                Write-ColorText "  En Son Degistirilen 10 Dosya:" White
                $files | Select-Object -First 10 | ForEach-Object {
                    $fileSize = if ($_.Length -gt 1MB) { 
                        "{0:N2} MB" -f ($_.Length/1MB) 
                    } elseif ($_.Length -gt 1KB) { 
                        "{0:N2} KB" -f ($_.Length/1KB) 
                    } else { 
                        "$($_.Length) B" 
                    }
                    
                    Write-Host "    * " -NoNewline
                    Write-ColorText $_.Name White -NoNewline
                    Write-Host " - " -NoNewline
                    Write-ColorText $_.LastWriteTime.ToString("dd.MM.yyyy HH:mm") Cyan -NoNewline
                    Write-Host " - " -NoNewline
                    Write-ColorText $fileSize Yellow
                }
                Write-Host ""
            } else {
                Write-ColorText "  Son $days gunde degisiklik bulunamadi" Red
                Write-Host ""
            }
            
        } catch {
            Write-ColorText "  Hata: $($_.Exception.Message)" Red
            Write-Host ""
        }
    }
    
    Write-Host ""
    Write-ColorText "========================================================" Magenta
    Write-ColorText "               GENEL TARAMA OZETI" Magenta
    Write-ColorText "========================================================" Magenta
    Write-Host ""
    Write-Host "  Taranan Surucu Sayisi: " -NoNewline
    Write-ColorText $drives.Count Green
    Write-Host "  Toplam Bulunan Dosya: " -NoNewline
    Write-ColorText $totalFiles.Count Yellow
    Write-Host "  Tarama Donemi: " -NoNewline
    Write-ColorText "Son $days gun" Cyan
    Write-Host ""
    
    if ($totalFiles.Count -gt 0) {
        Write-ColorText "En Son Degistirilen 50 Dosya (Tum Suruculer):" White
        Write-Host ""
        
        $totalFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 50 | Format-Table @{
            Label="Surucu"; Expression={$_.FullName.Substring(0,2)}; Width=7
        }, @{
            Label="Dosya Adi"; Expression={$_.Name}; Width=30
        }, @{
            Label="Degistirilme"; Expression={$_.LastWriteTime.ToString("dd.MM.yyyy HH:mm:ss")}
        }, @{
            Label="Boyut"; Expression={
                if ($_.Length -gt 1MB) { "{0:N2} MB" -f ($_.Length/1MB) }
                elseif ($_.Length -gt 1KB) { "{0:N2} KB" -f ($_.Length/1KB) }
                else { "$($_.Length) B" }
            }
        }, @{
            Label="Konum"; Expression={$_.DirectoryName}; Width=45
        } -AutoSize
    }
    
    Write-Host ""
    Write-ColorText "========================================================" Magenta
    Write-Host ""
    Read-Host "Devam etmek icin Enter'a basin"
}

function Get-NewlyCreatedFiles {
    Show-Header
    Write-ColorText "YENI OLUSTURULAN DOSYALAR" Magenta
    Write-Host ""
    
    $hours = Read-Host "Son kac saatteki dosyalar? (varsayilan: 24)"
    if ([string]::IsNullOrWhiteSpace($hours)) { $hours = 24 }
    
    $cutoffDate = (Get-Date).AddHours(-$hours)
    $userProfile = $env:USERPROFILE
    
    Write-ColorText "Son $hours saatteki yeni dosyalar taraniyor..." Yellow
    
    $files = Get-ChildItem -Path $userProfile -Recurse -File -ErrorAction SilentlyContinue |
             Where-Object { $_.CreationTime -gt $cutoffDate } |
             Sort-Object CreationTime -Descending
    
    if ($files) {
        $files | Format-Table Name, @{
            Label="Olusturulma"; Expression={$_.CreationTime}
        }, @{
            Label="Boyut (KB)"; Expression={[math]::Round($_.Length/1KB, 2)}
        }, DirectoryName -AutoSize
    } else {
        Write-ColorText "Yeni dosya bulunamadi." Yellow
    }
    
    Write-Host ""
    Read-Host "Devam etmek icin Enter'a basin"
}

function Get-RecycleBinContents {
    Show-Header
    Write-ColorText "GERI DONUSUM KUTUSU ICERIGI" Magenta
    Write-Host ""
    
    try {
        $shell = New-Object -ComObject Shell.Application
        $recycleBin = $shell.NameSpace(10)
        
        $itemCount = 0
        try {
            $itemCount = $recycleBin.Items().Count
        } catch {
            $itemCount = 0
        }
        
        if ($itemCount -gt 0) {
            Write-ColorText "Geri Donusum Kutusunda $itemCount oge bulundu:" Green
            Write-Host ""
            
            $counter = 1
            foreach ($item in $recycleBin.Items()) {
                try {
                    Write-ColorText "[$counter] -----------------------------------------" DarkGray
                    Write-Host "Dosya Adi    : " -NoNewline
                    Write-ColorText $item.Name White
                    
                    $originalPath = $recycleBin.GetDetailsOf($item, 1)
                    if ($originalPath) {
                        Write-Host "Orijinal Yol : " -NoNewline
                        Write-ColorText $originalPath Gray
                    }
                    
                    $deleteDate = $recycleBin.GetDetailsOf($item, 2)
                    if ($deleteDate) {
                        Write-Host "Silinme Tarihi: " -NoNewline
                        Write-ColorText $deleteDate Cyan
                    }
                    
                    $size = $recycleBin.GetDetailsOf($item, 3)
                    if ($size) {
                        Write-Host "Boyut        : " -NoNewline
                        Write-ColorText $size Yellow
                    }
                    
                    $counter++
                } catch {
                    Write-ColorText "Oge okunamadi" Red
                }
            }
        } else {
            Write-ColorText "Geri Donusum Kutusu bos." Yellow
        }
    } catch {
        Write-ColorText "Geri Donusum Kutusu erisim hatasi: $($_.Exception.Message)" Red
        Write-ColorText "Alternatif yontem deneniyor..." Yellow
        
        $recycleBinPath = "$env:SystemDrive\`$Recycle.Bin"
        if (Test-Path $recycleBinPath) {
            $items = Get-ChildItem -Path $recycleBinPath -Recurse -Force -ErrorAction SilentlyContinue
            if ($items) {
                Write-ColorText "Geri Donusum Kutusu dosya yapisi:" Green
                $items | Where-Object { -not $_.PSIsContainer } | Select-Object -First 20 | Format-Table Name, Length, LastWriteTime -AutoSize
            }
        }
    }
    
    Write-Host ""
    Read-Host "Devam etmek icin Enter'a basin"
}

function Get-FileRenameHistory {
    Show-Header
    Write-ColorText "DOSYA ISIM DEGISIKLIGI GECMISI" Magenta
    Write-Host ""
    
    Write-ColorText "Son dosya islemleri taraniyor..." Yellow
    Write-Host ""
    
    try {
        $events = Get-WinEvent -FilterHashtable @{
            LogName='Security'
            ID=4663
            StartTime=(Get-Date).AddDays(-7)
        } -MaxEvents 500 -ErrorAction Stop
        
        $renameEvents = $events | Where-Object { 
            $_.Message -like "*WRITE_ATTRIBUTES*" -or 
            $_.Message -like "*WriteData*" 
        } | Select-Object -First 50
        
        if ($renameEvents) {
            Write-ColorText "Son 50 dosya degisiklik kaydi:" Green
            Write-Host ""
            
            foreach ($event in $renameEvents) {
                $message = $event.Message
                $objectName = ""
                
                if ($message -match "Object Name:\s+(.+)") {
                    $objectName = $matches[1].Trim()
                }
                
                Write-ColorText "-------------------------------------------" DarkGray
                Write-Host "Tarih: " -NoNewline
                Write-ColorText $event.TimeCreated.ToString("dd.MM.yyyy HH:mm:ss") Cyan
                Write-Host "Islem: " -NoNewline
                Write-ColorText "Dosya Degisikligi (ID: $($event.Id))" Yellow
                if ($objectName -and $objectName -ne "") {
                    Write-Host "Dosya: " -NoNewline
                    Write-ColorText $objectName White
                }
            }
        } else {
            Write-ColorText "Dosya degisiklik kaydi bulunamadi." Yellow
        }
    } catch {
        Write-ColorText "Event Log okuma hatasi: $($_.Exception.Message)" Red
        Write-ColorText "Alternatif: Kullanici profilindeki son degisiklikler kontrol ediliyor..." Yellow
        Write-Host ""
        
        $recentFiles = Get-ChildItem -Path $env:USERPROFILE -Recurse -File -ErrorAction SilentlyContinue |
                       Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-24) } |
                       Sort-Object LastWriteTime -Descending |
                       Select-Object -First 30
        
        if ($recentFiles) {
            Write-ColorText "Son 24 saatte degistirilen dosyalar:" Green
            $recentFiles | Format-Table Name, LastWriteTime, DirectoryName -AutoSize
        }
    }
    
    Write-Host ""
    Read-Host "Devam etmek icin Enter'a basin"
}

function Get-USNJournalDeletes {
    Show-Header
    Write-ColorText "SILINMIS DOSYA IZLERI (USN Journal)" Magenta
    Write-Host ""
    
    Write-ColorText "USN Journal analiz ediliyor..." Yellow
    Write-Host ""
    
    try {
        $result = fsutil usn queryjournal C: 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorText "USN Journal aktif ve calisiyor." Green
            Write-Host ""
            
            Write-ColorText "Son dosya islemleri:" Yellow
            
            $startOutput = fsutil usn readjournal C: | Select-Object -First 100
            
            if ($startOutput) {
                $startOutput | ForEach-Object {
                    if ($_ -match "File name:(.+)") {
                        $fileName = $matches[1].Trim()
                        Write-ColorText "  * $fileName" White
                    }
                }
            } else {
                Write-ColorText "Journal okunamadi veya bos." Yellow
            }
        } else {
            Write-ColorText "USN Journal bu suruculde etkin degil." Yellow
        }
        
        Write-Host ""
        Write-ColorText "Alternatif: Son silinen dosyalarin izleri..." Cyan
        
        $recycleUsers = Get-ChildItem -Path "C:\`$Recycle.Bin" -Force -Directory -ErrorAction SilentlyContinue
        
        if ($recycleUsers) {
            foreach ($userFolder in $recycleUsers) {
                $deletedFiles = Get-ChildItem -Path $userFolder.FullName -Force -ErrorAction SilentlyContinue |
                                Where-Object { $_.Name -like "`$R*" } |
                                Sort-Object LastWriteTime -Descending |
                                Select-Object -First 20
                
                if ($deletedFiles) {
                    Write-Host ""
                    Write-ColorText "Kullanici: $($userFolder.Name)" Green
                    $deletedFiles | Format-Table @{
                        Label="Dosya"; Expression={$_.Name}
                    }, @{
                        Label="Silinme Zamani"; Expression={$_.LastWriteTime.ToString("dd.MM.yyyy HH:mm:ss")}
                    }, @{
                        Label="Boyut"; Expression={
                            if ($_.Length -gt 1MB) { "{0:N2} MB" -f ($_.Length/1MB) }
                            else { "{0:N2} KB" -f ($_.Length/1KB) }
                        }
                    } -AutoSize
                }
            }
        }
        
    } catch {
        Write-ColorText "Hata: $($_.Exception.Message)" Red
        Write-ColorText "USN Journal erisimi icin yonetici haklari gereklidir." Yellow
    }
    
    Write-Host ""
    Read-Host "Devam etmek icin Enter'a basin"
}

function Get-TempFiles {
    Show-Header
    Write-ColorText "GECICI DOSYALAR ANALIZI" Magenta
    Write-Host ""
    
    $tempPaths = @(
        "$env:TEMP",
        "$env:USERPROFILE\AppData\Local\Temp",
        "C:\Windows\Temp"
    )
    
    foreach ($path in $tempPaths) {
        if (Test-Path $path) {
            Write-ColorText "Konum: $path" Cyan
            $files = Get-ChildItem -Path $path -File -ErrorAction SilentlyContinue |
                     Sort-Object LastWriteTime -Descending |
                     Select-Object -First 20
            
            if ($files) {
                $files | Format-Table Name, @{
                    Label="Degistirilme"; Expression={$_.LastWriteTime}
                }, @{
                    Label="Boyut (KB)"; Expression={[math]::Round($_.Length/1KB, 2)}
                } -AutoSize
            }
        }
    }
    
    Write-Host ""
    Read-Host "Devam etmek icin Enter'a basin"
}

function Get-BrowserDownloadHistory {
    Show-Header
    Write-ColorText "TARAYICI INDIRME GECMISI" Magenta
    Write-Host ""
    
    $foundAny = $false
    
    $chromePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History"
    if (Test-Path $chromePath) {
        Write-ColorText "Chrome Indirme Veritabani Bulundu" Green
        Write-ColorText "  Konum: $chromePath" Gray
        $chromeSize = (Get-Item $chromePath).Length / 1KB
        Write-ColorText "  Boyut: $([math]::Round($chromeSize, 2)) KB" Gray
        Write-Host ""
        $foundAny = $true
    }
    
    $edgePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\History"
    if (Test-Path $edgePath) {
        Write-ColorText "Edge Indirme Veritabani Bulundu" Green
        Write-ColorText "  Konum: $edgePath" Gray
        $edgeSize = (Get-Item $edgePath).Length / 1KB
        Write-ColorText "  Boyut: $([math]::Round($edgeSize, 2)) KB" Gray
        Write-Host ""
        $foundAny = $true
    }
    
    $firefoxProfilePath = "$env:APPDATA\Mozilla\Firefox\Profiles"
    if (Test-Path $firefoxProfilePath) {
        $profiles = Get-ChildItem -Path $firefoxProfilePath -Directory -ErrorAction SilentlyContinue
        foreach ($profile in $profiles) {
            $placesDB = Join-Path $profile.FullName "places.sqlite"
            if (Test-Path $placesDB) {
                Write-ColorText "Firefox Indirme Veritabani Bulundu" Green
                Write-ColorText "  Profil: $($profile.Name)" Gray
                Write-ColorText "  Konum: $placesDB" Gray
                $ffSize = (Get-Item $placesDB).Length / 1KB
                Write-ColorText "  Boyut: $([math]::Round($ffSize, 2)) KB" Gray
                Write-Host ""
                $foundAny = $true
            }
        }
    }
    
    $bravePath = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\History"
    if (Test-Path $bravePath) {
        Write-ColorText "Brave Indirme Veritabani Bulundu" Green
        Write-ColorText "  Konum: $bravePath" Gray
        $braveSize = (Get-Item $bravePath).Length / 1KB
        Write-ColorText "  Boyut: $([math]::Round($braveSize, 2)) KB" Gray
        Write-Host ""
        $foundAny = $true
    }
    
    $operaPath = "$env:APPDATA\Opera Software\Opera Stable\History"
    if (Test-Path $operaPath) {
        Write-ColorText "Opera Indirme Veritabani Bulundu" Green
        Write-ColorText "  Konum: $operaPath" Gray
        $operaSize = (Get-Item $operaPath).Length / 1KB
        Write-ColorText "  Boyut: $([math]::Round($operaSize, 2)) KB" Gray
        Write-Host ""
        $foundAny = $true
    }
    
    if (-not $foundAny) {
        Write-ColorText "Hicbir tarayici gecmisi bulunamadi." Yellow
        Write-Host ""
    }
    
    Write-ColorText "-----------------------------------------------------" DarkGray
    Write-ColorText "Not: Bu veritabanlarini detayli okumak icin:" Yellow
    Write-ColorText "  * DB Browser for SQLite gibi araclar kullanabilirsiniz" Gray
    Write-ColorText "  * Veya Downloads klasorundenindirilen dosyalari inceleyebilirsiniz" Gray
    
    Write-Host ""
    Read-Host "Devam etmek icin Enter'a basin"
}

function Show-AllCategories {
    Get-DownloadedFiles
    Get-RecentlyModifiedFiles
    Get-NewlyCreatedFiles
    Get-RecycleBinContents
    Get-TempFiles
}

# Ana program dongusu
do {
    Show-Header
    Show-Menu
    
    $choice = Read-Host "Seciminizi yapin (0-9 veya A)"
    
    switch ($choice) {
        "1" { Get-DownloadedFiles }
        "2" { Get-RecentlyModifiedFiles }
        "3" { Get-AllDrivesModifiedFiles }
        "4" { Get-NewlyCreatedFiles }
        "5" { Get-RecycleBinContents }
        "6" { Get-FileRenameHistory }
        "7" { Get-USNJournalDeletes }
        "8" { Get-TempFiles }
        "9" { Get-BrowserDownloadHistory }
        "A" { Show-AllCategories }
        "a" { Show-AllCategories }
        "0" { 
            Show-Header
            Write-ColorText "Program kapatiliyor... Gule gule!" Green
            Start-Sleep -Seconds 2
            exit
        }
        default { 
            Write-ColorText "Gecersiz secim! Lutfen 0-9 veya A tusuna basin." Red
            Start-Sleep -Seconds 2
        }
    }
} while ($true)
 