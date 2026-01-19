#!/bin/bash

# Detecta o usuário padrão (caso rode como root)
DEFAULT_USER=$(logname)

function passo1_instalar_x11vnc() {
    echo "==> Instalando x11vnc..."
    sudo apt update
    sudo apt install -y x11vnc
}

function passo2_criar_senha() {
    echo "==> Criando senha do VNC..."
    sudo -u "$USERNAME" x11vnc -storepasswd
}

function passo3_testar_vnc_temporario() {
    echo "==> Rodando x11vnc temporariamente (use ctrl+C para sair)..."
    x11vnc -usepw
}

function passo4_rodar_em_bg() {
    echo "==> Rodando x11vnc em segundo plano..."
    x11vnc -usepw -forever -bg
}

function passo5_criar_service_file() {
    echo "==> Criando arquivo de serviço systemd..."

    SERVICE_FILE="/etc/systemd/system/x11vnc.service"

    sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=Start x11vnc at boot
After=display-manager.service

[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -auth guess -forever -loop -noxdamage -repeat -rfbauth /home/$USERNAME/.vnc/passwd -rfbport 5900 -shared
User=$USERNAME
Group=$USERNAME

[Install]
WantedBy=graphical.target
EOF

    echo "Arquivo criado em $SERVICE_FILE"
}

function passo6_ativar_service() {
    echo "==> Habilitando e iniciando o serviço..."
    sudo systemctl daemon-reload
    sudo systemctl enable x11vnc.service
    sudo systemctl start x11vnc.service
}

function passo7_status_service() {
    echo "==> Verificando status do serviço..."
    sudo systemctl status x11vnc.service
}

function passo8_reiniciar_service() {
    echo "==> Reiniciando serviço x11vnc..."
    sudo systemctl restart x11vnc.service
}

function passo9_kill_process() {
    echo "==> Finalizando qualquer processo x11vnc..."
    sudo killall x11vnc
}

while true; do
    echo ""
    echo "=== Menu de Instalação x11vnc ==="
    echo "1 - Instalar x11vnc"
    echo "2 - Criar senha VNC"
    echo "3 - Testar x11vnc temporariamente"
    echo "4 - Rodar x11vnc em segundo plano"
    echo "5 - Criar arquivo de serviço systemd"
    echo "6 - Ativar e iniciar serviço"
    echo "7 - Ver status do serviço"
    echo "8 - Reiniciar serviço"
    echo "9 - Matar processo x11vnc"
    echo "0 - Sair"
    echo "================================="
    read -p "Digite o número do passo: " opt

    if [[ "$opt" == "0" ]]; then
        echo "Saindo..."
        break
    fi

    if [[ -z "$USERNAME" ]]; then
        read -p "Informe o nome do usuário que usa a sessão gráfica [padrão: $DEFAULT_USER]: " USERNAME
        USERNAME=${USERNAME:-$DEFAULT_USER}
    fi

    case $opt in
        1) passo1_instalar_x11vnc ;;
        2) passo2_criar_senha ;;
        3) passo3_testar_vnc_temporario ;;
        4) passo4_rodar_em_bg ;;
        5) passo5_criar_service_file ;;
        6) passo6_ativar_service ;;
        7) passo7_status_service ;;
        8) passo8_reiniciar_service ;;
        9) passo9_kill_process ;;
        *) echo "Opção inválida" ;;
    esac
done
