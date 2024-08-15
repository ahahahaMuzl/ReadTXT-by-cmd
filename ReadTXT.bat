@echo off

if "%~1" == "" (
	PowerShell -ExecutionPolicy RemoteSigned -File "%~dp0FunctionMain.ps1" "%~dp0book.txt" "%~dp0bookmark"
) else (
	PowerShell -ExecutionPolicy RemoteSigned -File "%~dp0FunctionMain.ps1" "%~1" "%~dp0bookmark"
)
