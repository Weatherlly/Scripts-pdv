#!/bin/bash

# Detecta o usuário padrão (caso rode como root)
DEFAULT_USER=$(logname 2>/dev/null || whoami)

function passo1_instalar_ssh() {
    echo "==> Instalando openssh-server..."
    sudo apt update
    sudo apt install -y openssh-server
}

function passo2_testar_ssh_temporario() {
    echo "==> Iniciando SSH temporariamente..."
    sudo systemctl start ssh
}

function passo3_ativar_service() {
    echo "==> Habilitando e iniciando o serviço SSH permanentemente..."
    sudo systemctl enable ssh
    sudo systemctl start ssh
}

function passo4_status_service() {
    echo "==> Verificando status do serviço SSH..."
    sudo systemctl status ssh --no-pager
}

function passo5_reiniciar_service() {
    echo "==> Reiniciando serviço SSH..."
    sudo systemctl restart ssh
}

function passo6_stop_service() {
    echo "==> Parando serviço SSH..."
    sudo systemctl stop ssh
}

function passo7_kill_process() {
    echo "==> Finalizando processos SSH (sshd)..."
    sudo pkill -f sshd
}

function passo8_config_basic() {
    echo "==> Configurações básicas de segurança SSH (desabilitar root login)..."
    sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sudo systemctl restart ssh
    echo "Configurações aplicadas. Edite /etc/ssh/sshd_config para mais ajustes."
}

while true; do
    echo ""
    echo "=== Menu de Instalação SSH (OpenSSH) ==="
    echo "1 - Instalar openssh-server"
    echo "2 - Iniciar SSH temporariamente"
    echo "3 - Ativar e iniciar serviço permanentemente"
    echo "4 - Ver status do serviço"
    echo "5 - Reiniciar serviço"
    echo "6 - Parar serviço"
    echo "7 - Matar processos SSH"
    echo "8 - Configurações básicas de segurança"
    echo "0 - Sair"
    echo "========================================"
    read -p "Digite o número do passo: " opt

    if [[ "$opt" == "0" ]]; then
        echo "Saindo..."
        break
    fi

    if [[ -z "$USERNAME" ]]; then
        read -p "Informe o nome do usuário (opcional para SSH): " USERNAME
        USERNAME=${USERNAME:-$DEFAULT_USER}
    fi

    case $opt in
        1) passo1_instalar_ssh ;;
        2) passo2_testar_ssh_temporario ;;
        3) passo3_ativar_service ;;
        4) passo4_status_service ;;
        5) passo5_reiniciar_service ;;
        6) passo6_stop_service ;;
        7) passo7_kill_process ;;
        8) passo8_config_basic ;;
        *) echo "Opção inválida!" ;;
    esac
    echo ""
    read -p "Pressione Enter para continuar..."
done
