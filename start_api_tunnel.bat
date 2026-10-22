@echo off
title Khoi Chay Web API & Cloudflare Tunnel
echo ======================================================================
echo    KHOI CHAY HE THONG WEB API & PUBLIC LINK CLOUDFLARE TUNNEL
echo ======================================================================
echo.
echo [1/2] Dang khoi chay ASP.NET Core Web API...
start "Backend Web API" dotnet run --project "%~dp0backend_api\nguyenhuutri\nguyenhuutri.csproj"

echo [2/2] Dang thiet lap duong truyen Public HTTPS (Cloudflare Tunnel)...
timeout /t 4 /nobreak >nul
"%~dp0tools\cloudflared.exe" tunnel --url http://localhost:5184
pause
