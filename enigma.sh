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

	JUGADORES=$(egrep "^JUGADORES=" "$FICHERO_CONFIG" | cut -d'=' -f2 | tr -d '\r') 
	RONDAS=$(egrep "^RONDAS=" "$FICHERO_CONFIG" | cut -d'=' -f2 | tr -d '\r')
   	PVIDA=$(egrep "^PVIDA=" "$FICHERO_CONFIG" | cut -d'=' -f2 | tr -d '\r')
   	PFALLO=$(egrep "^PFALLO=" "$FICHERO_CONFIG" | cut -d'=' -f2 | tr -d '\r')
   	PRESPUESTA=$(egrep "^PRESPUESTA=" "$FICHERO_CONFIG" | cut -d'=' -f2 | tr -d '\r')
   	CATEGORIAS=$(egrep "^CATEGORIAS=" "$FICHERO_CONFIG" | cut -d'=' -f2 | tr -d '\r')
   	ESTRATEGIA=$(egrep "^ESTRATEGIA=" "$FICHERO_CONFIG" | cut -d'=' -f2 | tr -d '\r')
   	LOG=$(egrep "^LOG=" "$FICHERO_CONFIG" | cut -d'=' -f2 | tr -d '\r' | xargs)

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

verificar_log() {
    LOG=$(echo "$LOG" | tr -d '\r' | xargs)
    local dir_log
    dir_log=$(dirname "$LOG")

    if [ ! -d "$dir_log" ]; then
        mkdir -p "$dir_log" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "Error: No se puede crear el directorio para el log '$dir_log'."
            return 1
        fi
    fi

    if [ -f "$LOG" ]; then
        if [ ! -w "$LOG" ]; then
            echo "Error: No se tienen permisos de escritura sobre el fichero de log '$LOG'."
            return 1
        fi
    else
        touch "$LOG" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "Error: No se puede crear el fichero de log '$LOG'."
            return 1
        fi
    fi

    return 0
}

obtener_frases_disponibles() {
    local patron=""
    case "$CATEGORIAS" in
        1) patron="^(REFRAN):" ;;
        2) patron="^(REFRAN|PELICULA):" ;;
        3) patron="^(REFRAN|PELICULA|MUSICA):" ;;
        4) patron="^(REFRAN|PELICULA|MUSICA|DEPORTE):" ;;
    esac

    egrep "$patron" "$FICHERO_FRASES" > .tmp_frases_partida.txt
}

pausa() {
   	echo ""
        echo -n "Pulse una tecla para continuar..."
    	read -n 1 -r
    	echo ""
}

elegir_letra_ia() {
    local orden_letras=""
    if [ "$ESTRATEGIA" -eq 0 ]; then
        local libres=()
        for l in A B C D E F G H I J K L M N O P Q R S T U V W X Y Z; do
            if ! echo "$LETRAS_USADAS" | grep -q "$l"; then
                libres+=("$l")
            fi
        done
        local total=${#libres[@]}
        if [ "$total" -gt 0 ]; then
            local i=$((RANDOM % total))
            echo "${libres[$i]}"
            return
        fi
    elif [ "$ESTRATEGIA" -eq 1 ]; then
        orden_letras="A B C D E F G H I J K L M N O P Q R S T U V W X Y Z"
    else
        orden_letras="E A O S R N D L C T I U M P B G V Y Q H F Z J X W K"
    fi

    for l in $orden_letras; do
        if ! echo "$LETRAS_USADAS" | grep -q "$l"; then
            echo "$l"
            return
        fi
    done
}

inicializar_frase_oculta() {
    FRASE_OCULTA=""
    for ((k=0; k<${#FRASE_REAL}; k++)); do
        local char="${FRASE_REAL:$k:1}"
        if [ "$char" = " " ]; then
            FRASE_OCULTA="${FRASE_OCULTA} "
        else
            FRASE_OCULTA="${FRASE_OCULTA}_"
        fi
    done
}

mostrar_tablero() {
    clear
    echo "======================================================"
    echo " RONDA $RONDA_ACTUAL de $RONDAS | CATEGORIA: $CATEGORIA_ACTUAL"
    echo "======================================================"
    echo ""
    echo " FRASE: $FRASE_OCULTA"
    echo ""
    echo "------------------------------------------------------"
    echo " JUGADORES Y PUNTOS DE VIDA:"
    for ((i=1; i<=JUGADORES; i++)); do
        local marca=" "
        if [ "$i" -eq "$TURNO_ACTUAL" ]; then
            marca="->"
        fi
        eval "local p_vida=\$PVIDA_J$i"
        echo "  $marca Jugador $i: $p_vida PVIDA"
    done
    echo "------------------------------------------------------"
    echo " Letras usadas en la ronda: $LETRAS_USADAS"
    echo "======================================================"
}

jugar_partida() {
    obtener_frases_disponibles

    local fecha_inicio
    fecha_inicio=$(date "+%Y-%m-%d %H:%M:%S")
    local t_inicio
    t_inicio=$(date +%s)

    for ((i=1; i<=JUGADORES; i++)); do
        eval "RGJ$i=0"
        eval "PVIDA_ACUM_J$i=0"
    done

    local suma_pvidas_totales=0
    local total_lineas
    total_lineas=$(wc -l < .tmp_frases_partida.txt)

    for ((r=1; r<=RONDAS; r++)); do
        RONDA_ACTUAL=$r

        local num_linea=$(((RANDOM % total_lineas) + 1))
        local linea_elegida
        linea_elegida=$(sed -n "${num_linea}p" .tmp_frases_partida.txt)

        CATEGORIA_ACTUAL=$(echo "$linea_elegida" | cut -d':' -f1)
        FRASE_REAL=$(echo "$linea_elegida" | cut -d':' -f2)

        for ((i=1; i<=JUGADORES; i++)); do
            eval "PVIDA_J$i=$PVIDA"
        done

        LETRAS_USADAS=""
        inicializar_frase_oculta

        TURNO_ACTUAL=1
        local ronda_resuelta=0

        while [ "$ronda_resuelta" -eq 0 ]; do
            eval "local vida_actual=\$PVIDA_J$TURNO_ACTUAL"

            if [ "$vida_actual" -le 0 ]; then
                TURNO_ACTUAL=$(((TURNO_ACTUAL % JUGADORES) + 1))

                local activos=0
                for ((j=1; j<=JUGADORES; j++)); do
                    eval "local v=\$PVIDA_J$j"
                    if [ "$v" -gt 0 ]; then
                        activos=$((activos + 1))
                    fi
                done

                if [ "$activos" -eq 0 ]; then
                    mostrar_tablero
                    echo "Todos los jugadores han quedado sin PVIDA. Ronda desierta."
                    ronda_resuelta=1
                    pausa
                    break
                fi
                continue
            fi

            mostrar_tablero

            local accion=""
            local letra=""

            if [ "$TURNO_ACTUAL" -eq 1 ]; then
                echo "Turno del Jugador 1 (Humano)"
                echo "1) Solicitar letra"
                echo "2) Intentar resolver frase"
                echo -n "Elija opcion (1-2) >> "
                read accion

                case "$accion" in
                    1)
                        echo -n "Introduzca una letra >> "
                        read letra
                        letra=$(echo "$letra" | tr '[:lower:]' '[:upper:]')

                        if ! [[ "$letra" =~ ^[A-Z]$ ]]; then
                            echo "Error: Debe introducir una unica letra (A-Z)."
                            pausa
                            continue
                        fi

                        if echo "$LETRAS_USADAS" | grep -q "$letra"; then
                            echo "La letra '$letra' ya ha sido utilizada previamente. Introduzca otra."
                            pausa
                            continue
                        fi

                        LETRAS_USADAS="$LETRAS_USADAS $letra"

                        if echo "$FRASE_REAL" | grep -q "$letra"; then
                            echo "¡Acierto! La letra '$letra' esta en la frase."

                            NUEVA_OCULTA=""
                            for ((k=0; k<${#FRASE_REAL}; k++)); do
                                local c_real="${FRASE_REAL:$k:1}"
                                local c_ocult="${FRASE_OCULTA:$k:1}"
                                if [ "$c_real" = "$letra" ]; then
                                    NUEVA_OCULTA="${NUEVA_OCULTA}${letra}"
                                else
                                    NUEVA_OCULTA="${NUEVA_OCULTA}${c_ocult}"
                                fi
                            done
                            FRASE_OCULTA="$NUEVA_OCULTA"

                            if [ "$FRASE_OCULTA" = "$FRASE_REAL" ]; then
                                mostrar_tablero
                                echo "¡Felicidades! Jugador 1 ha completado la frase."
                                eval "RGJ1=$((RGJ1 + 1))"
                                ronda_resuelta=1
                                pausa
                            else
                                pausa
                            fi
                        else
                            echo "La letra '$letra' NO esta en la frase. Pierde $PFALLO PVIDA."
                            eval "PVIDA_J1=\$((PVIDA_J1 - PFALLO))"
                            TURNO_ACTUAL=$(((TURNO_ACTUAL % JUGADORES) + 1))
                            pausa
                        fi
                        ;;
                    2)
                        echo -n "Introduzca la frase completa >> "
                        read respuesta_user
                        respuesta_user=$(echo "$respuesta_user" | tr '[:lower:]' '[:upper:]')

                        if [ "$respuesta_user" = "$FRASE_REAL" ]; then
                            FRASE_OCULTA="$FRASE_REAL"
                            mostrar_tablero
                            echo "¡CORRECTO! Jugador 1 ha resuelto la frase."
                            eval "RGJ1=$((RGJ1 + 1))"
                            ronda_resuelta=1
                            pausa
                        else
                            echo "Frase incorrecta. Pierde $PRESPUESTA PVIDA."
                            eval "PVIDA_J1=\$((PVIDA_J1 - PRESPUESTA))"
                            TURNO_ACTUAL=$(((TURNO_ACTUAL % JUGADORES) + 1))
                            pausa
                        fi
                        ;;
                    *)
                        echo "Opcion invalida."
                        pausa
                        ;;
                esac
            else
                echo "Turno del Jugador $TURNO_ACTUAL (IA - Estrategia $ESTRATEGIA)..."
                sleep 1
                letra=$(elegir_letra_ia)
                echo "El Jugador $TURNO_ACTUAL solicita la letra: $letra"

                LETRAS_USADAS="$LETRAS_USADAS $letra"

                if echo "$FRASE_REAL" | grep -q "$letra"; then
                    echo "¡Acierto del Jugador $TURNO_ACTUAL!"

                    NUEVA_OCULTA=""
                    for ((k=0; k<${#FRASE_REAL}; k++)); do
                        local c_real="${FRASE_REAL:$k:1}"
                        local c_ocult="${FRASE_OCULTA:$k:1}"
                        if [ "$c_real" = "$letra" ]; then
                            NUEVA_OCULTA="${NUEVA_OCULTA}${letra}"
                        else
                            NUEVA_OCULTA="${NUEVA_OCULTA}${c_ocult}"
                        fi
                    done
                    FRASE_OCULTA="$NUEVA_OCULTA"

                    if [ "$FRASE_OCULTA" = "$FRASE_REAL" ]; then
                        mostrar_tablero
                        echo "¡Jugador $TURNO_ACTUAL ha resuelto la frase al completarla!"
                        eval "RGJ$TURNO_ACTUAL=\$((RGJ$TURNO_ACTUAL + 1))"
                        ronda_resuelta=1
                        pausa
                    else
                        pausa
                    fi
                else
                    echo "El Jugador $TURNO_ACTUAL falla. Pierde $PFALLO PVIDA."
                    eval "PVIDA_J$TURNO_ACTUAL=\$((PVIDA_J$TURNO_ACTUAL - PFALLO))"
                    TURNO_ACTUAL=$(((TURNO_ACTUAL % JUGADORES) + 1))
                    pausa
                fi
            fi
        done

        for ((i=1; i<=JUGADORES; i++)); do
            eval "local v_fin=\$PVIDA_J$i"
            if [ "$v_fin" -lt 0 ]; then v_fin=0; fi
            eval "PVIDA_ACUM_J$i=\$((PVIDA_ACUM_J$i + v_fin))"
            suma_pvidas_totales=$((suma_pvidas_totales + v_fin))
        done
    done

    rm -f .tmp_frases_partida.txt

    local t_fin
    t_fin=$(date +%s)
    local duracion=$((t_fin - t_inicio))

    local ganador=1
    eval "local max_rondas=\$RGJ1"
    eval "local max_pvidas=\$PVIDA_ACUM_J1"

    for ((i=2; i<=JUGADORES; i++)); do
        eval "local r_i=\$RGJ$i"
        eval "local p_i=\$PVIDA_ACUM_J$i"

        if [ "$r_i" -gt "$max_rondas" ]; then
            max_rondas=$r_i
            max_pvidas=$p_i
            ganador=$i
        elif [ "$r_i" -eq "$max_rondas" ]; then
            if [ "$p_i" -gt "$max_pvidas" ]; then
                max_pvidas=$p_i
                ganador=$i
            fi
        fi
    done

    local media_pvida=0
    if [ "$RONDAS" -gt 0 ]; then
        media_pvida=$((suma_pvidas_totales / RONDAS))
    fi

    local rgj1_val=${RGJ1:-0}
    local rgj2_val=${RGJ2:--}
    local rgj3_val=${RGJ3:--}
    local rgj4_val=${RGJ4:--}

    if [ "$JUGADORES" -lt 2 ]; then rgj2_val="-"; fi
    if [ "$JUGADORES" -lt 3 ]; then rgj3_val="-"; fi
    if [ "$JUGADORES" -lt 4 ]; then rgj4_val="-"; fi

    if [ ! -s "$LOG" ]; then
        echo "FECHA|HORA|TPO|JUGADORES|RONDAS|PVIDA|PFALLO|PRESPUESTA|CATEGORIAS|ESTRATEGIA|GANADOR|RONDAS_GANADAS_J1|RONDAS_GANADAS_J2|RONDAS_GANADAS_J3|RONDAS_GANADAS_J4|LETRAS_UTILIZADAS|FRASES_RESUELTAS|ESTADISTICA_LIBRE" > "$LOG"
    fi

    echo "$fecha_log|$hora_log|$duracion|$JUGADORES|$RONDAS|$PVIDA|$PFALLO|$PRESPUESTA|$CATEGORIAS|$ESTRATEGIA|$ganador|$rgj1_val|$rgj2_val|$rgj3_val|$rgj4_val|$total_letras_partida|$total_frases_resueltas|$media_pvida" >> "$LOG"

    clear
    echo "======================================================"
    echo "              FIN DE LA PARTIDA                       "
    echo "======================================================"
    echo " Ganador final de la partida: JUGADOR $ganador"
    echo " Duracion total: $duracion segundos"
    echo " Media PVIDA conservados por ronda: $media_pvida"
    echo "------------------------------------------------------"
    for ((i=1; i<=JUGADORES; i++)); do
        eval "local r_ganadas=\$RGJ$i"
        eval "local p_acum=\$PVIDA_ACUM_J$i"
        echo "  Jugador $i: $r_ganadas rondas ganadas ($p_acum PVIDA acumulados)"
    done
    echo "======================================================"
    echo "Registro guardado en: $LOG"
    pausa
}

menu_frases() {
    local subopcion=""
    while [ "$subopcion" != "0" ]; do
        clear
        echo "======================================================"
        echo "             MANTENIMIENTO DE FRASES                  "
        echo "======================================================"
        echo "1) Consultar/Listar frases existentes"
        echo "2) Añadir una nueva frase"
        echo "0) Volver al menu principal"
        echo "======================================================"
        echo -n "Seleccione una opcion >> "
        read subopcion

        case "$subopcion" in
            1)
                clear
                echo "======================================================"
                echo "               FRASES REGISTRADAS                     "
                echo "======================================================"
                if [ -s "$FICHERO_FRASES" ]; then
                    nl -w3 -s". " "$FICHERO_FRASES"
                else
                    echo "No hay frases registradas."
                fi
                echo "======================================================"
                pausa
                ;;
            2)
                clear
                echo "======================================================"
                echo "                 AÑADIR NUEVA FRASE                   "
                echo "======================================================"
                echo "Seleccione Categoria:"
                echo "1) REFRAN"
                echo "2) PELICULA"
                echo "3) MUSICA"
                echo "4) DEPORTE"
                echo -n "Opcion (1-4) >> "
                read cat_opc

                local cat_nom=""
                case "$cat_opc" in
                    1) cat_nom="REFRAN" ;;
                    2) cat_nom="PELICULA" ;;
                    3) cat_nom="MUSICA" ;;
                    4) cat_nom="DEPORTE" ;;
                    *)
                        echo "Categoria invalida."
                        pausa
                        continue
                        ;;
                esac

                echo -n "Introduzca el texto de la frase >> "
                read texto_frase
                texto_frase=$(echo "$texto_frase" | tr '[:lower:]' '[:upper:]')

                if ! [[ "$texto_frase" =~ ^[A-Z\ ]+$ ]]; then
                    echo "Error: La frase solo debe contener letras (A-Z) y espacios, sin acentos ni caracteres especiales."
                    pausa
                    continue
                fi

                if cut -d':' -f2 "$FICHERO_FRASES" | grep -q "^$texto_frase$"; then
                    echo "Error: La frase '$texto_frase' ya existe en el fichero."
                    pausa
                    continue
                fi

                echo "${cat_nom}:${texto_frase}" >> "$FICHERO_FRASES"
                echo "¡Frase añadida con exito a $FICHERO_FRASES!"
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

mostrar_estadisticas() {
    clear
    LOG=$(echo "$LOG" | tr -d '\r' | xargs)
    echo "======================================================"
    echo "              ESTADISTICAS DE JUEGO                   "
    echo "======================================================"

    if [ ! -f "$LOG" ] || [ ! -s "$LOG" ]; then
        echo "No existen partidas registradas en el fichero de log ('$LOG')."
        echo "======================================================"
        pausa
        return
    fi

    awk -F'|' '
    BEGIN {
        count = 0;
        sum_tpo = 0;
        sum_rondas = 0;
        sum_letras = 0;
        sum_est_libre = 0;
        min_tpo = 999999999;
        max_tpo = -1;

        for (i=1; i<=4; i++) {
            part_j[i] = 0;
            wins_j[i] = 0;
        }
        for (s=0; s<=2; s++) est_count[s] = 0;
        for (c=1; c<=4; c++) cat_count[c] = 0;
    }
    NR == 1 && $1 ~ /FECHA/ { next }
    {
        if (NF >= 17) {
            count++;
            fecha = $1;
            hora = $2;
            tpo = $3 + 0;
            n_jug = $4 + 0;
            rondas = $5 + 0;
            cat = $9 + 0;
            est = $10 + 0;
            ganador = $11 + 0;
            letras = $16 + 0;
            est_libre = ($18 != "" ? $18 + 0 : 0);

            sum_tpo += tpo;
            sum_rondas += rondas;
            sum_letras += letras;
            sum_est_libre += est_libre;

            if (tpo < min_tpo) {
                min_tpo = tpo;
                fecha_min = fecha " " hora;
            }
            if (tpo > max_tpo) {
                max_tpo = tpo;
                fecha_max = fecha " " hora;
            }

            for (i=1; i<=4; i++) {
                rg_val = $(11 + i);
                if (rg_val != "-") {
                    part_j[i]++;
                }
            }
            if (ganador >= 1 && ganador <= 4) {
                wins_j[ganador]++;
            }

            if (est >= 0 && est <= 2) {
                est_count[est]++;
            }

            if (cat >= 1 && cat <= 4) {
                cat_count[cat]++;
            }
        }
    }
    END {
        if (count == 0) {
            print "No hay registros validos de partidas.";
            exit;
        }

        printf " 1. Partidas jugadas : %d\n", count;
        printf " 2. Tiempo medio     : %.2f segundos\n", sum_tpo / count;
        printf " 3. Partida mas corta: %s (%d segundos)\n", fecha_min, min_tpo;
        printf "    Partida mas larga: %s (%d segundos)\n", fecha_max, max_tpo;
        print  " 4. Rendimiento por jugador:";
        for (i=1; i<=4; i++) {
            if (part_j[i] > 0) {
                pct = (wins_j[i] / part_j[i]) * 100;
                printf "    * Jugador %d: %d victorias / %d partidas (%.2f%%)\n", i, wins_j[i], part_j[i], pct;
            } else {
                printf "    * Jugador %d: Sin participaciones\n", i;
            }
        }
        printf " 5. Promedio de rondas: %.2f rondas/partida\n", sum_rondas / count;

        max_est_val = -1;
        for (s=0; s<=2; s++) {
            if (est_count[s] > max_est_val) max_est_val = est_count[s];
        }
        est_str = "";
        for (s=0; s<=2; s++) {
            if (est_count[s] == max_est_val && max_est_val > 0) {
                if (est_str != "") est_str = est_str ", ";
                est_str = est_str "Estrategia " s;
            }
        }
        printf " 6. Estrategia IA mas utilizada : %s\n", (est_str != "" ? est_str : "N/A");

        max_cat_val = -1;
        for (c=1; c<=4; c++) {
            if (cat_count[c] > max_cat_val) max_cat_val = cat_count[c];
        }
        cat_str = "";
        for (c=1; c<=4; c++) {
            if (cat_count[c] == max_cat_val && max_cat_val > 0) {
                if (cat_str != "") cat_str = cat_str ", ";
                if (c == 1) cat_str = cat_str "Nivel 1 (REFRAN)";
                else if (c == 2) cat_str = cat_str "Nivel 2 (+PELICULA)";
                else if (c == 3) cat_str = cat_str "Nivel 3 (+MUSICA)";
                else if (c == 4) cat_str = cat_str "Nivel 4 (+DEPORTE)";
            }
        }
        printf " 7. Categorias mas utilizadas   : %s\n", (cat_str != "" ? cat_str : "N/A");

        printf " 8. Promedio de letras          : %.2f letras/partida\n", sum_letras / count;
        printf " 9. Estadistica libre           : %.2f PVIDA conservados por ronda\n", sum_est_libre / count;
    }
    ' "$LOG"

    echo "======================================================"
    pausa
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
    echo "JUEGO EL ENIGMA"
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
            if ! verificar_log; then
                pausa
            else
                obtener_frases_disponibles
                TOTAL_DISP=$(wc -l < .tmp_frases_partida.txt)
                if [ "$TOTAL_DISP" -lt "$RONDAS" ]; then
                    echo "Error: No hay suficientes frases disponibles ($TOTAL_DISP) para las rondas configuradas ($RONDAS) en las categorias seleccionadas."
                    rm -f .tmp_frases_partida.txt
                    pausa
                else
                    jugar_partida
                fi
            fi
            ;;
        [fF])
            menu_frases
            ;;
        [eE])
            mostrar_estadisticas
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
