# ====================================================================
#      FAST MINECRAFT CHECKER PRO (EVERYTHING CLI OPTIMIZED)
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

# Авто-генерация мутаций (добавление суффиксов dlc, crack, leak, src, legit, client)
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

# 3. Анализ запущенных и фоновых процессов (Фильтр системного софта)
$white_list_processes = @("explorer", "svchost", "lsass", "csrss", "smss", "wininit", "winlogon", "services", "spoolsv", 
                          "taskhostw", "runtimebroker", "ctfmon", "conhost", "chrome", "opera", "discord", "steam", 
                          "yandex", "firefox", "telegram", "anydesk", "rustdesk", "nvidia", "amd", "realtek", "intel", 
                          "audiodg", "shellexperiencehost", "searchhost", "startmenuexperiencehost", "powershell", "cmd")

$processes = Get-Process | Select-Object Name, Id, Path -ErrorAction SilentlyContinue
foreach ($proc in $processes) {
    if ($proc.Name -and ($white_list_processes -notcontains $proc.Name.ToLower())) {
        $is_suspicious_proc = $false
        foreach ($keyword in $full_cheat_keywords) {
            if ($proc.Name.ToLower().Contains($keyword)) {
                $is_suspicious_proc = $true
                $detected_items += "Zapushenny process: $($proc.Name) (ID: $($proc.Id))"
            }
        }
        if ($is_suspicious_proc -or $proc.Path -match "Temp|AppData\\Local\\Temp") {
            $suspicious_processes += "$($proc.Name) (ID: $($proc.Id))"
        }
    }
}

# 4. Сверхбыстрый поиск файлов через Everything CLI
Write-Host "[*] Configuring fast search engine..." -ForegroundColor Cyan
$es_path = "$env:TEMP\es.exe"

# Скачиваем официальную CLI-утилиту es.exe в Temp, если её там нет
if (-not (Test-Path $es_path)) {
# Скачиваем официальную CLI-утилиту es.exe в Temp, если её там нет
if (-not (Test-Path $es_path)) {
    try {
        Invoke-WebRequest -Uri "https://voidtools.com" -OutFile $es_path -ErrorAction SilentlyContinue
    } catch {
        Write-Host "[-] Failed to load fast search engine. Swapped to fallback mode." -ForegroundColor Yellow
    }
}
    Write-Host "[*] Executing total PC scan via Everything (1-2 seconds)..." -ForegroundColor Cyan
    
    # Формируем один общий поисковый запрос для Everything
    # Запрос ищет файлы jar, dll, exe, zip, rar, содержащие ключевые слова, исключая системную папку Windows
    $search_query = "ext:jar;dll;exe;zip;rar !c:\windows\ " + (($base_keywords | ForEach-Object { "*$_*" }) -join " | ")
    
    try {
        # Запуск es.exe с передачей поискового запроса
        $es_results = &$es_path -search $search_query -max-results 100 2>$null
        if ($es_results) {
            foreach ($file_path in $es_results) {
                if ($file_path -and (Test-Path $file_path)) {
                    $file_obj = Get-Item $file_path -ErrorAction SilentlyContinue
                    if ($file_obj) {
                        $detected_items += "Fail: $($file_obj.FullName) (Izm: $($file_obj.LastWriteTime))"
                    }
                }
            }
        }
    } catch {
        Write-Host "[-] Everything service is not running or not installed." -ForegroundColor Red
    }
} else {
    # Запасной фоллбэк: если Everything не запущен или нет интернета, быстро проверяем только mods и недавние файлы
    $mods_path = "$env:APPDATA\.minecraft\mods"
    if (Test-Path $mods_path) {
        $files = Get-ChildItem -Path $mods_path -Include "*.jar","*.dll" -File -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            foreach ($keyword in $full_cheat_keywords) {
                if ($file.Name.ToLower().Contains($keyword)) {
                    $detected_items += "Fallback (mods): $($file.FullName)"
                }
            }
        }
    }
}

# 5. Итоговый вердикт и форматирование списков
$unique_detections = $detected_items | Select-Object -Unique
if ($unique_detections.Count -gt 0) {
    $verdict = "[!] VNIMANIE! NAIDENY CHITY ILI SLEDY SVOFTA! [!]`n"
    foreach ($item in $unique_detections) { $verdict += "- $item`n" }
} else {
    $verdict = "Chitov ili sledov ih udaleniya ne obnaruzheno."
}

$proc_output = if ($suspicious_processes) { ($suspicious_processes | Select-Object -First 15) -join "`n" } else { "Podozritelnyh processov ne naideno." }

# 6. Отправка Embed-карточки в Discord
$embed = @{
    title = "OTCHET O PROVERKE PK (Everything CLI Optimized)"
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
