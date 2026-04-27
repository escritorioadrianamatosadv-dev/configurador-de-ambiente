@echo off
setlocal EnableDelayedExpansion
title Escritorio Adriana Matos - Configurador v5.0
color 0A

:: ============================================================
:: Escritorio Adriana Matos - Configurador v5.0
:: Este bat prepara o ambiente e chama o setup.py principal.
::
:: FLUXO:
::   [1] Localiza Python instalado (ignora o stub do WindowsApps)
::   [2] Atualiza pip
::   [3] Instala dependencias Python necessarias
::   [4] Baixa o setup.py mais recente do Gist
::   [5] Executa o setup.py
::   [6] Limpa arquivos temporarios
::   [7] Exibe popup de encerramento proprio do bat
::
:: PORTABILIDADE MAC (futuro):
::   - Substituir por script .sh
::   - Python: usar python3/pip3
::   - Sem WindowsApps stub — python3 --version direto
::   - Sem taskkill — usar pkill
::   - PowerShell popup -> osascript -e 'display dialog "..."'
:: ============================================================
echo ============================================================
echo    Escritorio Adriana Matos - Configurador v5.0
echo    NAO feche esta janela durante o processo!
echo ============================================================
echo.

:: ════════════════════════════════════════════════════════════
:: ETAPA [1/6] — LOCALIZAR PYTHON REAL (ignora WindowsApps)
:: O Windows instala um stub "python.exe" em WindowsApps que abre
:: a Store em vez de rodar Python de verdade. Por isso testamos os
:: caminhos reais do instalador oficial primeiro.
:: ════════════════════════════════════════════════════════════
echo [1/6] Localizando Python...

set "PY="

:: Testa Python 3.12 instalado pelo usuario em AppData\Local
if exist "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" (
    set "PY=%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
    echo       Encontrado em Programs\Python312.
    goto :validar_python
)
:: Testa Python 3.11
if exist "%LOCALAPPDATA%\Programs\Python\Python311\python.exe" (
    set "PY=%LOCALAPPDATA%\Programs\Python\Python311\python.exe"
    echo       Encontrado em Programs\Python311.
    goto :validar_python
)
:: Testa Python 3.10
if exist "%LOCALAPPDATA%\Programs\Python\Python310\python.exe" (
    set "PY=%LOCALAPPDATA%\Programs\Python\Python310\python.exe"
    echo       Encontrado em Programs\Python310.
    goto :validar_python
)

:: Varre o PATH mas ignora qualquer caminho com "WindowsApps"
:: (o stub da Microsoft nao tem pip e nao funciona para nossos fins)
for /f "delims=" %%P in ('where python 2^>nul') do (
    echo %%P | findstr /i "WindowsApps" >nul
    if errorlevel 1 (
        if "!PY!"=="" (
            set "PY=%%P"
            echo       Encontrado no PATH: %%P
        )
    )
)

:: Se nao achou nada, baixa e instala Python 3.12.4 automaticamente
if "!PY!"=="" goto :instalar_python

:validar_python
:: Verifica se o Python encontrado funciona e tem pip
"!PY!" --version >nul 2>&1
if errorlevel 1 goto :instalar_python
"!PY!" -m pip --version >nul 2>&1
if errorlevel 1 goto :instalar_python
echo       Python OK: & "!PY!" --version
goto :instalar_deps

:instalar_python
:: Download silencioso do instalador oficial do Python 3.12.4
:: /quiet = sem janela de UI, InstallAllUsers=0 = so para o usuario atual
echo.
echo       Baixando Python 3.12.4 (aguarde)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.12.4/python-3.12.4-amd64.exe' -OutFile ([System.IO.Path]::Combine($env:TEMP,'adriana_python.exe')) -UseBasicParsing"
if errorlevel 1 (echo       ERRO: Falha ao baixar Python. & goto :erro_fatal)
echo       Instalando Python...
"%TEMP%\adriana_python.exe" /quiet InstallAllUsers=0 PrependPath=1 Include_test=0 Include_launcher=1
if errorlevel 1 (echo       ERRO: Falha ao instalar Python. & goto :erro_fatal)
set "PATH=%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts;%PATH%"
set "PY=%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
echo       Python instalado OK.

:: ════════════════════════════════════════════════════════════
:: ETAPA [2/6] — ATUALIZAR PIP
:: pip e o gerenciador de pacotes do Python
:: ════════════════════════════════════════════════════════════
:instalar_deps
echo.
echo [2/6] Atualizando pip...
"!PY!" -m pip install --upgrade pip --quiet
echo       pip OK.

:: ════════════════════════════════════════════════════════════
:: ETAPA [3/6] — INSTALAR DEPENDENCIAS PYTHON
:: selenium + webdriver-manager: controla Chrome via codigo
:: pyautogui + pillow + opencv: automacao mouse/teclado e visao
:: websocket-client + pyperclip: comunicacao e clipboard
:: ════════════════════════════════════════════════════════════
echo.
echo [3/6] Instalando dependencias...

"!PY!" -m pip install --quiet --no-cache-dir selenium webdriver-manager
if errorlevel 1 (echo       ERRO selenium/wdm. & goto :erro_fatal)
echo       selenium + webdriver-manager OK.

:: pyautogui/opencv: nao fatal — setup.py tem fallback sem visao computacional
"!PY!" -m pip install --quiet --no-cache-dir pyautogui pillow opencv-python-headless
if errorlevel 1 (echo       AVISO: pyautogui/opencv falhou - continuando sem visao computacional.)
echo       pyautogui + opencv OK.

"!PY!" -m pip install --quiet --no-cache-dir websocket-client pyperclip
if errorlevel 1 (echo       AVISO: websocket/pyperclip falhou.)
echo       websocket-client + pyperclip OK.

:: ════════════════════════════════════════════════════════════
:: ETAPA [4/6] — BAIXAR SETUP.PY DO GIST
:: Sempre baixa a versao mais recente — garante que o Gist atualizado
:: seja o que roda, nao uma copia antiga em cache.
:: Verifica tamanho minimo de 1000 bytes para detectar download corrompido.
:: ════════════════════════════════════════════════════════════
echo.
echo [4/6] Baixando configurador principal...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://gist.githubusercontent.com/escritorioadrianamatosadv-dev/8879ce890471381e21e1d484bfb6ebcc/raw/setup.py' -OutFile ([System.IO.Path]::Combine($env:TEMP,'adriana_setup.py')) -UseBasicParsing"
if errorlevel 1 (echo       ERRO: Falha ao baixar configurador. & goto :erro_fatal)

for %%F in ("%TEMP%\adriana_setup.py") do set "SZ=%%~zF"
if !SZ! LSS 1000 (echo       ERRO: setup.py corrompido. & goto :erro_fatal)
echo       Configurador baixado (!SZ! bytes).

:: ════════════════════════════════════════════════════════════
:: ETAPA [5/6] — EXECUTAR O CONFIGURADOR
:: Roda o setup.py e captura o codigo de saida em ERR.
:: ERR=0 = sucesso (setup.py chamou sys.exit(0) apos popup final)
:: ERR!=0 = alguma etapa falhou internamente
:: ════════════════════════════════════════════════════════════
echo.
echo [5/6] Iniciando configuracao...
echo ============================================================
echo.
"!PY!" "%TEMP%\adriana_setup.py"
set "ERR=!errorlevel!"

:: ════════════════════════════════════════════════════════════
:: ETAPA [6/6] — LIMPEZA DE TEMPORARIOS
:: Remove instalador Python e setup.py baixados nesta sessao
:: ════════════════════════════════════════════════════════════
echo.
echo [6/6] Limpando temporarios...
if exist "%TEMP%\adriana_python.exe"   del /f /q "%TEMP%\adriana_python.exe"   >nul 2>&1
if exist "%TEMP%\adriana_setup.py"     del /f /q "%TEMP%\adriana_setup.py"     >nul 2>&1

:: Se o setup.py retornou erro, vai para bloco de erro
if !ERR! neq 0 goto :erro_fatal

:: ════════════════════════════════════════════════════════════
:: SUCESSO — Popup proprio do bat
:: O setup.py ja mostrou o popup "Concluido!" e saiu com sys.exit(0).
:: Este popup aparece logo em seguida, encerrando o bat por completo.
:: MAC futuro: osascript -e 'display dialog "Configurador encerrado!" buttons {"OK"}'
:: ════════════════════════════════════════════════════════════
echo.
echo ============================================================
echo    Configuracao concluida com sucesso!
echo ============================================================

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Add-Type -AssemblyName System.Windows.Forms; ^
   [System.Windows.Forms.MessageBox]::Show( ^
     'Configurador encerrado com sucesso!' + [char]10 + 'Todas as etapas foram concluidas.', ^
     'Escritorio Adriana Matos', ^
     [System.Windows.Forms.MessageBoxButtons]::OK, ^
     [System.Windows.Forms.MessageBoxIcon]::Information ^
   )" >nul 2>&1

goto :fim

:: ════════════════════════════════════════════════════════════
:: ERRO FATAL — exibe mensagem e aguarda o usuario ler (pause)
:: ════════════════════════════════════════════════════════════
:erro_fatal
echo.
echo ============================================================
echo    ERRO: Processo interrompido.
echo    Tire foto desta tela e envie ao suporte.
echo ============================================================

:fim
echo.
pause
endlocal
