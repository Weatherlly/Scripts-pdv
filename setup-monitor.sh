#!/bin/bash

# Cores para o terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # Sem cor

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}    INSTALADOR AUTOMÁTICO - MONITOR PDV    ${NC}"
echo -e "${BLUE}==========================================${NC}"

show_menu() {
    echo -e "\n${GREEN}Selecione uma opção:${NC}"
    echo "1) Instalar tudo automaticamente (Recomendado)"
    echo "2) Instalar dependências e Liberar Firewall"
    echo "3) Criar e configurar o Agente Python (Corrigido)"
    echo "4) Configurar e Ativar o Serviço Systemd"
    echo "q) Sair"
    echo -ne "\nOpção: "
}

install_dependencies() {
    echo -e "\n${BLUE}[1/4] Instalando dependências e configurando Firewall...${NC}"
    sudo apt update
    sudo apt install -y python3 python3-pip
    
    # Instalação das libs Python
    sudo pip3 install flask flask-cors psutil --break-system-packages || sudo pip3 install flask flask-cors psutil
    
    # Liberação do Firewall
    if command -v ufw > /dev/null; then
        sudo ufw allow 5000/tcp
        echo -e "${GREEN}Porta 5000 liberada no UFW.${NC}"
    fi
}

create_agent() {
    echo -e "\n${BLUE}[2/4] Criando o agente em /usr/local/bin/agente_monitor.py...${NC}"
    
    cat <<EOF | sudo tee /usr/local/bin/agente_monitor.py > /dev/null
#!/usr/bin/env python3
from flask import Flask, jsonify
from flask_cors import CORS
import psutil
import socket
import os
import platform
import subprocess

app = Flask(__name__)
CORS(app)

def get_cpu_info():
    try:
        if platform.system() == "Linux":
            command = "cat /proc/cpuinfo | grep 'model name' | uniq | cut -d':' -f2"
            res = subprocess.check_output(command, shell=True).decode().strip()
            return res if res else platform.processor()
        return platform.processor()
    except:
        return "Processador Genérico"

def get_cpu_temp():
    try:
        temps = psutil.sensors_temperatures()
        if 'coretemp' in temps:
            return temps['coretemp'][0].current
        elif 'cpu_thermal' in temps:
            return temps['cpu_thermal'][0].current
        return 0
    except:
        return 0

@app.route('/status')
def get_status():
    try:
        load1, _, _ = os.getloadavg()
    except:
        load1 = 0
    
    mem = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    
    return jsonify({
        "hostname": socket.gethostname(),
        "cpu_percent": psutil.cpu_percent(interval=0.1),
        "cpu_temp": get_cpu_temp(),
        "memory_percent": mem.percent,
        "disk_percent": disk.percent,
        "load_avg": round(load1, 2),
        "uptime_days": int((psutil.time.time() - psutil.boot_time()) / 86400),
        "status": "Online",
        "hardware": {
            "cpu_model": get_cpu_info(),
            "cpu_cores": psutil.cpu_count(logical=False),
            "ram_total": f"{round(mem.total / (1024**3), 2)} GB",
            "disk_total": f"{round(disk.total / (1024**3), 2)} GB",
            "so": f"{platform.system()} {platform.release()}"
        }
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

    sudo chmod +x /usr/local/bin/agente_monitor.py
    echo -e "${GREEN}Agente criado com sucesso!${NC}"
}

setup_service() {
    echo -e "\n${BLUE}[3/4] Configurando o serviço Systemd...${NC}"
    
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

    sudo systemctl daemon-reload
    sudo systemctl enable monitor-pdv
    sudo systemctl restart monitor-pdv
    
    echo -e "${GREEN}Serviço ativado e rodando!${NC}"
}

# Loop principal do menu
while true; do
    show_menu
    read opt
    case $opt in
        1)
            install_dependencies
            create_agent
            setup_service
            echo -e "\n${GREEN}>>> INSTALAÇÃO COMPLETA FINALIZADA! <<<${NC}"
            break
            ;;
        2) install_dependencies ;;
        3) create_agent ;;
        4) setup_service ;;
        q) exit ;;
        *) echo -e "${RED}Opção inválida!${NC}" ;;
    esac
done
