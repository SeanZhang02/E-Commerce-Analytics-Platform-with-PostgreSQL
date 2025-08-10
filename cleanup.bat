@echo off
echo =====================================
echo E-Commerce Analytics Database Cleanup
echo =====================================

set PSQL="C:\Program Files\PostgreSQL\17\bin\psql"
set DB=ecommerce_analytics

echo.
echo WARNING: This will completely remove the existing database and all data!
echo.
set /p confirm="Are you sure you want to proceed? (y/N): "
if /i not "%confirm%"=="y" (
    echo Cleanup cancelled.
    pause
    exit /b 0
)

echo.
echo Dropping existing database...
%PSQL% -U postgres -c "DROP DATABASE IF EXISTS %DB%;"

if %errorlevel% equ 0 (
    echo.
    echo =====================================
    echo Database cleanup completed successfully!
    echo =====================================
    echo.
    echo You can now run setup.bat to create a fresh installation.
) else (
    echo.
    echo ERROR: Failed to drop database. Make sure no connections are active.
    echo Try closing all psql connections and run this script again.
)

echo.
pause