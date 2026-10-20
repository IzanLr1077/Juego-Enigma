#!/bin/bash

if [ $# -eq 1 ]; then
    if [ "$1" = "-g" ]; then
        echo "======================================================"
        echo "           JUEGO EL ENIGMA - MODO INFORMACION         "
        echo "======================================================"
        echo "Desarrollado por:"
        echo "  - [Tu Nombre / Nombre de los integrantes]"
        echo ""
        echo "Estrategia IA (ESTRATEGIA=2):"
        echo "  - Selecciona de forma prioritaria las vocales mas frecuentes"
        echo "    en castellano (E, A, O) y posteriormente las consonantes"
        echo "    de mayor frecuencia (S, R, N, D, L, C, T)."
        echo ""
        echo "Estadistica Libre (Menu E):"
        echo "  - Cantidad media de PVIDA conservados por ronda:"
        echo "    Calcula el promedio de puntos de vida (PVIDA) con los que"
        echo "    los jugadores finalizan cada una de las rondas jugadas."
        echo "======================================================"
        exit 0
    else
        echo "Error: Opcion no reconocida '$1'."
        echo "Uso correcto: $0 [-g]"
        exit 1
    fi
elif [ $# -gt 1 ]; then
    echo "Error: Se ha introducido un numero incorrecto de argumentos."
    echo "Uso correcto: $0 [-g]"
    exit 1
fi
echo "Argumentos correctos. Iniciando comprobación del juego..."
