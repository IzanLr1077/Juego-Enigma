#!/bin/bash

if [ $# -eq 1 ]; then
    if [ "$1" = "-g" ]; then
        echo "======================================================"
        echo "           JUEGO EL ENIGMA - MODO INFORMACION         "
        echo "======================================================"
        echo "Desarrollado por:"
        echo "  - [Izan Lozano Ramajo]"
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

FICHERO_CONFIG="config.cfg"

cargar_configuracion() {
	if [ ! -f "$FICHERO_CONFIG" ]; then
		echo "Error: El fichero de configuracion '$FICHERO_CONFIG' no existe."
		return 1
	fi

	if [ ! -r "$FICHERO_CONFIG" ]; then
		echo "Error: El fichero de confugiración '$FICHERO_CONFIG' no se puede leer."
		return 1
	fi

	LINEAS_INCORRECTAS=$(egrep -v "^(JUGADORES|RONDAS|PVIDA|PFALLO|PRESPUESTA|CATEGORIAS|ESTRATEGIA|LOG)=.*$" "$FICHERO_CONFIG" | egrep -v "^[[:space:]]*$" | wc -l)

    	if [ "$LINEAS_INCORRECTAS" -gt 0 ]; then
        	echo "Error en '$FICHERO_CONFIG': Se han detectado lineas con formato o parametros no validos."
        	return 1
    	fi

	JUGADORES=$(egrep "^JUGADORES=" "$FICHERO_CONFIG" | cut -d'=' -f2) 
	RONDAS=$(egrep "^RONDAS=" "$FICHERO_CONFIG" | cut -d'=' -f2)
   	PVIDA=$(egrep "^PVIDA=" "$FICHERO_CONFIG" | cut -d'=' -f2)
   	PFALLO=$(egrep "^PFALLO=" "$FICHERO_CONFIG" | cut -d'=' -f2)
   	PRESPUESTA=$(egrep "^PRESPUESTA=" "$FICHERO_CONFIG" | cut -d'=' -f2)
   	CATEGORIAS=$(egrep "^CATEGORIAS=" "$FICHERO_CONFIG" | cut -d'=' -f2)
   	ESTRATEGIA=$(egrep "^ESTRATEGIA=" "$FICHERO_CONFIG" | cut -d'=' -f2)
   	LOG=$(egrep "^LOG=" "$FICHERO_CONFIG" | cut -d'=' -f2)

	if [ -z "$JUGADORES" ] || ! [ "$JUGADORES" -ge 2 2>/dev/null ] || ! [ "$JUGADORES" -le 4 2>/dev/null ]; then
        	echo "Error en '$FICHERO_CONFIG': JUGADORES debe ser un entero entre 2 y 4 (valor actual: '$JUGADORES')."
       		return 1
    	fi

    	if [ -z "$RONDAS" ] || ! [ "$RONDAS" -gt 0 2>/dev/null ]; then
        	echo "Error en '$FICHERO_CONFIG': RONDAS debe ser un entero positivo mayor que 0 (valor actual: '$RONDAS')."
        	return 1
    	fi

    	if [ -z "$PVIDA" ] || ! [ "$PVIDA" -ge 50 2>/dev/null ] || ! [ "$PVIDA" -le 100 2>/dev/null ]; then
        	echo "Error en '$FICHERO_CONFIG': PVIDA debe ser un entero entre 50 y 100 (valor actual: '$PVIDA')."
        	return 1
    	fi

    	if [ -z "$PFALLO" ] || ! [ "$PFALLO" -ge 5 2>/dev/null ] || ! [ "$PFALLO" -le 10 2>/dev/null ]; then
        	echo "Error en '$FICHERO_CONFIG': PFALLO debe ser un entero entre 5 y 10 (valor actual: '$PFALLO')."
        	return 1
    	fi

    	if [ -z "$PRESPUESTA" ] || ! [ "$PRESPUESTA" -gt "$PFALLO" 2>/dev/null ] || ! [ "$PRESPUESTA" -lt "$PVIDA" 2>/dev/null ]; then
        	echo "Error en '$FICHERO_CONFIG': PRESPUESTA debe cumplir PFALLO < PRESPUESTA < PVIDA (valor actual: '$PRESPUESTA')."
        	return 1
    	fi

    	if [ -z "$CATEGORIAS" ] || ! [ "$CATEGORIAS" -ge 1 2>/dev/null ] || ! [ "$CATEGORIAS" -le 4 2>/dev/null ]; then
        	echo "Error en '$FICHERO_CONFIG': CATEGORIAS debe ser un entero entre 1 y 4 (valor actual: '$CATEGORIAS')."
       	 	return 1
    	fi

    	if [ -z "$ESTRATEGIA" ] || ! [ "$ESTRATEGIA" -ge 0 2>/dev/null ] || ! [ "$ESTRATEGIA" -le 2 2>/dev/null ]; then
        	echo "Error en '$FICHERO_CONFIG': ESTRATEGIA debe ser un entero entre 0 y 2 (valor actual: '$ESTRATEGIA')."
       	 	return 1
    	fi

    	if [ -z "$LOG" ]; then
        	echo "Error en '$FICHERO_CONFIG': La variable LOG no esta definida o esta vacia."
        	return 1
    	fi
    	return 0
}

if ! cargar_configuracion; then
    exit 1
fi

guardar_configuracion() {
    	cat << EOF > "$FICHERO_CONFIG"
	JUGADORES=$JUGADORES
	RONDAS=$RONDAS
	PVIDA=$PVIDA
	PFALLO=$PFALLO
	PRESPUESTA=$PRESPUESTA
	CATEGORIAS=$CATEGORIAS
	ESTRATEGIA=$ESTRATEGIA
	LOG=$LOG	
EOF
}

pausa() {
   	echo ""
        echo -n "Pulse una tecla para continuar..."
    	read -n 1 -r
    	echo ""
}

menu_configuracion() {
    local subopcion=""
    while [ "$subopcion" != "0" ]; do
        clear
        echo "======================================================"
        echo "             CONFIGURACION DE LA PARTIDA              "
        echo "======================================================"
        echo "1) JUGADORES  : $JUGADORES (2..4)"
        echo "2) RONDAS     : $RONDAS (>0)"
        echo "3) PVIDA      : $PVIDA (50..100)"
        echo "4) PFALLO     : $PFALLO (5..10)"
        echo "5) PRESPUESTA : $PRESPUESTA (PFALLO < PRESPUESTA < PVIDA)"
        echo "6) CATEGORIAS : $CATEGORIAS (1..4)"
        echo "7) ESTRATEGIA : $ESTRATEGIA (0..2)"
        echo "8) LOG        : $LOG"
        echo "0) Volver al menu principal"
        echo "======================================================"
        echo -n "Seleccione parametro a modificar >> "
        read subopcion

        case "$subopcion" in
            1)
                echo -n "Nuevo valor para JUGADORES (2..4): "
                read val
                if [ "$val" -ge 2 2>/dev/null ] && [ "$val" -le 4 2>/dev/null ]; then
                    JUGADORES=$val
                    guardar_configuracion
                    echo "Parametro actualizado con exito."
                else
                    echo "Valor invalido."
                fi
                pausa
                ;;
            2)
                echo -n "Nuevo valor para RONDAS (>0): "
                read val
                if [ "$val" -gt 0 2>/dev/null ]; then
                    RONDAS=$val
                    guardar_configuracion
                    echo "Parametro actualizado con exito."
                else
                    echo "Valor invalido."
                fi
                pausa
                ;;
            3)
                echo -n "Nuevo valor para PVIDA (50..100): "
                read val
                if [ "$val" -ge 50 2>/dev/null ] && [ "$val" -le 100 2>/dev/null ] && [ "$val" -gt "$PRESPUESTA" 2>/dev/null ]; then
                    PVIDA=$val
                    guardar_configuracion
                    echo "Parametro actualizado con exito."
                else
                    echo "Valor invalido (compruebe limite respecto a PRESPUESTA)."
                fi
                pausa
                ;;
            4)
                echo -n "Nuevo valor para PFALLO (5..10): "
                read val
                if [ "$val" -ge 5 2>/dev/null ] && [ "$val" -le 10 2>/dev/null ] && [ "$val" -lt "$PRESPUESTA" 2>/dev/null ]; then
                    PFALLO=$val
                    guardar_configuracion
                    echo "Parametro actualizado con exito."
                else
                    echo "Valor invalido (compruebe limite respecto a PRESPUESTA)."
                fi
                pausa
                ;;
            5)
                echo -n "Nuevo valor para PRESPUESTA ($PFALLO < x < $PVIDA): "
                read val
                if [ "$val" -gt "$PFALLO" 2>/dev/null ] && [ "$val" -lt "$PVIDA" 2>/dev/null ]; then
                    PRESPUESTA=$val
                    guardar_configuracion
                    echo "Parametro actualizado con exito."
                else
                    echo "Valor invalido."
                fi
                pausa
                ;;
            6)
                echo -n "Nuevo valor para CATEGORIAS (1..4): "
                read val
                if [ "$val" -ge 1 2>/dev/null ] && [ "$val" -le 4 2>/dev/null ]; then
                    CATEGORIAS=$val
                    guardar_configuracion
                    echo "Parametro actualizado con exito."
                else
                    echo "Valor invalido."
                fi
                pausa
                ;;
            7)
                echo -n "Nuevo valor para ESTRATEGIA (0..2): "
                read val
                if [ "$val" -ge 0 2>/dev/null ] && [ "$val" -le 2 2>/dev/null ]; then
                    ESTRATEGIA=$val
                    guardar_configuracion
                    echo "Parametro actualizado con exito."
                else
                    echo "Valor invalido."
                fi
                pausa
                ;;
            8)
                echo -n "Nueva ruta para LOG: "
                read val
                if [ -n "$val" ]; then
                    LOG=$val
                    guardar_configuracion
                    echo "Parametro actualizado con exito."
                else
                    echo "Ruta invalida."
                fi
                pausa
                ;;
            0)
                ;;
            *)
                echo "Opcion no valida."
                pausa
                ;;
        esac
    done
}

OPCION=""

while [ "$OPCION" != "S" ] && [ "$OPCION" != "s" ]; do
    clear
    echo "JUEGO \"EL ENIGMA\""
    echo "================="
    echo "C) CONFIGURACION"
    echo "J) JUGAR"
    echo "F) FRASES"
    echo "E) ESTADISTICAS"
    echo "S) SALIR"
    echo ""
    echo -n "Introduzca una opcion >> "
    read OPCION

    case "$OPCION" in
        [cC])
            menu_configuracion
            ;;
        [jJ])
            echo "Opcion JUGAR (En desarrollo para el Paso 4)..."
            pausa
            ;;
        [fF])
            echo "Opcion FRASES (En desarrollo para el Paso 5)..."
            pausa
            ;;
        [eE])
            echo "Opcion ESTADISTICAS (En desarrollo para el Paso 5)..."
            pausa
            ;;
        [sS])
            rm -f .tmp_* 2>/dev/null
            echo "Saliendo del juego..."
            ;;
        *)
            echo "Opcion no valida. Intelo de nuevo."
            pausa
            ;;
    esac
done
