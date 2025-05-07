# Windows Update Controller
# Version 1.0

$devName = "HelpTech"

function Get-UpdateStatus {
    $wuService = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
    $status = if ($wuService.Status -eq 'Running') { "ENABLED" } else { "DISABLED" }
    return $status
}

function Show-Banner {
    Clear-Host
    $currentStatus = Get-UpdateStatus
    $statusColor = if ($currentStatus -eq "ENABLED") { "Red" } else { "Green" }
    
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "     WINDOWS UPDATE CONTROLLER" -ForegroundColor Green
    Write-Host "           Developed by $devName" -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host " Current Status: $currentStatus" -ForegroundColor $statusColor
    Write-Host "=========================================`n" -ForegroundColor Cyan
}

function Show-Menu {
    $currentStatus = Get-UpdateStatus
    
    if ($currentStatus -eq "ENABLED") {
        Write-Host "1. DISABLE Windows Updates" -ForegroundColor Red
    } else {
        Write-Host "1. ENABLE Windows Updates" -ForegroundColor Green
    }
    
    Write-Host "2. Refresh Status"
    Write-Host "3. EXIT`n"
    
    $choice = Read-Host "Please select an option (1-3)"
    return $choice
}

function Set-ServiceStatus {
    param ($name, $status)
    try {
        if ($status -eq "disable") {
            Write-Host "Disabling service: $name"
            Stop-Service -Name $name -Force -ErrorAction SilentlyContinue
            Set-Service -Name $name -StartupType Disabled -ErrorAction SilentlyContinue
            if ($?) { Write-Host "Successfully disabled $name" -ForegroundColor Green }
            else { Write-Warning "Failed to disable $name" }
        } elseif ($status -eq "enable") {
            Write-Host "Enabling service: $name"
            Set-Service -Name $name -StartupType Manual -ErrorAction SilentlyContinue
            Start-Service -Name $name -ErrorAction SilentlyContinue
            if ($?) { Write-Host "Successfully enabled $name" -ForegroundColor Green }
            else { Write-Warning "Failed to enable $name" }
        }
    } catch {
        Write-Warning "Error configuring service ${name}: $_"
    }
}

function Set-TaskStatus {
    param ($task, $status)
    try {
        # Check if task exists first
        $taskExists = schtasks /Query /TN $task 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            if ($status -eq "disable") {
                Write-Host "Disabling task: $task"
                schtasks /Change /TN $task /Disable | Out-Null
                if ($LASTEXITCODE -eq 0) { Write-Host "Successfully disabled $task" -ForegroundColor Green }
                else { Write-Warning "Failed to disable $task" }
            } elseif ($status -eq "enable") {
                Write-Host "Enabling task: $task"
                schtasks /Change /TN $task /Enable | Out-Null
                if ($LASTEXITCODE -eq 0) { Write-Host "Successfully enabled $task" -ForegroundColor Green }
                else { Write-Warning "Failed to enable $task" }
            }
        } else {
            Write-Host "Task not found: $task" -ForegroundColor Yellow
        }
    } catch {
        Write-Warning "Error configuring task ${task}: $_"
    }
}

function Toggle-WindowsUpdate {
    $currentStatus = Get-UpdateStatus
    
    if ($currentStatus -eq "ENABLED") {
        Write-Host "`nDisabling Windows Updates..." -ForegroundColor Yellow
        # Disable logic
        Set-ServiceStatus -name "wuauserv" -status "disable"
        Set-ServiceStatus -name "bits" -status "disable"
        Set-ServiceStatus -name "UsoSvc" -status "disable"
        Set-ServiceStatus -name "DoSvc" -status "disable"
        
        $tasks = @(
            "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan",
            "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker",
            "\Microsoft\Windows\WindowsUpdate\Scheduled Start"
        )
        foreach ($task in $tasks) {
            Set-TaskStatus -task $task -status "disable"
        }
        
        Write-Host "`nWindows Updates have been DISABLED" -ForegroundColor Red
    } else {
        Write-Host "`nEnabling Windows Updates..." -ForegroundColor Yellow
        # Enable logic
        Set-ServiceStatus -name "wuauserv" -status "enable"
        Set-ServiceStatus -name "bits" -status "enable"
        Set-ServiceStatus -name "UsoSvc" -status "enable"
        Set-ServiceStatus -name "DoSvc" -status "enable"
        
        $tasks = @(
            "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan",
            "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker",
            "\Microsoft\Windows\WindowsUpdate\Scheduled Start"
        )
        foreach ($task in $tasks) {
            Set-TaskStatus -task $task -status "enable"
        }
        
        Write-Host "`nWindows Updates have been ENABLED" -ForegroundColor Green
    }
    
    Read-Host "`nPress ENTER to continue..."
}

# Main program loop
while ($true) {
    Show-Banner
    $choice = Show-Menu
    
    switch ($choice) {
        "1" { Toggle-WindowsUpdate }
        "2" { continue }  # Just refreshes
        "3" { exit }
        default { Write-Host "Invalid option. Please try again." -ForegroundColor Red }
    }
}
