#!/bin/bash

# Cores para o terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Detecta o usuário padrão
DEFAULT_USER=$(logname 2>/dev/null || whoami)

# ==========================================
# SUBMENU 1 - MONITOR PDV (PYTHON AGENT)
# ==========================================
menu_monitor_pdv() {
    while true; do
        echo -e "\n${BLUE}--- SUBMENU MONITOR PDV ---${NC}"
        echo "1 - Instalar tudo automaticamente (Recomendado)"
        echo "2 - Instalar dependências e Liberar Firewall (Porta 5000)"
        echo "3 - Criar e configurar o Agente Python"
        echo "4 - Configurar e Ativar o Serviço Systemd"
        echo "0 - Voltar"
        read -p "Opção: " o_mon

        case $o_mon in
            1)
                instalar_deps_monitor
                criar_agente_python
                ativar_servico_monitor
                echo -e "${GREEN}>>> MONITOR PDV INSTALADO COM SUCESSO!${NC}" ;;
            2) instalar_deps_monitor ;;
            3) criar_agente_python ;;
            4) ativar_servico_monitor ;;
            0) break ;;
        esac
    done
}

instalar_deps_monitor() {
    echo -e "\n${BLUE}==> Instalando dependências...${NC}"
    sudo apt update && sudo apt install -y python3 python3-pip
    sudo pip3 install flask flask-cors psutil --break-system-packages || sudo pip3 install flask flask-cors psutil
    if command -v ufw > /dev/null; then sudo ufw allow 5000/tcp; fi
}

criar_agente_python() {
    echo -e "\n${BLUE}==> Criando agente em /usr/local/bin/agente_monitor.py...${NC}"
    cat <<EOF | sudo tee /usr/local/bin/agente_monitor.py > /dev/null
#!/usr/bin/env python3
from flask import Flask, jsonify
from flask_cors import CORS
import psutil, socket, os, platform, subprocess
app = Flask(__name__)
CORS(app)
def get_cpu_info():
    try:
        res = subprocess.check_output("cat /proc/cpuinfo | grep 'model name' | uniq | cut -d':' -f2", shell=True).decode().strip()
        return res if res else platform.processor()
    except: return "Processador Genérico"
@app.route('/status')
def get_status():
    mem = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    return jsonify({
        "hostname": socket.gethostname(),
        "cpu_percent": psutil.cpu_percent(interval=0.1),
        "memory_percent": mem.percent,
        "disk_percent": disk.percent,
        "status": "Online",
        "hardware": {"cpu_model": get_cpu_info(), "ram_total": f"{round(mem.total / (1024**3), 2)} GB"}
    })
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF
    sudo chmod +x /usr/local/bin/agente_monitor.py
}

ativar_servico_monitor() {
    echo -e "\n${BLUE}==> Ativando serviço Systemd...${NC}"
    cat <<EOF | sudo tee /etc/systemd/system/monitor-pdv.service > /dev/null
[Unit]
Description=Agente de Monitoramento de PDV
After=network.target
[Service]
ExecStart=/usr/bin/python3 /usr/local/bin/agente_monitor.py
Restart=always
User=root
[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload && sudo systemctl enable monitor-pdv --now
}

# ==========================================
# SUBMENU 2 - SSH
# ==========================================
menu_ssh() {
    while true; do
        echo -e "\n${BLUE}--- SUBMENU SSH ---${NC}"
        echo "1 - Instalar, Ativar e Iniciar SSH"
        echo "2 - Ver Status"
        echo "3 - Reiniciar Serviço"
        echo "0 - Voltar"
        read -p "Opção: " o_ssh
        case $o_ssh in
            1)
                sudo apt update && sudo apt install -y openssh-server
                sudo systemctl enable ssh --now
                echo -e "${GREEN}SSH Ativo.${NC}" ;;
            2) sudo systemctl status ssh --no-pager ;;
            3) sudo systemctl restart ssh ;;
            0) break ;;
        esac
    done
}

# ==========================================
# SUBMENU 3 - VNC (X11VNC)
# ==========================================
menu_vnc() {
    while true; do
        echo -e "\n${BLUE}--- SUBMENU VNC ---${NC}"
        echo "1 - Instalação Completa (Senha 102030 + Service)"
        echo "2 - Reiniciar Serviço"
        echo "3 - Matar Processos x11vnc"
        echo "0 - Voltar"
        read -p "Opção: " o_vnc
        case $o_vnc in
            1)
                sudo apt update && sudo apt install -y x11vnc
                sudo -u "$DEFAULT_USER" mkdir -p "/home/$DEFAULT_USER/.vnc"
                sudo x11vnc -storepasswd "102030" "/home/$DEFAULT_USER/.vnc/passwd"
                sudo chown "$DEFAULT_USER:$DEFAULT_USER" "/home/$DEFAULT_USER/.vnc/passwd"
                
                cat <<EOF | sudo tee /etc/systemd/system/x11vnc.service > /dev/null
[Unit]
Description=x11vnc service
After=display-manager.service
[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -auth guess -forever -loop -noxdamage -repeat -rfbauth /home/$DEFAULT_USER/.vnc/passwd -rfbport 5900 -shared
User=$DEFAULT_USER
Restart=on-failure
[Install]
WantedBy=graphical.target
EOF
                sudo systemctl daemon-reload && sudo systemctl enable x11vnc.service --now
                echo -e "${GREEN}VNC Configurado (Senha: 102030)${NC}" ;;
            2) sudo systemctl restart x11vnc.service ;;
            3) sudo killall x11vnc ;;
            0) break ;;
        esac
    done
}

# ==========================================
# SUBMENU 4 - RESCUE (LIMPEZA TTY)
# ==========================================
menu_rescue() {
    while true; do
        echo -e "\n${RED}--- SUBMENU RESCUE PDV ---${NC}"
        echo "1 - Checkup e Travar Logs (df -h + du + chattr)"
        echo "2 - Identificar Display Manager"
        echo "3 - Reiniciar Interface Gráfica"
        echo "0 - Voltar"
        read -p "Opção: " o_res
        case $o_res in
            1)
                df -h
                sudo du -ahx / 2>/dev/null | sort -rh | head -20
                for u in $(ls /home); do
                    sudo chattr -i "/home/$u/.xsession-errors" 2>/dev/null
                    sudo truncate -s 0 "/home/$u/.xsession-errors" 2>/dev/null
                    sudo chattr +i "/home/$u/.xsession-errors" 2>/dev/null
                done
                echo -e "${GREEN}Limpeza concluída e logs travados.${NC}" ;;
            2) cat /etc/X11/default-display-manager; systemctl status display-manager --no-pager ;;
            3) sudo systemctl restart lightdm || sudo systemctl restart sddm ;;
            0) break ;;
        esac
    done
}

# ==========================================
# LOOP PRINCIPAL
# ==========================================
while true; do
    echo -e "\n${BLUE}==========================================${NC}"
    echo -e "${BLUE}        TOOLKIT PDV - MENU PRINCIPAL      ${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo "1) MONITOR PDV (Menu de Instalação)"
    echo "2) SSH (Menu de Gestão)"
    echo "3) VNC (Menu de Gestão)"
    echo "4) RESCUE (Manutenção e Limpeza)"
    echo "0) Sair"
    echo -e "${BLUE}==========================================${NC}"
    read -p "Opção Geral: " opt

    case $opt in
        1) menu_monitor_pdv ;;
        2) menu_ssh ;;
        3) menu_vnc ;;
        4) menu_rescue ;;
        0) echo "Saindo..."; exit 0 ;;
        *) echo -e "${RED}Opção Inválida!${NC}" ;;
    esac
done