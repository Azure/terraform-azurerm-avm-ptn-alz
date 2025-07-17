@echo off
SETLOCAL EnableDelayedExpansion

REM Check if this is the original script or a forked copy
IF NOT DEFINED AVM_FORKED (
    REM Create a temporary directory and file
    SET TEMP_DIR="%TEMP%\avm_temp_%RANDOM%"
    MKDIR !TEMP_DIR! 2>NUL
    SET TEMP_FILE=!TEMP_DIR!\avm_%RANDOM%.bat

    REM Copy the current script to the temporary file
    COPY "avm.bat" !TEMP_FILE! >NUL

    REM Execute the temporary file with AVM_FORKED=1 and all original arguments
    SET AVM_FORKED=1
    CALL !TEMP_FILE! %*
    SET EXIT_CODE=%ERRORLEVEL%

    REM Clean up
    DEL /Q !TEMP_FILE! 2>NUL
    RMDIR /Q !TEMP_DIR! 2>NUL

    EXIT /B !EXIT_CODE!
)

REM Set CONTAINER_RUNTIME to its current value if it's already set, or docker if it's not
IF DEFINED CONTAINER_RUNTIME (SET "CONTAINER_RUNTIME=%CONTAINER_RUNTIME%") ELSE (SET "CONTAINER_RUNTIME=docker")

REM Check if CONTAINER_RUNTIME is installed
WHERE /Q %CONTAINER_RUNTIME%
IF ERRORLEVEL 1 (
    echo Error: %CONTAINER_RUNTIME% is not installed. Please install %CONTAINER_RUNTIME% first.
    exit /b
)

IF DEFINED AVM_IMAGE (SET "AVM_IMAGE=%AVM_IMAGE%") ELSE (SET "AVM_IMAGE=mcr.microsoft.com/azterraform")

REM Check if a make target is provided
IF "%~1"=="" (
    echo Error: Please provide a make target. See https://github.com/Azure/tfmod-scaffold/blob/main/avmmakefile for available targets.
    exit /b
)

IF DEFINED NO_PULL (
    SET "PULL_ARG="
) ELSE (
    SET "PULL_ARG=--pull always"
)

REM Run the make target with CONTAINER_RUNTIME
%CONTAINER_RUNTIME% run %PULL_ARG% --rm -v "%cd%":/src -w /src --user "1000:1000" -e GITHUB_TOKEN -e ARM_SUBSCRIPTION_ID -e ARM_TENANT_ID -e ARM_CLIENT_ID -e GITHUB_REPOSITORY -e GITHUB_REPOSITORY_OWNER %AVM_IMAGE% make %1

ENDLOCAL
