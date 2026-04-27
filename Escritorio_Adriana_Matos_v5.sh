#!/usr/bin/env bash
# ============================================================
# Escritorio Adriana Matos - Configurador v5.0 (macOS)
# Traduzido do Escritorio_Adriana_Matos_v5.bat
#
# FLUXO:
#   [1] Localiza Python3 instalado
#   [2] Atualiza pip
#   [3] Instala dependencias Python necessarias
#   [4] Baixa o setup_mac.py mais recente do Gist
#   [5] Executa o setup_mac.py
#   [6] Limpa arquivos temporarios
#   [7] Exibe popup de encerramento
# ============================================================

set -euo pipefail

echo "============================================================"
echo "   Escritorio Adriana Matos - Configurador v5.0 (macOS)"
echo "   NAO feche este terminal durante o processo!"
echo "============================================================"
echo ""

# ════════════════════════════════════════════════════════════
# ETAPA [1/6] — LOCALIZAR PYTHON3
# No Mac nao existe stub WindowsApps. python3 e o comando certo.
# Testamos brew, depois /usr/local, depois o que vier no PATH.
# ════════════════════════════════════════════════════════════
echo "[1/6] Localizando Python..."

PY=""

# Homebrew Apple Silicon
if [ -x "/opt/homebrew/bin/python3" ]; then
    PY="/opt/homebrew/bin/python3"
    echo "      Encontrado em /opt/homebrew (Apple Silicon)."
# Homebrew Intel
elif [ -x "/usr/local/bin/python3" ]; then
    PY="/usr/local/bin/python3"
    echo "      Encontrado em /usr/local (Intel)."
# python.org installer (gera /usr/local/bin/python3.12 etc.)
elif [ -x "/usr/local/bin/python3.12" ]; then
    PY="/usr/local/bin/python3.12"
    echo "      Encontrado python3.12 em /usr/local."
elif [ -x "/usr/local/bin/python3.11" ]; then
    PY="/usr/local/bin/python3.11"
    echo "      Encontrado python3.11 em /usr/local."
# Qualquer python3 no PATH
elif command -v python3 &>/dev/null; then
    PY="$(command -v python3)"
    echo "      Encontrado no PATH: $PY"
fi

# Valida: precisa funcionar e ter pip
if [ -n "$PY" ]; then
    "$PY" --version &>/dev/null || PY=""
fi
if [ -n "$PY" ]; then
    "$PY" -m pip --version &>/dev/null || PY=""
fi

if [ -z "$PY" ]; then
    # ── Instala Python via Homebrew se disponivel
    if command -v brew &>/dev/null; then
        echo "      Instalando Python via Homebrew..."
        brew install python@3.12
        PY="$(brew --prefix)/bin/python3.12"
    else
        echo ""
        echo "      ERRO: Python nao encontrado e Homebrew nao disponivel."
        echo "      Instale Python em https://python.org/downloads/macos"
        echo "      Ou instale Homebrew em https://brew.sh e rode novamente."
        _erro_fatal
    fi
fi

echo "      Python OK: $("$PY" --version)"

# ════════════════════════════════════════════════════════════
# ETAPA [2/6] — ATUALIZAR PIP
# ════════════════════════════════════════════════════════════
echo ""
echo "[2/6] Atualizando pip..."
"$PY" -m pip install --upgrade pip --quiet
echo "      pip OK."

# ════════════════════════════════════════════════════════════
# ETAPA [3/6] — INSTALAR DEPENDENCIAS PYTHON
# --break-system-packages: necessario no macOS 13+ com Python
# do sistema (evita erro "externally managed environment").
# Para Python do Homebrew ou python.org isso e ignorado sem dano.
# ════════════════════════════════════════════════════════════
echo ""
echo "[3/6] Instalando dependencias..."

pip_install() {
    "$PY" -m pip install --quiet --no-cache-dir --break-system-packages "$@"
}

if pip_install selenium webdriver-manager; then
    echo "      selenium + webdriver-manager OK."
else
    echo "      ERRO: falha ao instalar selenium/webdriver-manager."
    _erro_fatal
fi

# pyautogui no Mac requer 'pyobjc-framework-Quartz' para captura de tela
if pip_install pyautogui pillow opencv-python-headless pyobjc-framework-Quartz 2>/dev/null; then
    echo "      pyautogui + opencv + pyobjc OK."
else
    echo "      AVISO: pyautogui/opencv falhou - continuando sem visao computacional."
fi

if pip_install websocket-client pyperclip 2>/dev/null; then
    echo "      websocket-client + pyperclip OK."
else
    echo "      AVISO: websocket/pyperclip falhou."
fi

# ════════════════════════════════════════════════════════════
# ETAPA [4/6] — BAIXAR SETUP_MAC.PY DO GIST
# curl substitui Invoke-WebRequest do PowerShell.
# -fsSL: fail silently, sem progress, segue redirects.
# ════════════════════════════════════════════════════════════
echo ""
echo "[4/6] Baixando configurador principal..."

SETUP_TMP="$TMPDIR/adriana_setup_mac.py"

# IMPORTANTE: troque esta URL pelo Gist do setup_mac.py quando publicar
GIST_URL="https://gist.githubusercontent.com/escritorioadrianamatosadv-dev/5795318d6a3596b5404bd33f143cbb5e/raw/23113d43ca12b9ce076fdbce51d02ff7f81a54c3/setup_mac.py"

if ! curl -fsSL "$GIST_URL" -o "$SETUP_TMP"; then
    echo "      ERRO: Falha ao baixar configurador."
    _erro_fatal
fi

SZ=$(wc -c < "$SETUP_TMP" | tr -d ' ')
if [ "$SZ" -lt 1000 ]; then
    echo "      ERRO: setup_mac.py corrompido ($SZ bytes)."
    _erro_fatal
fi
echo "      Configurador baixado ($SZ bytes)."

# ════════════════════════════════════════════════════════════
# ETAPA [5/6] — EXECUTAR O CONFIGURADOR
# ════════════════════════════════════════════════════════════
echo ""
echo "[5/6] Iniciando configuracao..."
echo "============================================================"
echo ""

"$PY" "$SETUP_TMP"
ERR=$?

# ════════════════════════════════════════════════════════════
# ETAPA [6/6] — LIMPEZA
# ════════════════════════════════════════════════════════════
echo ""
echo "[6/6] Limpando temporarios..."
[ -f "$SETUP_TMP" ] && rm -f "$SETUP_TMP"

if [ "$ERR" -ne 0 ]; then
    _erro_fatal
fi

# ════════════════════════════════════════════════════════════
# SUCESSO — popup via osascript (equivalente ao MessageBox do .bat)
# ════════════════════════════════════════════════════════════
echo ""
echo "============================================================"
echo "   Configuracao concluida com sucesso!"
echo "============================================================"

osascript -e 'display dialog "Configurador encerrado com sucesso!\nTodas as etapas foram concluidas." buttons {"OK"} default button "OK" with icon note with title "Escritorio Adriana Matos"' &>/dev/null || true

exit 0

# ════════════════════════════════════════════════════════════
# ERRO FATAL
# ════════════════════════════════════════════════════════════
_erro_fatal() {
    echo ""
    echo "============================================================"
    echo "   ERRO: Processo interrompido."
    echo "   Tire foto desta tela e envie ao suporte."
    echo "============================================================"
    read -rp "Pressione ENTER para sair..."
    exit 1
}
