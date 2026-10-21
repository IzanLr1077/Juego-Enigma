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

FICHERO_FRASES="frases.dat"

if [ ! -f "$FICHERO_FRASES" ]; then
    echo "Error: El fichero de datos '$FICHERO_FRASES' no existe en la ruta actual."
    exit 1
fi

if [ ! -r "$FICHERO_FRASES" ]; then
    echo "Error: No se tienen permisos de lectura sobre '$FICHERO_FRASES'."
    exit 1
fi

LINEAS_FORMATO_INCORRECTO=$(egrep -v "^(REFRAN|PELICULA|MUSICA|DEPORTE):[A-Z ]+$" "$FICHERO_FRASES" | wc -l)

if [ "$LINEAS_FORMATO_INCORRECTO" -gt 0 ]; then
    echo "Error: El fichero '$FICHERO_FRASES' contiene lineas con formato o categorias no validas."
    exit 1
fi

DUPLICADOS=$(cut -d':' -f2 "$FICHERO_FRASES" | sort | uniq -d | wc -l)

if [ "$DUPLICADOS" -gt 0 ]; then
    echo "Error: Se han detectado frases repetidas dentro del fichero '$FICHERO_FRASES'."
    exit 1
fi

TOTAL_FRASES=$(wc -l < "$FICHERO_FRASES")

if [ "$TOTAL_FRASES" -eq 0 ]; then
    echo "Error: El fichero '$FICHERO_FRASES' esta vacio."
    exit 1
fi

echo "Verificacion de '$FICHERO_FRASES' completada con exito. Total de frases validas: $TOTAL_FRASES"
