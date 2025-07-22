# Функция для проверки прав администратора
function Test-IsAdmin {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Проверяем, запущен ли скрипт с правами администратора
if (-not (Test-IsAdmin)) {
    Write-Host "Скрипт не запущен с правами администратора. Перезапускаем с повышенными правами..."
    
    # Получаем полный путь к текущему скрипту
    $scriptPath = $MyInvocation.MyCommand.Definition
    
    # Запускаем скрипт с повышенными правами
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
    exit
}

# Основной код скрипта начинается здесь
$anyDeskExecutable = "C:\Program Files (x86)\AnyDesk\AnyDesk.exe"

# 1. Убиваем все процессы AnyDesk через диспетчер задач
Write-Host "Завершаем все процессы AnyDesk..."
Stop-Process -Name "AnyDesk" -Force -ErrorAction SilentlyContinue

# 2. Удаляем все содержимое папки C:\ProgramData\AnyDesk
$programDataPath = "C:\ProgramData\AnyDesk"
if (Test-Path $programDataPath) {
    Write-Host "Удаляем содержимое папки $programDataPath..."
    Remove-Item -Path "$programDataPath\*" -Recurse -Force
} else {
    Write-Host "Папка $programDataPath не найдена."
}

# 3. Сохраняем файл user.conf в папку %localappdata%\temp
$appDataPath = "$env:APPDATA\AnyDesk"
$userConfPath = "$appDataPath\user.conf"
$tempPath = "$env:LOCALAPPDATA\Temp"
$backupUserConfPath = "$tempPath\user.conf"

if (Test-Path $userConfPath) {
    Write-Host "Сохраняем файл user.conf в папку $tempPath..."
    Copy-Item -Path $userConfPath -Destination $backupUserConfPath -Force
} else {
    Write-Host "Файл user.conf не найден в папке $appDataPath."
}

# 4. Удаляем все файлы из папки %appdata%\anydesk
if (Test-Path $appDataPath) {
    Write-Host "Удаляем все файлы из папки $appDataPath..."
    Remove-Item -Path "$appDataPath\*" -Recurse -Force
} else {
    Write-Host "Папка $appDataPath не найдена."
}

# 5. Запускаем новый AnyDesk и закрываем его (для инициализации)
if (Test-Path $anyDeskExecutable) {
    Write-Host "Запускаем AnyDesk для инициализации..."
    $process = Start-Process -FilePath $anyDeskExecutable -PassThru
    Start-Sleep -Seconds 7
    Stop-Process -InputObject $process -Force -ErrorAction SilentlyContinue
    Write-Host "AnyDesk инициализирован и закрыт."
} else {
    Write-Host "AnyDesk не найден по пути $anyDeskExecutable."
}

# 6. Возвращаем файл user.conf на место
if (Test-Path $backupUserConfPath) {
    Write-Host "Восстанавливаем файл user.conf из резервной копии..."
    Copy-Item -Path $backupUserConfPath -Destination $userConfPath -Force
    Write-Host "Файл user.conf успешно восстановлен."
	Start-Sleep -Seconds 5
} else {
    Write-Host "Резервная копия файла user.conf не найдена."
}

# 7. Запускаем AnyDesk для работы (ФИНАЛЬНЫЙ ЗАПУСК)
if (Test-Path $anyDeskExecutable) {
    Write-Host "Запускаем AnyDesk для работы..."
    Start-Process -FilePath $anyDeskExecutable
    Write-Host "AnyDesk успешно запущен для работы."
} else {
    Write-Host "AnyDesk не найден по пути $anyDeskExecutable. Финальный запуск невозможен."
}

Write-Host "Операция завершена."