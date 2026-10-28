# ====================================================================
#   FAST MINECRAFT CHECKER PRO (EVERYTHING CLI + ADVANCED REGEX SCAN)
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

# Шаблоны нечёткого поиска (Regex) для поиска скрытых аимов, триггеров и ботов
$fuzzy_patterns = @(
    "aim.*bot",   # ловит aimbot, aim_bot, aim-bot, aimbbot
    "bot.*aim",   # ловит botaim, bot_aim, bot-aim
    "killaura",   # киллаура
    "trigger",    # триггербот
    "hitbox",     # хитбоксы
    "aura",       # ауры
    "velocity",   # анти-откидывание
    "flyhack"     # флайхак
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
        
        # Проверка по точным словам
        foreach ($keyword in $full_cheat_keywords) {
            if ($proc.Name.ToLower().Contains($keyword)) { $is_suspicious_proc = $true }
        }
        # Проверка по регулярным шаблонам (нечёткий поиск)
        foreach ($pattern in $fuzzy_patterns) {
            if ($proc.Name.ToLower() -match $pattern) { $is_suspicious_proc = $true }
        }
        
        if ($is_suspicious_proc) {
            $detected_items += "Zapushenny process (CHEAT): $($proc.Name) (ID: $($proc.Id))"
        }
        if ($is_suspicious_proc -or $proc.Path -match "Temp|AppData\\Local\\Temp") {
            $suspicious_processes += "$($proc.Name) (ID: $($proc.Id))"
        }
    }
}

# 4. Поиск файлов через Everything CLI + Сквозной и Нечёткий анализ
Write-Host "[*] Configuring fast search engine..." -ForegroundColor Cyan
$es_path = "$env:TEMP\es.exe"

[Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null

if (-not (Test-Path $es_path)) {
    try {
        Invoke-WebRequest -Uri "https://voidtools.com" -OutFile $es_path -ErrorAction SilentlyContinue
    } catch {
        Write-Host "[-] Failed to load fast search engine." -ForegroundColor Yellow
    }
}

if (Test-Path $es_path) {
    Write-Host "[*] Executing deep scan via Everything..." -ForegroundColor Cyan
    
    # Запрос ищет файлы, содержащие базовые слова, а также любые совпадения с аимами/ботами
    $search_terms = ($base_keywords + @("aim", "bot", "aura", "hitbox", "cheat")) | ForEach-Object { "*$_*" }
    $search_query = "ext:jar;dll;exe;zip;rar !c:\windows\ " + ($search_terms -join " | ")
    
    try {
        $es_results = &$es_path -search $search_query -max-results 100 2>$null
        if ($es_results) {
            foreach ($file_path in $es_results) {
                if ($file_path -and (Test-Path $file_path)) {
                    $file_obj = Get-Item $file_path -ErrorAction SilentlyContinue
                    if ($file_obj) {
                        $is_hit = $false
                        $name_lower = $file_obj.Name.ToLower()
                        
                        # 1. Проверяем имя файла на точные ключевые слова
                        foreach ($keyword in $full_cheat_keywords) {
                            if ($name_lower.Contains($keyword)) {
                                $is_hit = $true
                                $detected_items += "Fail na diske: $($file_obj.FullName)"
                            }
                        }
                        # 2. Нечёткая проверка имени файла (Regex)
                        if (!$is_hit) {
                            foreach ($pattern in $fuzzy_patterns) {
                                if ($name_lower -match $pattern) {
                                    $is_hit = $true
                                    $detected_items += "Podozritelny fail (Fuzzy): $($file_obj.FullName)"
                                }
                            }
                        }
                        
                        # 3. Сквозной анализ архивов и JAR-ников
                        if (($file_obj.Extension -eq ".jar" -or $file_obj.Extension -eq ".zip") -and !$is_hit) {
                            try {
                                $archive = [System.IO.Compression.ZipFile]::OpenRead($file_obj.FullName)
                                foreach ($entry in $archive.Entries) {
                                    $entry_lower = $entry.Name.ToLower()
                                    $is_entry_hit = $false
                                    
                                    # Ищем точные совпадения внутри JAR
                                    foreach ($keyword in $full_cheat_keywords) {
                                        if ($entry_lower.Contains($keyword)) {
                                            $is_entry_hit = $true
                                            $detected_items += "Vnutri JAR [$($file_obj.Name)]: $($entry.FullName)"
                                        }
                                    }
                                    # Ищем нечёткие совпадения (aimbot/botaim) внутри JAR
                                    if (!$is_entry_hit) {
                                        foreach ($pattern in $fuzzy_patterns) {
                                            if ($entry_lower -match $pattern) {
                                                $detected_items += "Fuzzy vnutri JAR [$($file_obj.Name)]: $($entry.FullName)"
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
        }
    } catch {
        Write-Host "[-] Everything service error." -ForegroundColor Red
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

