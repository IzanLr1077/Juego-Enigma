#!/bin/bash

if [ $# -eq 1 ]; then
    if [ "$1" = "-g" ]; then
        echo "======================================================"
        echo "           JUEGO EL ENIGMA - MODO INFORMACION         "
        echo "======================================================"
        echo "Desarrollado por:"
        echo "  - [Izan Lozano Ramajo]"
        echo ""
	echo "Estrategia IA (ESTRATEGIA=0)"
	echo "  -  Selecciona de forma totalmente aleatoria una letra del 
		   abecedario (A-Z) que aún no haya sido utilizada en la ronda
		   actual."
	echo ""
	echo "Estrategia IA (ESTRATEGIA=1)"
	echo "  - Recorre el abecedario en orden alfabetico (A,B,C,...) y elige
		  la primera letra que este libre."
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

ficheroFrases="frases.dat"

if [ ! -f "$ficheroFrases" ]; then
    echo "Error: El fichero de datos '$ficheroFrases' no existe en la ruta actual."
    exit 1
fi

if [ ! -r "$ficheroFrases" ]; then
    echo "Error: No se tienen permisos de lectura sobre '$ficheroFrases'."
    exit 1
fi

lineasFormatoIncorrecto=$(egrep -v "^(REFRAN|PELICULA|MUSICA|DEPORTE):[A-Z ]+$" "$ficheroFrases" | wc -l)

if [ "$lineasFormatoIncorrecto" -gt 0 ]; then
    echo "Error: El fichero '$ficheroFrases' contiene lineas con formato o categorias no validas."
    exit 1
fi

frasesDuplicadas=$(cut -d':' -f2 "$ficheroFrases" | sort | uniq -d | wc -l)

if [ "$frasesDuplicadas" -gt 0 ]; then
    echo "Error: Se han detectado frases repetidas dentro del fichero '$ficheroFrases'."
    exit 1
fi

totalFrases=$(wc -l < "$ficheroFrases")

if [ "$totalFrases" -eq 0 ]; then
    echo "Error: El fichero '$ficheroFrases' esta vacio."
    exit 1
fi

ficheroConfig="config.cfg"

cargarConfiguracion() {
    if [ ! -f "$ficheroConfig" ]; then
        echo "Error: El fichero de configuracion '$ficheroConfig' no existe en la ruta actual."
        return 1
    fi

    if [ ! -r "$ficheroConfig" ]; then
        echo "Error: No se tienen permisos de lectura sobre '$ficheroConfig'."
        return 1
    fi

    tr -d '\r' < "$ficheroConfig" > .tmp_cfg_clean && mv .tmp_cfg_clean "$ficheroConfig"

    lineasIncorrectas=$(egrep -v "^(JUGADORES|RONDAS|PVIDA|PFALLO|PRESPUESTA|CATEGORIAS|ESTRATEGIA|LOG)=.*$" "$ficheroConfig" | egrep -v "^[[:space:]]*$" | wc -l)

    if [ "$lineasIncorrectas" -gt 0 ]; then
        echo "Error en '$ficheroConfig': Se han detectado lineas con formato o parametros no validos."
        return 1
    fi

    numJugadores=$(egrep "^JUGADORES=" "$ficheroConfig" | cut -d'=' -f2 | tr -d '\r' | xargs)
    numRondas=$(egrep "^RONDAS=" "$ficheroConfig" | cut -d'=' -f2 | tr -d '\r' | xargs)
    puntosVida=$(egrep "^PVIDA=" "$ficheroConfig" | cut -d'=' -f2 | tr -d '\r' | xargs)
    puntosFallo=$(egrep "^PFALLO=" "$ficheroConfig" | cut -d'=' -f2 | tr -d '\r' | xargs)
    puntosRespuesta=$(egrep "^PRESPUESTA=" "$ficheroConfig" | cut -d'=' -f2 | tr -d '\r' | xargs)
    numCategorias=$(egrep "^CATEGORIAS=" "$ficheroConfig" | cut -d'=' -f2 | tr -d '\r' | xargs)
    estrategiaIa=$(egrep "^ESTRATEGIA=" "$ficheroConfig" | cut -d'=' -f2 | tr -d '\r' | xargs)
    ficheroLog=$(egrep "^LOG=" "$ficheroConfig" | cut -d'=' -f2 | tr -d '\r' | xargs)

    if [ -z "$numJugadores" ] || ! [ "$numJugadores" -ge 2 2>/dev/null ] || ! [ "$numJugadores" -le 4 2>/dev/null ]; then
        echo "Error en '$ficheroConfig': JUGADORES debe ser un entero entre 2 y 4 (valor actual: '$numJugadores')."
        return 1
    fi

    if [ -z "$numRondas" ] || ! [ "$numRondas" -gt 0 2>/dev/null ]; then
        echo "Error en '$ficheroConfig': RONDAS debe ser un entero positivo mayor que 0 (valor actual: '$numRondas')."
        return 1
    fi

    if [ -z "$puntosVida" ] || ! [ "$puntosVida" -ge 50 2>/dev/null ] || ! [ "$puntosVida" -le 100 2>/dev/null ]; then
        echo "Error en '$ficheroConfig': PVIDA debe ser un entero entre 50 y 100 (valor actual: '$puntosVida')."
        return 1
    fi

    if [ -z "$puntosFallo" ] || ! [ "$puntosFallo" -ge 5 2>/dev/null ] || ! [ "$puntosFallo" -le 10 2>/dev/null ]; then
        echo "Error en '$ficheroConfig': PFALLO debe ser un entero entre 5 y 10 (valor actual: '$puntosFallo')."
        return 1
    fi

    if [ -z "$puntosRespuesta" ] || ! [ "$puntosRespuesta" -gt "$puntosFallo" 2>/dev/null ] || ! [ "$puntosRespuesta" -lt "$puntosVida" 2>/dev/null ]; then
        echo "Error en '$ficheroConfig': PRESPUESTA debe cumplir PFALLO < PRESPUESTA < PVIDA (valor actual: '$puntosRespuesta')."
        return 1
    fi

    if [ -z "$numCategorias" ] || ! [ "$numCategorias" -ge 1 2>/dev/null ] || ! [ "$numCategorias" -le 4 2>/dev/null ]; then
        echo "Error en '$ficheroConfig': CATEGORIAS debe ser un entero entre 1 y 4 (valor actual: '$numCategorias')."
        return 1
    fi

    if [ -z "$estrategiaIa" ] || ! [ "$estrategiaIa" -ge 0 2>/dev/null ] || ! [ "$estrategiaIa" -le 2 2>/dev/null ]; then
        echo "Error en '$ficheroConfig': ESTRATEGIA debe ser un entero entre 0 y 2 (valor actual: '$estrategiaIa')."
        return 1
    fi

    if [ -z "$ficheroLog" ]; then
        echo "Error en '$ficheroConfig': La variable LOG no esta definida o esta vacia."
        return 1
    fi

    return 0
}

guardarConfiguracion() {
    cat << EOF > "$ficheroConfig"
	JUGADORES=$numJugadores
	RONDAS=$numRondas
	PVIDA=$puntosVida
	PFALLO=$puntosFallo
	PRESPUESTA=$puntosRespuesta
	CATEGORIAS=$numCategorias
	ESTRATEGIA=$estrategiaIa
	LOG=$ficheroLog
EOF
}

verificarLog() {
    ficheroLog=$(echo "$ficheroLog" | tr -d '\r' | xargs)
    local dirLog
    dirLog=$(dirname "$ficheroLog")

    if [ ! -d "$dirLog" ]; then
        mkdir -p "$dirLog" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "Error: No se puede crear el directorio para el log '$dirLog'."
            return 1
        fi
    fi

    if [ -f "$ficheroLog" ]; then
        if [ ! -w "$ficheroLog" ]; then
            echo "Error: No se tienen permisos de escritura sobre el fichero de log '$ficheroLog'."
            return 1
        fi
    else
        touch "$ficheroLog" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "Error: No se puede crear el fichero de log '$ficheroLog'."
            return 1
        fi
    fi

    return 0
}

obtenerFrasesDisponibles() {
    local patronCategorias=""
    case "$numCategorias" in
        1) patronCategorias="^(REFRAN):" ;;
        2) patronCategorias="^(REFRAN|PELICULA):" ;;
        3) patronCategorias="^(REFRAN|PELICULA|MUSICA):" ;;
        4) patronCategorias="^(REFRAN|PELICULA|MUSICA|DEPORTE):" ;;
    esac

    egrep "$patronCategorias" "$ficheroFrases" > .tmp_frases_partida.txt
}

if ! cargarConfiguracion; then
    exit 1
fi

pausa() {
    echo ""
    echo -n "Pulse una tecla para continuar..."
    read -n 1 -r
    echo ""
}

elegirLetraIa() {
    local ordenLetras=""
    if [ "$estrategiaIa" -eq 0 ]; then
        local letrasLibres=()
        for l in A B C D E F G H I J K L M N O P Q R S T U V W X Y Z; do
            if ! echo "$letrasUsadas" | grep -q "$l"; then
                letrasLibres+=("$l")
            fi
        done
        local totalLibres=${#letrasLibres[@]}
        if [ "$totalLibres" -gt 0 ]; then
            local idxRandom=$((RANDOM % totalLibres))
            echo "${letrasLibres[$idxRandom]}"
            return
        fi
    elif [ "$estrategiaIa" -eq 1 ]; then
        ordenLetras="A B C D E F G H I J K L M N O P Q R S T U V W X Y Z"
    else
        ordenLetras="E A O S R N D L C T I U M P B G V Y Q H F Z J X W K"
    fi

    for l in $ordenLetras; do
        if ! echo "$letrasUsadas" | grep -q "$l"; then
            echo "$l"
            return
        fi
    done
}

inicializarFraseOculta() {
    fraseOculta=""
    for ((k=0; k<${#fraseReal}; k++)); do
        local charActual="${fraseReal:$k:1}"
        if [ "$charActual" = " " ]; then
            fraseOculta="${fraseOculta} "
        else
            fraseOculta="${fraseOculta}_"
        fi
    done
}

mostrarTablero() {
    clear
    echo "======================================================"
    echo " RONDA $rondaActual de $numRondas | CATEGORIA: $categoriaActual"
    echo "======================================================"
    echo ""
    echo " FRASE: $fraseOculta"
    echo ""
    echo "------------------------------------------------------"
    echo " JUGADORES Y PUNTOS DE VIDA:"
    for ((i=1; i<=numJugadores; i++)); do
        local marcaTurno=" "
        if [ "$i" -eq "$turnoActual" ]; then
            marcaTurno="->"
        fi
        eval "local puntosVidaLocal=\$puntosVidaJ$i"
        echo "  $marcaTurno Jugador $i: $puntosVidaLocal PVIDA"
    done
    echo "------------------------------------------------------"
    echo " Letras usadas en la ronda: $letrasUsadas"
    echo "======================================================"
}

jugarPartida() {
    obtenerFrasesDisponibles

    local fechaLog
    fechaLog=$(date "+%d%m%y")
    local horaLog
    horaLog=$(date "+%H:%M:%S")
    local tiempoInicio
    tiempoInicio=$(date +%s)

    for ((i=1; i<=numJugadores; i++)); do
        eval "rondasGanadasJ$i=0"
        eval "puntosVidaAcumuladosJ$i=0"
    done

    local sumaPuntosVidaTotales=0
    local totalLetrasPartida=0
    local totalFrasesResueltas=0
    local totalLineasFrases
    totalLineasFrases=$(wc -l < .tmp_frases_partida.txt)

    for ((r=1; r<=numRondas; r++)); do
        rondaActual=$r

        local numLineaElegida=$(((RANDOM % totalLineasFrases) + 1))
        local lineaElegida
        lineaElegida=$(sed -n "${numLineaElegida}p" .tmp_frases_partida.txt)

        categoriaActual=$(echo "$lineaElegida" | cut -d':' -f1)
        fraseReal=$(echo "$lineaElegida" | cut -d':' -f2)

        for ((i=1; i<=numJugadores; i++)); do
            eval "puntosVidaJ$i=$puntosVida"
        done

        letrasUsadas=""
        inicializarFraseOculta

        turnoActual=1
        local rondaResuelta=0

        while [ "$rondaResuelta" -eq 0 ]; do
            eval "local vidaActualJugador=\$puntosVidaJ$turnoActual"

            if [ "$vidaActualJugador" -le 0 ]; then
                turnoActual=$(((turnoActual % numJugadores) + 1))

                local jugadoresActivos=0
                for ((j=1; j<=numJugadores; j++)); do
                    eval "local vLocal=\$puntosVidaJ$j"
                    if [ "$vLocal" -gt 0 ]; then
                        jugadoresActivos=$((jugadoresActivos + 1))
                    fi
                done

                if [ "$jugadoresActivos" -eq 0 ]; then
                    mostrarTablero
                    echo "Todos los jugadores han quedado sin PVIDA. Ronda desierta."
                    rondaResuelta=1
                    pausa
                    break
                fi
                continue
            fi

            mostrarTablero

            local accionUsuario=""
            local letraElegida=""

            if [ "$turnoActual" -eq 1 ]; then
                echo "Turno del Jugador 1 (Humano)"
                echo "1) Solicitar letra"
                echo "2) Intentar resolver frase"
                echo -n "Elija opcion (1-2) >> "
                read accionUsuario

                case "$accionUsuario" in
                    1)
                        echo -n "Introduzca una letra >> "
                        read letraElegida
                        letraElegida=$(echo "$letraElegida" | tr '[:lower:]' '[:upper:]')

                        if ! [[ "$letraElegida" =~ ^[A-Z]$ ]]; then
                            echo "Error: Debe introducir una unica letra (A-Z)."
                            pausa
                            continue
                        fi

                        if echo "$letrasUsadas" | grep -q "$letraElegida"; then
                            echo "La letra '$letraElegida' ya ha sido utilizada previamente. Introduzca otra."
                            pausa
                            continue
                        fi

                        letrasUsadas="$letrasUsadas $letraElegida"
                        totalLetrasPartida=$((totalLetrasPartida + 1))

                        if echo "$fraseReal" | grep -q "$letraElegida"; then
                            echo "¡Acierto! La letra '$letraElegida' esta en la frase."

                            nuevaFraseOculta=""
                            for ((k=0; k<${#fraseReal}; k++)); do
                                local caracterReal="${fraseReal:$k:1}"
                                local caracterOculto="${fraseOculta:$k:1}"
                                if [ "$caracterReal" = "$letraElegida" ]; then
                                    nuevaFraseOculta="${nuevaFraseOculta}${letraElegida}"
                                else
                                    nuevaFraseOculta="${nuevaFraseOculta}${caracterOculto}"
                                fi
                            done
                            fraseOculta="$nuevaFraseOculta"

                            if [ "$fraseOculta" = "$fraseReal" ]; then
                                mostrarTablero
                                echo "¡Felicidades! Jugador 1 ha completado la frase."
                                eval "rondasGanadasJ1=$((rondasGanadasJ1 + 1))"
                                totalFrasesResueltas=$((totalFrasesResueltas + 1))
                                rondaResuelta=1
                                pausa
                            else
                                pausa
                            fi
                        else
                            echo "La letra '$letraElegida' NO esta en la frase. Pierde $puntosFallo PVIDA."
                            eval "puntosVidaJ1=\$((puntosVidaJ1 - puntosFallo))"
                            turnoActual=$(((turnoActual % numJugadores) + 1))
                            pausa
                        fi
                        ;;
                    2)
                        echo -n "Introduzca la frase completa >> "
                        read respuestaUsuario
                        respuestaUsuario=$(echo "$respuestaUsuario" | tr '[:lower:]' '[:upper:]')

                        if [ "$respuestaUsuario" = "$fraseReal" ]; then
                            fraseOculta="$fraseReal"
                            mostrarTablero
                            echo "¡CORRECTO! Jugador 1 ha resuelto la frase."
                            eval "rondasGanadasJ1=$((rondasGanadasJ1 + 1))"
                            totalFrasesResueltas=$((totalFrasesResueltas + 1))
                            rondaResuelta=1
                            pausa
                        else
                            echo "Frase incorrecta. Pierde $puntosRespuesta PVIDA."
                            eval "puntosVidaJ1=\$((puntosVidaJ1 - puntosRespuesta))"
                            turnoActual=$(((turnoActual % numJugadores) + 1))
                            pausa
                        fi
                        ;;
                    *)
                        echo "Opcion invalida."
                        pausa
                        ;;
                esac
            else
                echo "Turno del Jugador $turnoActual (IA - Estrategia $estrategiaIa)..."
                sleep 1
                letraElegida=$(elegirLetraIa)
                echo "El Jugador $turnoActual solicita la letra: $letraElegida"

                letrasUsadas="$letrasUsadas $letraElegida"
                totalLetrasPartida=$((totalLetrasPartida + 1))

                if echo "$fraseReal" | grep -q "$letraElegida"; then
                    echo "¡Acierto del Jugador $turnoActual!"

                    nuevaFraseOculta=""
                    for ((k=0; k<${#fraseReal}; k++)); do
                        local caracterReal="${fraseReal:$k:1}"
                        local caracterOculto="${fraseOculta:$k:1}"
                        if [ "$caracterReal" = "$letraElegida" ]; then
                            nuevaFraseOculta="${nuevaFraseOculta}${letraElegida}"
                        else
                            nuevaFraseOculta="${nuevaFraseOculta}${caracterOculto}"
                        fi
                    done
                    fraseOculta="$nuevaFraseOculta"

                    if [ "$fraseOculta" = "$fraseReal" ]; then
                        mostrarTablero
                        echo "¡Jugador $turnoActual ha resuelto la frase al completarla!"
                        eval "rondasGanadasJ$turnoActual=\$((rondasGanadasJ$turnoActual + 1))"
                        totalFrasesResueltas=$((totalFrasesResueltas + 1))
                        rondaResuelta=1
                        pausa
                    else
                        pausa
                    fi
                else
                    echo "El Jugador $turnoActual falla. Pierde $puntosFallo PVIDA."
                    eval "puntosVidaJ$turnoActual=\$((puntosVidaJ$turnoActual - puntosFallo))"
                    turnoActual=$(((turnoActual % numJugadores) + 1))
                    pausa
                fi
            fi
        done

        for ((i=1; i<=numJugadores; i++)); do
            eval "local vFin=\$puntosVidaJ$i"
            if [ "$vFin" -lt 0 ]; then vFin=0; fi
            eval "puntosVidaAcumuladosJ$i=\$((puntosVidaAcumuladosJ$i + vFin))"
            sumaPuntosVidaTotales=$((sumaPuntosVidaTotales + vFin))
        done
    done

    rm -f .tmp_frases_partida.txt

    local tiempoFin
    tiempoFin=$(date +%s)
    local duracionPartida=$((tiempoFin - tiempoInicio))

    local jugadorGanador=1
    eval "local maxRondasGanadas=\$rondasGanadasJ1"
    eval "local maxPuntosVida=\$puntosVidaAcumuladosJ1"

    for ((i=2; i<=numJugadores; i++)); do
        eval "local rondasI=\$rondasGanadasJ$i"
        eval "local puntosI=\$puntosVidaAcumuladosJ$i"

        if [ "$rondasI" -gt "$maxRondasGanadas" ]; then
            maxRondasGanadas=$rondasI
            maxPuntosVida=$puntosI
            jugadorGanador=$i
        elif [ "$rondasI" -eq "$maxRondasGanadas" ]; then
            if [ "$puntosI" -gt "$maxPuntosVida" ]; then
                maxPuntosVida=$puntosI
                jugadorGanador=$i
            fi
        fi
    done

    local mediaPuntosVida=0
    if [ "$numRondas" -gt 0 ]; then
        mediaPuntosVida=$((sumaPuntosVidaTotales / numRondas))
    fi

    local rgj1Val=${rondasGanadasJ1:-0}
    local rgj2Val=${rondasGanadasJ2:--}
    local rgj3Val=${rondasGanadasJ3:--}
    local rgj4Val=${rondasGanadasJ4:--}

    if [ "$numJugadores" -lt 2 ]; then rgj2Val="-"; fi
    if [ "$numJugadores" -lt 3 ]; then rgj3Val="-"; fi
    if [ "$numJugadores" -lt 4 ]; then rgj4Val="-"; fi

    if [ ! -s "$ficheroLog" ]; then
        echo "FECHA|HORA|TPO|JUGADORES|RONDAS|PVIDA|PFALLO|PRESPUESTA|CATEGORIAS|ESTRATEGIA|GANADOR|RONDAS_GANADAS_J1|RONDAS_GANADAS_J2|RONDAS_GANADAS_J3|RONDAS_GANADAS_J4|LETRAS_UTILIZADAS|FRASES_RESUELTAS|ESTADISTICA_LIBRE" > "$ficheroLog"
    fi

    echo "$fechaLog|$horaLog|$duracionPartida|$numJugadores|$numRondas|$puntosVida|$puntosFallo|$puntosRespuesta|$numCategorias|$estrategiaIa|$jugadorGanador|$rgj1Val|$rgj2Val|$rgj3Val|$rgj4Val|$totalLetrasPartida|$totalFrasesResueltas|$mediaPuntosVida" >> "$ficheroLog"

    clear
    echo "======================================================"
    echo "              FIN DE LA PARTIDA                       "
    echo "======================================================"
    echo " Ganador final de la partida: JUGADOR $jugadorGanador"
    echo " Duracion total: $duracionPartida segundos"
    echo " Media PVIDA conservados por ronda: $mediaPuntosVida"
    echo "------------------------------------------------------"
    for ((i=1; i<=numJugadores; i++)); do
        eval "local rondasGanadasLocal=\$rondasGanadasJ$i"
        eval "local puntosAcumuladosLocal=\$puntosVidaAcumuladosJ$i"
        echo "  Jugador $i: $rondasGanadasLocal rondas ganadas ($puntosAcumuladosLocal PVIDA acumulados)"
    done
    echo "======================================================"
    echo "Registro guardado en: $ficheroLog"
    pausa
}

menuFrases() {
    local opcionMenu=""
    while [ "$opcionMenu" != "0" ]; do
        clear
        echo "======================================================"
        echo "             MANTENIMIENTO DE FRASES                  "
        echo "======================================================"
        echo "1) Consultar/Listar frases existentes"
        echo "2) Añadir una nueva frase"
        echo "0) Volver al menu principal"
        echo "======================================================"
        echo -n "Seleccione una opcion >> "
        read opcionMenu

        case "$opcionMenu" in
            1)
                clear
                echo "======================================================"
                echo "               FRASES REGISTRADAS                     "
                echo "======================================================"
                if [ -s "$ficheroFrases" ]; then
                    nl -w3 -s". " "$ficheroFrases"
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
                read opcionCategoria

                local nombreCategoria=""
                case "$opcionCategoria" in
                    1) nombreCategoria="REFRAN" ;;
                    2) nombreCategoria="PELICULA" ;;
                    3) nombreCategoria="MUSICA" ;;
                    4) nombreCategoria="DEPORTE" ;;
                    *)
                        echo "Categoria invalida."
                        pausa
                        continue
                        ;;
                esac

                echo -n "Introduzca el texto de la frase >> "
                read textoNuevaFrase
                textoNuevaFrase=$(echo "$textoNuevaFrase" | tr '[:lower:]' '[:upper:]')

                if ! [[ "$textoNuevaFrase" =~ ^[A-Z\ ]+$ ]]; then
                    echo "Error: La frase solo debe contener letras (A-Z) y espacios, sin acentos ni caracteres especiales."
                    pausa
                    continue
                fi

                if cut -d':' -f2 "$ficheroFrases" | grep -q "^$textoNuevaFrase$"; then
                    echo "Error: La frase '$textoNuevaFrase' ya existe en el fichero."
                    pausa
                    continue
                fi

                echo "${nombreCategoria}:${textoNuevaFrase}" >> "$ficheroFrases"
                echo "¡Frase anadida con exito a $ficheroFrases!"
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

mostrarEstadisticas() {
    clear
    ficheroLog=$(echo "$ficheroLog" | tr -d '\r' | xargs)
    echo "======================================================"
    echo "              ESTADISTICAS DE JUEGO                   "
    echo "======================================================"

    if [ ! -f "$ficheroLog" ] || [ ! -s "$ficheroLog" ]; then
        echo "No existen partidas registradas en el fichero de log ('$ficheroLog')."
        echo "======================================================"
        pausa
        return
    fi

    awk -F'|' '
    BEGIN {
        totalPartidas = 0;
        sumaTiempo = 0;
        sumaRondas = 0;
        sumaLetras = 0;
        sumaEstadisticaLibre = 0;
        minTiempo = 999999999;
        maxTiempo = -1;

        for (i=1; i<=4; i++) {
            partidasJugador[i] = 0;
            victoriasJugador[i] = 0;
        }
        for (s=0; s<=2; s++) conteoEstrategia[s] = 0;
        for (c=1; c<=4; c++) conteoCategoria[c] = 0;
    }
    NR == 1 && $1 ~ /FECHA/ { next }
    {
        if (NF >= 17) {
            totalPartidas++;
            fechaStr = $1;
            horaStr = $2;
            tiempoDuracion = $3 + 0;
            numJugadoresPartida = $4 + 0;
            rondasPartida = $5 + 0;
            categoriaPartida = $9 + 0;
            estrategiaPartida = $10 + 0;
            jugadorGanador = $11 + 0;
            letrasPartida = $16 + 0;
            valEstadisticaLibre = ($18 != "" ? $18 + 0 : 0);

            sumaTiempo += tiempoDuracion;
            sumaRondas += rondasPartida;
            sumaLetras += letrasPartida;
            sumaEstadisticaLibre += valEstadisticaLibre;

            if (tiempoDuracion < minTiempo) {
                minTiempo = tiempoDuracion;
                fechaMinima = fechaStr " " horaStr;
            }
            if (tiempoDuracion > maxTiempo) {
                maxTiempo = tiempoDuracion;
                fechaMaxima = fechaStr " " horaStr;
            }

            for (i=1; i<=4; i++) {
                rondasGanadasVal = $(11 + i);
                if (rondasGanadasVal != "-") {
                    partidasJugador[i]++;
                }
            }
            if (jugadorGanador >= 1 && jugadorGanador <= 4) {
                victoriasJugador[jugadorGanador]++;
            }

            if (estrategiaPartida >= 0 && estrategiaPartida <= 2) {
                conteoEstrategia[estrategiaPartida]++;
            }

            if (categoriaPartida >= 1 && categoriaPartida <= 4) {
                conteoCategoria[categoriaPartida]++;
            }
        }
    }
    END {
        if (totalPartidas == 0) {
            print "No hay registros validos de partidas.";
            exit;
        }

        printf " 1. Partidas jugadas : %d\n", totalPartidas;
        printf " 2. Tiempo medio     : %.2f segundos\n", sumaTiempo / totalPartidas;
        printf " 3. Partida mas corta: %s (%d segundos)\n", fechaMinima, minTiempo;
        printf "    Partida mas larga: %s (%d segundos)\n", fechaMaxima, maxTiempo;
        print  " 4. Rendimiento por jugador:";
        for (i=1; i<=4; i++) {
            if (partidasJugador[i] > 0) {
                porcentajeVictorias = (victoriasJugador[i] / partidasJugador[i]) * 100;
                printf "    * Jugador %d: %d victorias / %d partidas (%.2f%%)\n", i, victoriasJugador[i], partidasJugador[i], porcentajeVictorias;
            } else {
                printf "    * Jugador %d: Sin participaciones\n", i;
            }
        }
        printf " 5. Promedio de rondas: %.2f rondas/partida\n", sumaRondas / totalPartidas;

        maxEstrategiaVal = -1;
        for (s=0; s<=2; s++) {
            if (conteoEstrategia[s] > maxEstrategiaVal) maxEstrategiaVal = conteoEstrategia[s];
        }
        textoEstrategia = "";
        for (s=0; s<=2; s++) {
            if (conteoEstrategia[s] == maxEstrategiaVal && maxEstrategiaVal > 0) {
                if (textoEstrategia != "") textoEstrategia = textoEstrategia ", ";
                textoEstrategia = textoEstrategia "Estrategia " s;
            }
        }
        printf " 6. Estrategia IA mas utilizada : %s\n", (textoEstrategia != "" ? textoEstrategia : "N/A");

        maxCategoriaVal = -1;
        for (c=1; c<=4; c++) {
            if (conteoCategoria[c] > maxCategoriaVal) maxCategoriaVal = conteoCategoria[c];
        }
        textoCategoria = "";
        for (c=1; c<=4; c++) {
            if (conteoCategoria[c] == maxCategoriaVal && maxCategoriaVal > 0) {
                if (textoCategoria != "") textoCategoria = textoCategoria ", ";
                if (c == 1) textoCategoria = textoCategoria "Nivel 1 (REFRAN)";
                else if (c == 2) textoCategoria = textoCategoria "Nivel 2 (+PELICULA)";
                else if (c == 3) textoCategoria = textoCategoria "Nivel 3 (+MUSICA)";
                else if (c == 4) textoCategoria = textoCategoria "Nivel 4 (+DEPORTE)";
            }
        }
        printf " 7. Categorias mas utilizadas   : %s\n", (textoCategoria != "" ? textoCategoria : "N/A");

        printf " 8. Promedio de letras          : %.2f letras/partida\n", sumaLetras / totalPartidas;
        printf " 9. Estadistica libre           : %.2f PVIDA conservados por ronda\n", sumaEstadisticaLibre / totalPartidas;
    }
    ' "$ficheroLog"

    echo "======================================================"
    pausa
}

menuConfiguracion() {
    local subOpcionConfig=""
    while [ "$subOpcionConfig" != "0" ]; do
        clear
        echo "======================================================"
        echo "             CONFIGURACION DE LA PARTIDA              "
        echo "======================================================"
        echo "1) JUGADORES  : $numJugadores (2-4)"
        echo "2) RONDAS     : $numRondas (>0)"
        echo "3) PVIDA      : $puntosVida (50-100)"
        echo "4) PFALLO     : $puntosFallo (5-10)"
        echo "5) PRESPUESTA : $puntosRespuesta (PFALLO < PRESPUESTA < PVIDA)"
        echo "6) CATEGORIAS : $numCategorias (1-4)"
        echo "7) ESTRATEGIA : $estrategiaIa (0-2)"
        echo "8) LOG        : $ficheroLog"
        echo "0) Volver al menu principal"
        echo "======================================================"
        echo -n "Seleccione parametro a modificar >> "
        read subOpcionConfig

        case "$subOpcionConfig" in
            1)
                echo -n "Nuevo valor para JUGADORES (2-4): "
                read nuevoValor
                if [ "$nuevoValor" -ge 2 2>/dev/null ] && [ "$nuevoValor" -le 4 2>/dev/null ]; then
                    numJugadores=$nuevoValor
                    guardarConfiguracion
                    echo "Parametro actualizado con exito."
                else
                    echo "Valor invalido."
                fi
                pausa
                ;;
            2)
                echo -n "Nuevo valor para RONDAS (>0): "
                read nuevoValor
                if [ "$nuevoValor" -gt 0 2>/dev/null ]; then
                    numRondas=$nuevoValor
                    guardarConfiguracion
                    echo "Parametro actualizado con exito."
                else
                    echo "Valor invalido."
                fi
                pausa
                ;;
            3)
                echo -n "Nuevo valor para PVIDA (50-100): "
                read nuevoValor
                if [ "$nuevoValor" -ge 50 2>/dev/null ] && [ "$nuevoValor" -le 100 2>/dev/null ] && [ "$nuevoValor" -gt "$puntosRespuesta" 2>/dev/null ]; then
                    puntosVida=$nuevoValor
                    guardarConfiguracion
                    echo "Parametro actualizado con exito."
                else
                    echo "Valor invalido (compruebe limite respecto a PRESPUESTA)."
                fi
                pausa
                ;;
            4)
                echo -n "Nuevo valor para PFALLO (5-10): "
                read nuevoValor
                if [ "$nuevoValor" -ge 5 2>/dev/null ] && [ "$nuevoValor" -le 10 2>/dev/null ] && [ "$nuevoValor" -lt "$puntosRespuesta" 2>/dev/null ]; then
                    puntosFallo=$nuevoValor
                    guardarConfiguracion
                    echo "Parametro actualizado con exito."
                else
                    echo "Valor invalido (compruebe limite respecto a PRESPUESTA)."
                fi
                pausa
                ;;
            5)
                echo -n "Nuevo valor para PRESPUESTA ($puntosFallo < x < $puntosVida): "
                read nuevoValor
                if [ "$nuevoValor" -gt "$puntosFallo" 2>/dev/null ] && [ "$nuevoValor" -lt "$puntosVida" 2>/dev/null ]; then
                    puntosRespuesta=$nuevoValor
                    guardarConfiguracion
                    echo "Parametro actualizado con exito."
                else
                    echo "Valor invalido."
                fi
                pausa
                ;;
            6)
                echo -n "Nuevo valor para CATEGORIAS (1-4): "
                read nuevoValor
                if [ "$nuevoValor" -ge 1 2>/dev/null ] && [ "$nuevoValor" -le 4 2>/dev/null ]; then
                    numCategorias=$nuevoValor
                    guardarConfiguracion
                    echo "Parametro actualizado con exito."
                else
                    echo "Valor invalido."
                fi
                pausa
                ;;
            7)
                echo -n "Nuevo valor para ESTRATEGIA (0-2): "
                read nuevoValor
                if [ "$nuevoValor" -ge 0 2>/dev/null ] && [ "$nuevoValor" -le 2 2>/dev/null ]; then
                    estrategiaIa=$nuevoValor
                    guardarConfiguracion
                    echo "Parametro actualizado con exito."
                else
                    echo "Valor invalido."
                fi
                pausa
                ;;
            8)
                echo -n "Nueva ruta para LOG: "
                read nuevoValor
                if [ -n "$nuevoValor" ]; then
                    ficheroLog=$nuevoValor
                    guardarConfiguracion
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

opcionMenuPrincipal=""

while [ "$opcionMenuPrincipal" != "S" ] && [ "$opcionMenuPrincipal" != "s" ]; do
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
    read opcionMenuPrincipal

    case "$opcionMenuPrincipal" in
        [cC])
            menuConfiguracion
            ;;
        [jJ])
            if ! verificarLog; then
                pausa
            else
                obtenerFrasesDisponibles
                totalDisponibles=$(wc -l < .tmp_frases_partida.txt)
                if [ "$totalDisponibles" -lt "$numRondas" ]; then
                    echo "Error: No hay suficientes frases disponibles ($totalDisponibles) para las rondas configuradas ($numRondas) en las categorias seleccionadas."
                    rm -f .tmp_frases_partida.txt
                    pausa
                else
                    jugarPartida
                fi
            fi
            ;;
        [fF])
            menuFrases
            ;;
        [eE])
            mostrarEstadisticas
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

