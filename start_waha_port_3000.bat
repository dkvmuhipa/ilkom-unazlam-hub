@echo off
title ILKOM UNAZLAM - WhatsApp Gateway (Port 3000)
color 0A
cls
echo =============================================================
echo   ILKOM UNAZLAM HUB - WHATSAPP GATEWAY (PORT 3000)
echo =============================================================
echo.
echo Menjalankan WhatsApp Gateway di port 3000...
echo Jangan tutup jendela ini agar gateway tetap aktif melayani
echo pesan pengumuman dan kas dari aplikasi Flutter.
echo.
cd /d "%~dp0waha_gateway"
node server.js
pause
