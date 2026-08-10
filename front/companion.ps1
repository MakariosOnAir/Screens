# ==============================================================================
# Screen Controller Companion Script for Windows
# This script monitors the timer state from Supabase and minimizes/maximizes
# the browser window accordingly.
# ==============================================================================

# 1. Compile User32.dll window controls and enumeration in memory if not already loaded
if ($null -eq ("WindowHelper" -as [type])) {
    Add-Type @"
    using System;
    using System.Collections.Generic;
    using System.Runtime.InteropServices;
    using System.Text;

    public class WindowHelper {
        [DllImport("user32.dll")]
        public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
        
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);

        [DllImport("user32.dll")]
        private static extern bool EnumWindows(EnumCallBackDelegate lpMethod, IntPtr lParam);

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        private static extern int GetWindowText(IntPtr hWnd, StringBuilder strText, int maxCount);

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        private static extern int GetWindowTextLength(IntPtr hWnd);

        private delegate bool EnumCallBackDelegate(IntPtr hwnd, IntPtr lParam);

        public static IntPtr[] FindWindowsByTitle(string substring) {
            List<IntPtr> result = new List<IntPtr>();
            EnumWindows(new EnumCallBackDelegate((hwnd, lParam) => {
                int length = GetWindowTextLength(hwnd);
                if (length > 0) {
                    StringBuilder sb = new StringBuilder(length + 1);
                    GetWindowText(hwnd, sb, sb.Capacity);
                    string title = sb.ToString();
                    if (title.IndexOf(substring, StringComparison.OrdinalIgnoreCase) >= 0) {
                        result.Add(hwnd);
                    }
                }
                return true;
            }), IntPtr.Zero);
            return result.ToArray();
        }
    }
"@
}

# 2. Supabase configuration
$supabaseUrl = "https://zabocfwhfqntmumiahlt.supabase.co"
$supabaseKey = "sb_publishable_aD0xKcUmcwKfaSS1_Vnmfg_W3ExePcE"
$apiUrl = "$supabaseUrl/rest/v1/timer_state?id=eq.1&select=*"
$headers = @{
    "apikey" = $supabaseKey
    "Authorization" = "Bearer $supabaseKey"
}
$lastState = ""

Clear-Host
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "     St-Philopateer Screens Companion Script" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "Data Source: Supabase" -ForegroundColor DarkGray
Write-Host "Monitoring state change... Press Ctrl+C to exit." -ForegroundColor White
Write-Host "======================================================" -ForegroundColor Cyan

while ($true) {
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers $headers -TimeoutSec 5
        $timerData = $response[0]

        if ($timerData.active -and $timerData.startTime) {
            # Calculate current state from timer data
            $maxMs = [long]$timerData.maxMins * 60 * 1000
            $minMs = [long]$timerData.minMins * 60 * 1000
            $totalCycleMs = $maxMs + $minMs
            $nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
            $elapsed = ($nowMs - [long]$timerData.startTime) % $totalCycleMs
            
            if ($elapsed -lt $maxMs) {
                $currentState = "maximize"
            } else {
                $currentState = "minimize"
            }

            if ($currentState -ne $lastState) {
                $lastState = $currentState
                
                # Find all windows containing "Display-Screen"
                $hwnds = [WindowHelper]::FindWindowsByTitle("Display-Screen")
                
                if ($hwnds -and $hwnds.Count -gt 0) {
                    foreach ($hwnd in $hwnds) {
                        if ($currentState -eq "minimize") {
                            Write-Host "$(Get-Date -Format 'HH:mm:ss') | State: MINIMIZE -> Minimizing browser window ($hwnd)..." -ForegroundColor Yellow
                            [void][WindowHelper]::ShowWindowAsync($hwnd, 6)
                        } else {
                            Write-Host "$(Get-Date -Format 'HH:mm:ss') | State: MAXIMIZE -> Restoring and Maximizing ($hwnd)..." -ForegroundColor Green
                            [void][WindowHelper]::ShowWindowAsync($hwnd, 3)
                            [void][WindowHelper]::SetForegroundWindow($hwnd)
                        }
                    }
                } else {
                    Write-Host "$(Get-Date -Format 'HH:mm:ss') | Warning: Window with title '*Display-Screen*' not found." -ForegroundColor DarkYellow
                }
            }
        } else {
            # Timer is inactive, ensure window is restored/maximized
            if ($lastState -ne "inactive") {
                $lastState = "inactive"
                Write-Host "$(Get-Date -Format 'HH:mm:ss') | Timer is INACTIVE. Restoring window..." -ForegroundColor Gray
                
                $hwnds = [WindowHelper]::FindWindowsByTitle("Display-Screen")
                if ($hwnds -and $hwnds.Count -gt 0) {
                    foreach ($hwnd in $hwnds) {
                        [void][WindowHelper]::ShowWindowAsync($hwnd, 3)
                        [void][WindowHelper]::SetForegroundWindow($hwnd)
                    }
                }
            }
        }
    } catch {
        Write-Host "$(Get-Date -Format 'HH:mm:ss') | Error connecting to Supabase: $_" -ForegroundColor Red
    }
    Start-Sleep -Seconds 2
}
