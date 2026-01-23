#!/bin/bash

function passo1_espaco_disco() {
    echo "==> Espaço em disco:"
    df -h
}

function passo2_display_manager() {
    echo "==> Gerenciador de display:"
    cat /etc/X11/default-display-manager
    systemctl status display-manager 2>/dev/null || echo "Nenhum ativo"
}

function passo3_restart_lightdm() {
    echo "==> Reiniciando LightDM..."
    sudo systemctl restart lightdm
}

function passo4_restart_sddm() {
    echo "==> Reiniciando SDDM..."
    sudo systemctl restart sddm
}

function passo5_maiores_arquivos() {
    echo "==> 20 maiores arquivos/pastas:"
    sudo du -ahx / 2>/dev/null | sort -rh | head -20
}

function passo6_limpar_xsession() {
    echo "==> Limpando .xsession-errors (logs gráficos)..."
    USUARIOS=$(ls /home)
    for user in $USUARIOS; do
        sudo truncate -s 0 "/home/$user/.xsession-errors" 2>/dev/null
        echo "Limpou /home/$user/.xsession-errors"
    done
    df -h
}

function passo7_voltar_grafico() {
    echo "==> Voltando ao modo gráfico (Ctrl+Alt+F1/F2)..."
    echo "Pressione Ctrl+D ou execute: startx"
}

while true; do
    echo ""
    echo "=== RESCUE PDV - Tela Preta (TTY) ==="
    echo "1 - Ver espaço em disco (df -h)"
    echo "2 - Identificar display manager"
    echo "3 - Reiniciar LightDM"
    echo "4 - Reiniciar SDDM [memory:3]"
    echo "5 - Maiores arquivos (du top 20)"
    echo "6 - Limpar logs .xsession-errors"
    echo "7 - Dicas voltar gráfico"
    echo "0 - Sair"
    echo "====================================="
    read -p "Opção: " opt

    case $opt in
        1) passo1_espaco_disco ;;
        2) passo2_display_manager ;;
        3) passo3_restart_lightdm ;;
        4) passo4_restart_sddm ;;
        5) passo5_maiores_arquivos ;;
        6) passo6_limpar_xsession ;;
        7) passo7_voltar_grafico ;;
        0) echo "Saindo..."; break ;;
        *) echo "Opção inválida!" ;;
    esac
    echo ""
    read -p "Enter para continuar..."
done
