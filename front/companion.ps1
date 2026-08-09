# ==============================================================================
# Screen Controller Companion Script for Windows
# This script monitors the display state and minimizes/maximizes the browser window.
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

# 2. Base domain name (determines current URL dynamically)
$url = "https://st-philopateer-screens.fly.dev/api/timer/state"
$lastState = ""

Clear-Host
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "     St-Philopateer Screens Companion Script" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Cyan

# Check if local server is running on port 7860
try {
    $localTest = Invoke-RestMethod -Uri "http://localhost:7860/api/timer/state" -Method Get -TimeoutSec 2 -ErrorAction SilentlyContinue
    if ($localTest) {
        $url = "http://localhost:7860/api/timer/state"
        Write-Host "Detected local server running on port 7860." -ForegroundColor Green
    }
} catch {
    # Fallback to the default URL
}

Write-Host "Target URL: $url" -ForegroundColor DarkGray
Write-Host "Monitoring state change... Press Ctrl+C to exit." -ForegroundColor White
Write-Host "======================================================" -ForegroundColor Cyan

while ($true) {
    try {
        $response = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 5
        if ($response.active) {
            $currentState = $response.state
            if ($currentState -ne $lastState) {
                $lastState = $currentState
                
                # Find all windows containing "Display-Screen"
                $hwnds = [WindowHelper]::FindWindowsByTitle("Display-Screen")
                
                if ($hwnds -and $hwnds.Count -gt 0) {
                    foreach ($hwnd in $hwnds) {
                        if ($currentState -eq "minimize") {
                            Write-Host "$(Get-Date -Format 'HH:mm:ss') | State: MINIMIZE -> Minimizing browser window ($hwnd)..." -ForegroundColor Yellow
                            [WindowHelper]::ShowWindowAsync($hwnd, 6) # SW_MINIMIZE (minimizes the window)
                        } else {
                            Write-Host "$(Get-Date -Format 'HH:mm:ss') | State: MAXIMIZE -> Restoring and Maximizing ($hwnd)..." -ForegroundColor Green
                            [WindowHelper]::ShowWindowAsync($hwnd, 3) # SW_SHOWMAXIMIZED (maximizes the window)
                            [WindowHelper]::SetForegroundWindow($hwnd)
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
                        [WindowHelper]::ShowWindowAsync($hwnd, 3)
                        [WindowHelper]::SetForegroundWindow($hwnd)
                    }
                }
            }
        }
    } catch {
        Write-Host "$(Get-Date -Format 'HH:mm:ss') | Error connecting to server: $_" -ForegroundColor Red
    }
    Start-Sleep -Seconds 2
}
