#!/bin/bash

# ==========================================
# PARROT OS - HERRAMIENTA DE DIAGNOSTICO
# ==========================================

set -u

# Comprobar que se ejecuta en Bash
if [ -z "${BASH_VERSION:-}" ]; then
    echo "Error: ejecuta este script con Bash."
    exit 1
fi

# Colores
VERDE='\033[0;32m'
ROJO='\033[0;31m'
AMARILLO='\033[1;33m'
AZUL='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Sin color

# Limpiar pantalla si es posible
clear 2>/dev/null || true

echo -e "${CYAN}==================================${NC}"
echo -e "${CYAN}       PARROT OS - BASH TOOL     ${NC}"
echo -e "${CYAN}==================================${NC}"
echo

# Informacion del sistema
if [ -r /etc/os-release ]; then
    . /etc/os-release
    echo -e "${AZUL}Sistema:${NC} ${PRETTY_NAME:-Desconocido}"
fi

echo -e "${AZUL}Usuario:${NC} $(whoami)"
echo -e "${AZUL}Hostname:${NC} $(hostname)"
echo -e "${AZUL}Kernel:${NC}  $(uname -r)"
echo -e "${AZUL}Fecha:${NC}   $(date '+%d/%m/%Y %H:%M:%S')"
echo

# Funcion para pausar y volver al menu
pausar() {
    echo
    read -r -p "Pulsa Enter para volver al menu..."
    clear 2>/dev/null || true
}

# Menu principal
while true; do
    echo -e "${CYAN}==================================${NC}"
    echo -e "${CYAN}             MENU               ${NC}"
    echo -e "${CYAN}==================================${NC}"
    echo -e "${VERDE}1)${NC} Ver informacion de red"
    echo -e "${VERDE}2)${NC} Comprobar conexion a Internet"
    echo -e "${VERDE}3)${NC} Ver uso de memoria RAM"
    echo -e "${VERDE}4)${NC} Ver espacio en disco"
    echo -e "${VERDE}5)${NC} Buscar herramientas de seguridad"
    echo -e "${VERDE}6)${NC} Actualizar lista de paquetes"
    echo -e "${VERDE}7)${NC} Actualizar paquetes instalados"
    echo -e "${AZUL}8)${NC} Ver tiempo encendido y carga del sistema"
    echo -e "${AZUL}9)${NC} Ver puertos abiertos y servicios escuchando"
    echo -e "${AZUL}10)${NC} Ver IP pública"
    echo -e "${AZUL}11)${NC} Comprobar si hay VPN activa"
    echo -e "${AZUL}12)${NC} Ver estado del firewall"
    echo -e "${AZUL}13)${NC} Ver usuarios conectados / últimos accesos"
    echo -e "${AZUL}14)${NC} Ver temperatura y info de CPU"
    echo -e "${AMARILLO}15)${NC} Limpieza de paquetes (autoremove + autoclean)"
    echo -e "${AMARILLO}16)${NC} Generar informe completo de diagnóstico"
    echo -e "${ROJO}0)${NC} Salir"
    echo -e "${CYAN}==================================${NC}"

    read -r -p "Selecciona una opcion: " opcion

    case "$opcion" in

        1)
            echo
            echo -e "${CYAN}========== INFORMACION DE RED ==========${NC}"

            if command -v ip >/dev/null 2>&1; then
                echo
                echo -e "${AZUL}--- Interfaces de red ---${NC}"
                ip -brief address

                echo
                echo -e "${AZUL}--- Tabla de rutas ---${NC}"
                ip route
            else
                echo -e "${ROJO}[ERROR]${NC} No se encuentra el comando ip."
            fi
            ;;

        2)
            echo
            echo -e "${CYAN}========== CONEXION A INTERNET ==========${NC}"

            if ! command -v ping >/dev/null 2>&1; then
                echo -e "${AMARILLO}[AVISO]${NC} No se encuentra el comando ping."
            elif ping -c 3 -W 2 1.1.1.1 >/dev/null 2>&1; then
                echo -e "${VERDE}[OK]${NC} Conexion IP disponible (1.1.1.1 responde)."
            else
                echo -e "${ROJO}[ERROR]${NC} Sin respuesta de 1.1.1.1."
                echo "Puede ser un problema de red o bloqueo ICMP."
            fi

            echo

            if ! command -v getent >/dev/null 2>&1; then
                echo -e "${AMARILLO}[AVISO]${NC} No se encuentra el comando getent."
            elif getent hosts deb.parrot.sh >/dev/null 2>&1; then
                echo -e "${VERDE}[OK]${NC} Resolucion DNS funcional (deb.parrot.sh)."
            else
                echo -e "${AMARILLO}[AVISO]${NC} No se pudo resolver deb.parrot.sh."
            fi
            ;;

        3)
            echo
            echo -e "${CYAN}========== MEMORIA RAM ==========${NC}"

            if command -v free >/dev/null 2>&1; then
                free -h
            else
                echo -e "${ROJO}[ERROR]${NC} No se encuentra el comando free."
            fi
            ;;

        4)
            echo
            echo -e "${CYAN}========== ESPACIO EN DISCO ==========${NC}"

            if command -v df >/dev/null 2>&1; then
                df -hT | grep -v tmpfs | grep -v overlay
            else
                echo -e "${ROJO}[ERROR]${NC} No se encuentra el comando df."
            fi
            ;;

        5)
            echo
            echo -e "${CYAN}========== HERRAMIENTAS DE SEGURIDAD ==========${NC}"

            for herramienta in nmap curl git python3 sqlmap hydra nikto ffuf gobuster masscan netcat socat; do
                if command -v "$herramienta" >/dev/null 2>&1; then
                    echo -e "${VERDE}[INSTALADA]${NC} $herramienta"
                else
                    echo -e "${ROJO}[NO INSTALADA]${NC} $herramienta"
                fi
            done
            ;;

        6)
            echo
            echo -e "${CYAN}==================================${NC}"
            echo -e "${CYAN} ACTUALIZANDO LISTAS DE PAQUETES${NC}"
            echo -e "${CYAN}==================================${NC}"
            echo

            if ! command -v apt-get >/dev/null 2>&1; then
                echo -e "${ROJO}[ERROR]${NC} No se encuentra apt-get."
            elif sudo apt-get update; then
                echo
                echo -e "${VERDE}[OK]${NC} Listas de paquetes actualizadas."
                echo
                echo "Para ver los paquetes actualizables:"
                echo "apt list --upgradable 2>/dev/null"
            else
                echo
                echo -e "${ROJO}[ERROR]${NC} No se pudieron actualizar las listas."
                echo "Revisa tu conexion y los repositorios."
            fi
            ;;

        7)
            echo
            echo -e "${CYAN}==================================${NC}"
            echo -e "${CYAN} ACTUALIZANDO PAQUETES INSTALADOS${NC}"
            echo -e "${CYAN}==================================${NC}"
            echo
            echo -e "${AMARILLO}Se comprobaran las actualizaciones disponibles.${NC}"
            echo -e "${AMARILLO}Revisa los cambios antes de confirmarlos.${NC}"
            echo

            if ! command -v apt-get >/dev/null 2>&1; then
                echo -e "${ROJO}[ERROR]${NC} No se encuentra apt-get."
            elif sudo apt-get upgrade; then
                echo
                echo -e "${VERDE}[OK]${NC} Proceso de actualizacion finalizado."
            else
                echo
                echo -e "${ROJO}[ERROR]${NC} La actualizacion fallo o fue interrumpida."
            fi
            ;;

        8)
            echo
            echo -e "${CYAN}========== UPTIME Y CARGA ==========${NC}"
            uptime
            echo
            echo -e "${AZUL}Carga media (1, 5, 15 min):${NC} $(cut -d' ' -f1-3 /proc/loadavg)"
            ;;

        9)
            echo
            echo -e "${CYAN}========== PUERTOS ESCUCHANDO ==========${NC}"
            if command -v ss >/dev/null 2>&1; then
                echo -e "${AZUL}Usando: ss${NC}"
                ss -Htanup 2>/dev/null || ss -tulnp
            elif command -v netstat >/dev/null 2>&1; then
                echo -e "${AZUL}Usando: netstat${NC}"
                sudo netstat -tulnp 2>/dev/null || netstat -tulnp
            else
                echo -e "${ROJO}[ERROR]${NC} No se encuentra ss ni netstat."
            fi
            ;;

        10)
            echo
            echo -e "${CYAN}========== IP PUBLICA ==========${NC}"
            PUBIP=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null)
            if [ -n "$PUBIP" ]; then
                echo -e "${VERDE}[IP PUBLICA]${NC} $PUBIP"
            else
                PUBIP2=$(curl -s --connect-timeout 5 https://api.ipify.org 2>/dev/null)
                if [ -n "$PUBIP2" ]; then
                    echo -e "${VERDE}[IP PUBLICA]${NC} $PUBIP2"
                else
                    echo -e "${ROJO}[ERROR]${NC} No se pudo obtener la IP publica."
                    echo "Comprueba tu conexion a Internet."
                fi
            fi
            ;;

        11)
            echo
            echo -e "${CYAN}========== ESTADO VPN ==========${NC}"
            if ip addr 2>/dev/null | grep -qE 'tun[0-9]|wg[0-9]|tap[0-9]|proton[0-9]|nordlynx'; then
                echo -e "${VERDE}[OK]${NC} Interfaz VPN detectada:"
                echo
                ip addr | grep -A 3 -E 'tun[0-9]|wg[0-9]|tap[0-9]|proton[0-9]|nordlynx'
            else
                echo -e "${AMARILLO}[AVISO]${NC} No se detectan interfaces VPN activas (tun/wg/tap)."
            fi
            ;;

        12)
            echo
            echo -e "${CYAN}========== ESTADO DEL FIREWALL ==========${NC}"
            if command -v ufw >/dev/null 2>&1; then
                echo -e "${AZUL}Usando: UFW${NC}"
                sudo ufw status verbose 2>/dev/null || ufw status verbose
            elif command -v iptables >/dev/null 2>&1; then
                echo -e "${AZUL}Usando: iptables${NC}"
                sudo iptables -L -n -v 2>/dev/null | head -40
                echo
                echo -e "${AMARILLO}[INFO]${NC} Mostrando solo las primeras 40 lineas. Usa 'iptables -L -n -v' para ver todo."
            else
                echo -e "${ROJO}[ERROR]${NC} No se detecta ufw ni iptables."
            fi
            ;;

        13)
            echo
            echo -e "${CYAN}========== USUARIOS CONECTADOS Y ACCESOS ==========${NC}"
            echo -e "${AZUL}--- Sesiones activas (who) ---${NC}"
            who
            echo
            echo -e "${AZUL}--- Usuarios con actividad (w) ---${NC}"
            w
            echo
            echo -e "${AZUL}--- Últimos 5 accesos (last) ---${NC}"
            last -n 5
            ;;

        14)
            echo
            echo -e "${CYAN}========== TEMPERATURA Y CPU ==========${NC}"
            echo -e "${AZUL}--- Información del procesador ---${NC}"
            lscpu | grep -E 'Model name|CPU\(s\)|Thread|Core|MHz'
            echo
            if command -v sensors >/dev/null 2>&1; then
                echo -e "${AZUL}--- Sensores (temperaturas) ---${NC}"
                sensors
            else
                echo -e "${AMARILLO}[AVISO]${NC} 'sensors' no esta instalado."
                echo "Instalalo con: sudo apt install lm-sensors && sudo sensors-detect"
            fi
            ;;

        15)
            echo
            echo -e "${CYAN}========== LIMPIEZA DE PAQUETES ==========${NC}"
            echo -e "${AMARILLO}Esto eliminara paquetes huerfanos, dependencias innecesarias y caché.${NC}"
            echo
            read -r -p "¿Deseas continuar? [s/N]: " confirmar
            if [[ "$confirmar" =~ ^[sS]$ ]]; then
                echo
                sudo apt autoremove -y && sudo apt autoclean
                echo
                echo -e "${VERDE}[OK]${NC} Limpieza completada correctamente."
            else
                echo -e "${AMARILLO}[CANCELADO]${NC} Operacion cancelada."
            fi
            ;;

        16)
            echo
            echo -e "${CYAN}========== GENERANDO INFORME ==========${NC}"
            REPORTE="$HOME/parrot-diagnostico-$(date +%Y%m%d_%H%M%S).txt"
            {
                echo "=============================================="
                echo "      PARROT OS - INFORME DE DIAGNOSTICO     "
                echo "=============================================="
                echo "Fecha: $(date)"
                echo "Usuario: $(whoami)"
                echo "Hostname: $(hostname)"
                echo "Sistema: $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '\"')"
                echo "Kernel: $(uname -r)"
                echo "Arquitectura: $(uname -m)"
                echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
                echo "=============================================="

                echo -e "\n[RED - INTERFACES]"
                ip -brief address 2>/dev/null
                echo -e "\n[RED - RUTAS]"
                ip route 2>/dev/null

                echo -e "\n[INTERNET]"
                if ping -c 2 -W 2 1.1.1.1 >/dev/null 2>&1; then echo "Ping 1.1.1.1: OK"; else echo "Ping 1.1.1.1: FAIL"; fi
                if getent hosts deb.parrot.sh >/dev/null 2>&1; then echo "DNS deb.parrot.sh: OK"; else echo "DNS deb.parrot.sh: FAIL"; fi
                PUBIP=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null)
                [ -n "$PUBIP" ] && echo "IP Publica: $PUBIP" || echo "IP Publica: NO OBTENIDA"

                echo -e "\n[VPN]"
                if ip addr 2>/dev/null | grep -qE 'tun[0-9]|wg[0-9]|tap[0-9]|proton[0-9]|nordlynx'; then
                    echo "Estado: ACTIVA"
                    ip addr | grep -A 2 -E 'tun[0-9]|wg[0-9]|tap[0-9]|proton[0-9]|nordlynx'
                else
                    echo "Estado: INACTIVA / NO DETECTADA"
                fi

                echo -e "\n[MEMORIA RAM]"
                free -h

                echo -e "\n[ESPACIO EN DISCO]"
                df -hT | grep -v tmpfs | grep -v overlay

                echo -e "\n[PUERTOS ESCUCHANDO]"
                if command -v ss >/dev/null 2>&1; then
                    ss -tulnp 2>/dev/null
                elif command -v netstat >/dev/null 2>&1; then
                    netstat -tulnp 2>/dev/null
                else
                    echo "No disponible (ss/netstat)"
                fi

                echo -e "\n[USUARIOS CONECTADOS]"
                who

                echo -e "\n[ÚLTIMOS ACCESOS]"
                last -n 5

                echo -e "\n[FIREWALL]"
                if command -v ufw >/dev/null 2>&1; then
                    ufw status verbose 2>/dev/null || sudo ufw status verbose 2>/dev/null
                elif command -v iptables >/dev/null 2>&1; then
                    iptables -L -n -v 2>/dev/null | head -30
                else
                    echo "No detectado"
                fi

                echo -e "\n[PAQUETES ACTUALIZABLES]"
                apt list --upgradable 2>/dev/null | tail -n +2

                echo -e "\n=============================================="
                echo "                FIN DEL INFORME              "
                echo "=============================================="
            } > "$REPORTE"

            echo -e "${VERDE}[OK]${NC} Informe guardado correctamente."
            echo -e "${AZUL}Ruta:${NC} $REPORTE"
            ;;

        0)
            echo
            echo -e "${CYAN}Saliendo de Parrot OS - Bash Tool...${NC}"
            echo -e "${VERDE}¡Hasta luego!${NC}"
            exit 0
            ;;

        *)
            echo
            echo -e "${ROJO}[ERROR]${NC} Opcion no valida."
            echo -e "Selecciona una opcion del ${VERDE}0${NC} al ${VERDE}16${NC}."
            ;;
    esac

    pausar
done
