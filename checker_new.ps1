# ====================================================================
#   MINECRAFT CHECKER PRO (AUTONOMOUS SMART DIRECTORY SEARCH)
# ====================================================================
$webhook_url = "https://discord.com/api/webhooks/1565015662324097214/M_mLlWyFfljXceX_KcWJ3wISOxO--Lr60YGKybbu6afUWYeLgn_BQMgkPfawHIThrTpC"

# 1. Инициализация и сбор базовых данных
$pc_user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$detected_items = @()
$suspicious_processes = @()

# Получение названия сети
$network_info = Get-NetConnectionProfile | Select-Object -ExpandProperty Name -ErrorAction SilentlyContinue
$network_name = if ($network_info) { $network_info -join ", " } else { "Не удалось определить (возможно VPN/Скрыто)" }

# 2. Огромная база ключевых слов
$base_keywords = @(
    "systemdlc", "nursultan", "dimasik", "pandora", "revenge", "evaware", "revive", "norvix", "paunt", "astralis", 
    "rinals", "pouch", "catlavan", "delta", "meow", "nuclear", "ReplayMod", "IsometricRender", "CmdCam", "WorldDownloader", 
    "Flashback", "AutoMining", "ReplantingCrops", "AutoHarvest", "Reap", "Tweakeroo", "AutoFish", "Accurate Block Placement", 
    "Baritone", "Player Spotlight", "AucHelper", "ChestTracker", "Friend Highlighter", "Donut Auctions", "XRay", "DiamondGen", 
    "FreeCam", "BaseFinder", "TrueSight", "Neat", "ChunkAnimator", "MobHealthBar", "Litematica", "Schematica", 
    "block-entity-tooltip", "WorldEdit", "Better PVP", "RemoveBlindness", "Re:Entity Outline", "AntiInvis", "Cooldowns HUD", 
    "UseTracker", "CheatUtils", "No Darkness Effect", "removewardeneffect", "funtime-ah-helper", "AutoBuy", "AutoSell", 
    "AutoCasino", "AutoPilot", "InventoryControlTweaks", "AutoLeave", "Foodslot", "Quickstack", "ItemSwap", "AutoTool", 
    "Movement in GUI", "FasterBlockPlacement", "Firework Helper", "Effortless Building", "InvMove", "Inventory Profiles Next", 
    "autojumpreset", "Dont Heat Teammates", "Don't hit teammates", "CleanCut", "Attack", "Aim", "Fever", "Luminar", "Ascart", 
    "Badlion", "Simple", "SoupApi", "Wave", "ClientCommands", "quick", "hitsune", "warden", "graphite", "excellent", "arbuz", 
    "aurora", "celestial", "haruka", "impact", "inertia", "meteor", "zenith", "britva", "releon", "rockstar", "catlean", 
    "velka", "night", "nigthly", "nightix", "venus", "mercury", "eclipse", "luminous", "sakura", "sacura", "cakyra", 
    "cacura", "sadnes", "atheryx", "dama", "celevant", "xameleon", "faker", "takker", "taker", "kazakhstan client", 
    "phobia", "flow", "madness", "toshiba", "ryzen", "marafedov", "timoha", "mhub", "myau", "wonderful", "wayne", 
    "nuvera", "frozzy", "durex", "xrose", "cortex", "zedge", "aspect", "ephoria", "exp", "expcrime", "exploit", "debuda", 
    "winston", "deluxe", "eternity", "essense", "nexis"
)

# Шаблоны нечёткого поиска (Regex)
$fuzzy_patterns = @(
    "aim.*bot", "bot.*aim", ".*aim.*", ".*bot.*",
    "killaura", "trigger", "hitbox", "aura", "velocity", "flyhack"
)

# Авто-генерация мутаций
$suffixes = @("dlc", "crack", "leak", "src", "legit", "client")
$full_cheat_keywords = New-Object System.Collections.Generic.List[string]

foreach ($word in $base_keywords) {
    $full_cheat_keywords.Add($word.ToLower())
    foreach ($suffix in $suffixes) {
        $full_cheat_keywords.Add("${word}${suffix}".ToLower())
        $full_cheat_keywords.Add("${word}_${suffix}".ToLower())
        $full_cheat_keywords.Add("${word}-${suffix}".ToLower())
    }
}

# 3. Анализ запущенных и фоновых процессов
$white_list_processes = @("explorer", "svchost", "lsass", "csrss", "smss", "wininit", "winlogon", "services", "spoolsv", 
                          "taskhostw", "runtimebroker", "ctfmon", "conhost", "chrome", "opera", "discord", "steam", 
                          "yandex", "firefox", "telegram", "anydesk", "rustdesk", "nvidia", "amd", "realtek", "intel", 
                          "audiodg", "shellexperiencehost", "searchhost", "startmenuexperiencehost", "powershell", "cmd")

$processes = Get-Process | Select-Object Name, Id, Path -ErrorAction SilentlyContinue
foreach ($proc in $processes) {
    if ($proc.Name -and ($white_list_processes -notcontains $proc.Name.ToLower())) {
        $is_suspicious_proc = $false
        
        foreach ($keyword in $full_cheat_keywords) {
            if ($proc.Name.ToLower().Contains($keyword)) { $is_suspicious_proc = $true }
        }
        foreach ($pattern in $fuzzy_patterns) {
            if ($proc.Name.ToLower() -match $pattern) { $is_suspicious_proc = $true }
        }
        
        if ($is_suspicious_proc) {
            $detected_items += "Zapushenny process: $($proc.Name) (ID: $($proc.Id))"
        }
        if ($is_suspicious_proc -or $proc.Path -match "Temp|AppData\\Local\\Temp") {
            $suspicious_processes += "$($proc.Name) (ID: $($proc.Id))"
        }
    }
}

# 4. Оптимизированное сканирование критических целевых папок (Вместо всего диска)
Write-Host "[*] Executing smart directory scan..." -ForegroundColor Cyan
$target_extensions = @("*.jar", "*.exe", "*.zip", "*.rar", "*.dll")

# Список путей, где Майнкрафт и читы чаще всего находятся
$paths_to_scan = @(
    "$env:APPDATA\.minecraft",
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\Desktop",
    "$env:TEMP",
    "$env:USERPROFILE\AppData\Local\Temp",
    "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Recent"
)

[Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null

foreach ($path in $paths_to_scan) {
    if (Test-Path $path) {
        $files = Get-ChildItem -Path $path -Include $target_extensions -Recurse -File -ErrorAction SilentlyContinue
        
        foreach ($file in $files) {
            $name_lower = $file.Name.ToLower()
            $is_hit = $false
            
            # Проверка имени файла
            foreach ($keyword in $full_cheat_keywords) {
                if ($name_lower.Contains($keyword)) {
                    $is_hit = $true
                    $detected_items += "Naiden fail: $($file.FullName)"
                }
            }
            if (!$is_hit) {
                foreach ($pattern in $fuzzy_patterns) {
                    if ($name_lower -match $pattern) {
                        $is_hit = $true
                        $detected_items += "Fuzzy match fail: $($file.FullName)"
                    }
                }
            }
            
            # Сквозной анализ Java и ZIP архивов изнутри
            if (($file.Extension -eq ".jar" -or $file.Extension -eq ".zip") -and !$is_hit) {
                try {
                    $archive = [System.IO.Compression.ZipFile]::OpenRead($file.FullName)
                    foreach ($entry in $archive.Entries) {
                        $entry_lower = $entry.Name.ToLower()
                        $is_entry_hit = $false
                        
                        foreach ($keyword in $full_cheat_keywords) {
                            if ($entry_lower.Contains($keyword)) {
                                $is_entry_hit = $true
                                $detected_items += "Vnutri JAR/ZIP [$($file.Name)]: $($entry.FullName)"
                            }
                        }
                        if (!$is_entry_hit) {
                            foreach ($pattern in $fuzzy_patterns) {
                                if ($entry_lower -match $pattern) {
                                    $detected_items += "Fuzzy vnutri JAR/ZIP [$($file.Name)]: $($entry.FullName)"
                                }
                            }
                        }
                    }
                    $archive.Dispose()
                } catch {}
            }
        }
    }
}

# 5. Вердикт и отправка
$unique_detections = $detected_items | Select-Object -Unique
if ($unique_detections.Count -gt 0) {
    $verdict = "[!] VNIMANIE! NAIDENY CHITY ILI SLEDY SVOFTA! [!]`n"
    foreach ($item in $unique_detections) { $verdict += "- $item`n" }
} else {
    $verdict = "Chitov ili sledov ih udaleniya ne obnaruzheno."
}

$proc_output = if ($suspicious_processes) { ($suspicious_processes | Select-Object -First 15) -join "`n" } else { "Podozritelnyh processov ne naideno." }

$embed = @{
    title = "OTCHET O SKVOZNOM SCANIROVANII PK"
    color = if ($unique_detections.Count -gt 0) { 16711680 } else { 65280 }
    fields = @(
        @{ name = "User PC"; value = "``````$pc_user``````"; inline = $true },
        @{ name = "Network / Provider"; value = "``````$network_name``````"; inline = $true },
        @{ name = "Verdict"; value = $verdict; inline = $false },
        @{ name = "Active Processes (Top-15)"; value = "``````" + $proc_output + "``````"; inline = $false }
    )
}

$json_payload = [PSCustomObject]@{ embeds = @($embed) } | ConvertTo-Json -Depth 5

try {
    Invoke-RestMethod -Uri $webhook_url -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($json_payload)) -ContentType "application/json; charset=utf-8"
    Write-Host "`n[+] Scan successfully completed! Data sent to Discord." -ForegroundColor Green
} catch {
    Write-Host "`n[-] Critical error sending data to Discord." -ForegroundColor Red
}
