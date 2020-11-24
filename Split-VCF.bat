@echo off
rem Execute the PS1 file with the same name as this batch file.
set filename="%~d0%~p0%~n0.ps1"
if exist "%filename%" (
  echo "running: %filename% with PowerShell.exe"
  PowerShell.exe -executionpolicy bypass -file "%filename%"
  rem Collect the exit code from the PowerShell script.
  set err=%errorlevel%
) else (
  echo "File: %filename% not found"
  rem Set our exit code.
  set err=1
)
echo "... finished"
rem Pause if we need to.
if [%1] neq [/nopause] pause
rem Exit and pass along our exit code.
exit /B %err%
