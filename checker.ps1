# ====================================================================
#          ULTRA MINECRAFT CHECKER PRO (JAR, EXE, ARCHIVES & DLL)
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
                $detected_items += "Запущенный процесс: $($proc.Name) (ID: $($proc.Id))"
            }
        }
        if ($is_suspicious_proc -or $proc.Path -match "Temp|AppData\\Local\\Temp") {
            $suspicious_processes += "$($proc.Name) (ID: $($proc.Id))"
        }
    }
}

# 4. Тотальный поиск по ВСЕМ дискам ПК (Добавлены .dll)
$disks = Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root
$target_extensions = @("*.jar", "*.exe", "*.zip", "*.rar", "*.dll")

[Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null

foreach ($disk in $disks) {
    $files = Get-ChildItem -Path $disk -Include $target_extensions -Recurse -File -ErrorAction SilentlyContinue | 
             Where-Object { $_.FullName -notmatch "C:\\Windows" -and $_.FullName -notmatch "Program Files" }

    foreach ($file in $files) {
        $file_name_lower = $file.Name.ToLower()
        $is_hit = $false
        
        foreach ($keyword in $full_cheat_keywords) {
            if ($file_name_lower.Contains($keyword)) {
                $is_hit = $true
                $detected_items += "Файл на диске ($($file.Extension)): $($file.FullName) (Изм: $($file.LastWriteTime))"
            }
        }
        
        if ($file.Extension -eq ".zip" -and !$is_hit) {
            try {
                $zip = [System.IO.Compression.ZipFile]::OpenRead($file.FullName)
                foreach ($entry in $zip.Entries) {
                    foreach ($keyword in $full_cheat_keywords) {
                        if ($entry.Name.ToLower().Contains($keyword)) {
                            $detected_items += "Внутри архива [$($file.Name)]: $($entry.FullName)"
                        }
                    }
                }
                $zip.Dispose()
            } catch {}
        }
    }
}

# 5. Итоговый вердикт и форматирование списков
$unique_detections = $detected_items | Select-Object -Unique
if ($unique_detections.Count -gt 0) {
    $verdict = "🚨 **ОБНАРУЖЕНЫ ЧИТЫ, DLL ИЛИ СЛЕДЫ СТОРОННЕГО СОФТА!** 🚨`n"
    foreach ($item in $unique_detections) { $verdict += "🔴 $item`n" }
} else {
    $verdict = "✅ **Запрещенного софта, DLL или подозрительных совпадений не найдено.**"
}

$proc_output = if ($suspicious_processes) { ($suspicious_processes | Select-Object -First 15) -join "`n" } else { "Подозрительных процессов не найдено." }

# 6. Отправка Embed-карточки в твой Discord
$embed = @{
    title = "🕵️‍♂️ ТОТАЛЬНЫЙ ДОСМОТР ПК ИГРОКА (Error Checker PRO + DLL)"
    color = if ($unique_detections.Count -gt 0) { 16711680 } else { 65280 }
    fields = @(
        @{ name = "💻 Пользователь ПК"; value = "`\`\`$pc_user`\`\`"; inline = $true },
        @{ name = "🌐 Сеть / Провайдер"; value = "`\`\`$network_name`\`\`"; inline = $true },
        @{ name = "⚖️ Вердикт сканирования"; value = $verdict; inline = $false },
        @{ name = "⚙️ Активные несистемные процессы (Топ-15)"; value = "`\`\`\``n" + $proc_output + "`\`\`\`"; inline = $false }
    )
}

$json_payload = [PSCustomObject]@{ embeds = @($embed) } | ConvertTo-Json -Depth 5

try {
    Invoke-RestMethod -Uri $webhook_url -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($json_payload)) -ContentType "application/json; charset=utf-8"
    Write-Host "`n[+] Сканирование успешно завершено! Все данные улетели в Discord." -ForegroundColor Green
} catch {
    Write-Host "`n[-] Критическая ошибка отправки данных в Discord." -ForegroundColor Red
}
