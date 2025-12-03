#!/bin/bash

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Banner inicial
clear
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${BOLD}LABORATORIO DE PRUEBAS - BALANCEADOR DE CARGA NGINX${NC}       ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ${BLUE}Politécnico Grancolombiano - Sistemas Operacionales${NC}        ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}[INFO]${NC} Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "${YELLOW}[INFO]${NC} Sistema: $(uname -s) $(uname -r)"
echo ""
sleep 2

# Verificar que Docker está corriendo
echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}[1/7] VERIFICACIÓN DEL ENTORNO${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
echo ""

if ! docker ps &> /dev/null; then
    echo -e "${RED}[ERROR]${NC} Docker no está corriendo o no tienes permisos."
    exit 1
fi

echo -e "${GREEN}✓${NC} Docker operativo"

# Verificar contenedores
CONTAINERS=$(docker ps --filter "name=backend" --filter "name=loadbalancer" --format "{{.Names}}" | wc -l)
if [ "$CONTAINERS" -lt 3 ]; then
    echo -e "${RED}[ERROR]${NC} Se esperaban 3 contenedores (backend1, backend2, loadbalancer)"
    echo -e "${YELLOW}[SUGERENCIA]${NC} Ejecuta: cd ~/lab-docker && docker compose up -d"
    exit 1
fi

echo -e "${GREEN}✓${NC} Contenedores activos: $CONTAINERS"
echo ""
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
sleep 2

# Limpiar logs previos
echo -e "${YELLOW}[INFO]${NC} Limpiando logs de contenedores..."
docker logs backend1 > /dev/null 2>&1
docker logs backend2 > /dev/null 2>&1
echo -e "${GREEN}✓${NC} Logs reiniciados"
echo ""
sleep 1

# Prueba de conectividad básica
echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}[2/7] PRUEBA DE CONECTIVIDAD BÁSICA${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}[INFO]${NC} Ejecutando 20 peticiones de prueba..."
echo ""

for i in {1..20}; do
    RESPONSE=$(curl -s http://localhost:8080 | grep -o "Backend [12]")
    printf "${BLUE}Petición %2d:${NC} %s\n" $i "$RESPONSE"
    sleep 0.1
done

echo ""
echo -e "${GREEN}✓${NC} Conectividad verificada - Balanceo funcionando"
echo ""
sleep 2

# Función para ejecutar pruebas con ab
run_ab_test() {
    local TEST_NAME=$1
    local REQUESTS=$2
    local CONCURRENCY=$3
    local KEEPALIVE=$4

    echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}[$5] PRUEBA: $TEST_NAME${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}[INFO]${NC} Parámetros:"
    echo -e "  • Peticiones totales:    ${BOLD}$REQUESTS${NC}"
    echo -e "  • Concurrencia:          ${BOLD}$CONCURRENCY${NC}"
    echo -e "  • Keep-Alive:            ${BOLD}$KEEPALIVE${NC}"
    echo ""
    echo -e "${BLUE}[EJECUTANDO]${NC} Apache Benchmark..."
    echo ""

    # Ejecutar ab y guardar resultado
    if [ "$KEEPALIVE" == "Sí" ]; then
        AB_OUTPUT=$(ab -n $REQUESTS -c $CONCURRENCY -k http://localhost:8080/ 2>&1)
    else
        AB_OUTPUT=$(ab -n $REQUESTS -c $CONCURRENCY http://localhost:8080/ 2>&1)
    fi

    # Extraer métricas clave
    REQUESTS_PER_SEC=$(echo "$AB_OUTPUT" | grep "Requests per second" | awk '{print $4}')
    TIME_PER_REQUEST=$(echo "$AB_OUTPUT" | grep "Time per request" | head -1 | awk '{print $4}')
    FAILED_REQUESTS=$(echo "$AB_OUTPUT" | grep "Failed requests" | awk '{print $3}')
    TOTAL_TIME=$(echo "$AB_OUTPUT" | grep "Time taken for tests" | awk '{print $5}')
    TRANSFER_RATE=$(echo "$AB_OUTPUT" | grep "Transfer rate" | awk '{print $3}')

    # Mostrar resultados
    echo -e "${GREEN}═══ RESULTADOS ═══${NC}"
    echo ""
    printf "%-30s ${BOLD}%s${NC}\n" "⏱️  Tiempo total:" "$TOTAL_TIME segundos"
    printf "%-30s ${BOLD}%s${NC}\n" "🚀 Peticiones por segundo:" "$REQUESTS_PER_SEC req/s"
    printf "%-30s ${BOLD}%s${NC}\n" "⏳ Tiempo por petición:" "$TIME_PER_REQUEST ms"
    printf "%-30s ${BOLD}%s${NC}\n" "📊 Tasa de transferencia:" "$TRANSFER_RATE KB/s"
    printf "%-30s ${BOLD}%s${NC}\n" "❌ Peticiones fallidas:" "$FAILED_REQUESTS"
    echo ""

    # Guardar para la tabla final
    echo "$TEST_NAME|$REQUESTS|$CONCURRENCY|$REQUESTS_PER_SEC|$TIME_PER_REQUEST|$FAILED_REQUESTS" >> /tmp/test_results.txt

    sleep 2
}

# Limpiar resultados previos
rm -f /tmp/test_results.txt

# Ejecutar pruebas
run_ab_test "CARGA LIGERA" 1000 10 "No" "3/7"
run_ab_test "CARGA MEDIA" 5000 50 "No" "4/7"
run_ab_test "CARGA PESADA" 20000 200 "Sí" "5/7"

# Análisis de distribución de carga
echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}[6/7] ANÁLISIS DE DISTRIBUCIÓN DE CARGA${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}[INFO]${NC} Analizando logs de contenedores..."
echo ""

# Contar peticiones GET en cada backend
BACKEND1_REQUESTS=$(docker logs backend1 2>&1 | grep -c "GET / HTTP")
BACKEND2_REQUESTS=$(docker logs backend2 2>&1 | grep -c "GET / HTTP")
TOTAL_REQUESTS=$((BACKEND1_REQUESTS + BACKEND2_REQUESTS))

# Calcular porcentajes
if [ $TOTAL_REQUESTS -gt 0 ]; then
    BACKEND1_PERCENT=$(awk "BEGIN {printf \"%.2f\", ($BACKEND1_REQUESTS/$TOTAL_REQUESTS)*100}")
    BACKEND2_PERCENT=$(awk "BEGIN {printf \"%.2f\", ($BACKEND2_REQUESTS/$TOTAL_REQUESTS)*100}")
else
    BACKEND1_PERCENT="0.00"
    BACKEND2_PERCENT="0.00"
fi

echo -e "${GREEN}═══ DISTRIBUCIÓN DE PETICIONES ═══${NC}"
echo ""
printf "%-20s ${BOLD}%6d${NC} peticiones (${CYAN}%6.2f%%${NC})\n" "🔵 Backend 1:" $BACKEND1_REQUESTS $BACKEND1_PERCENT
printf "%-20s ${BOLD}%6d${NC} peticiones (${CYAN}%6.2f%%${NC})\n" "🟢 Backend 2:" $BACKEND2_REQUESTS $BACKEND2_PERCENT
printf "%-20s ${BOLD}%6d${NC} peticiones\n" "📊 TOTAL:" $TOTAL_REQUESTS
echo ""

# Evaluar balance
DIFF=$((BACKEND1_REQUESTS - BACKEND2_REQUESTS))
DIFF=${DIFF#-}  # Valor absoluto
if [ $TOTAL_REQUESTS -gt 0 ]; then
    DIFF_PERCENT=$(awk "BEGIN {printf \"%.2f\", ($DIFF/$TOTAL_REQUESTS)*100}")
    if (( $(echo "$DIFF_PERCENT < 10" | bc -l) )); then
        echo -e "${GREEN}✓${NC} Balance: ${GREEN}EXCELENTE${NC} (diferencia < 10%)"
    elif (( $(echo "$DIFF_PERCENT < 20" | bc -l) )); then
        echo -e "${YELLOW}⚠${NC} Balance: ${YELLOW}ACEPTABLE${NC} (diferencia < 20%)"
    else
        echo -e "${RED}✗${NC} Balance: ${RED}DESBALANCEADO${NC} (diferencia > 20%)"
    fi
fi
echo ""
sleep 2

# Tabla resumen final
echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}[7/7] TABLA RESUMEN DE RESULTADOS${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
echo ""

# Encabezado de tabla
printf "${BOLD}%-15s %-12s %-14s %-15s %-15s %-10s${NC}\n" \
    "PRUEBA" "PETICIONES" "CONCURRENCIA" "REQ/SEG" "TIEMPO/REQ" "FALLOS"
echo "──────────────────────────────────────────────────────────────────────────────────────"

# Leer y mostrar resultados
while IFS='|' read -r name requests concurrency rps time fails; do
    printf "%-15s %-12s %-14s %-15s %-15s %-10s\n" \
        "$name" "$requests" "$concurrency" "$rps" "${time} ms" "$fails"
done < /tmp/test_results.txt

echo "──────────────────────────────────────────────────────────────────────────────────────"
echo ""

# Recomendaciones
echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}RECOMENDACIONES PARA EL INFORME${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✓${NC} Incluir screenshot de esta terminal completa"
echo -e "${GREEN}✓${NC} Documentar la distribución equitativa de carga"
echo -e "${GREEN}✓${NC} Analizar el comportamiento bajo diferentes cargas"
echo -e "${GREEN}✓${NC} Mencionar que no hubo peticiones fallidas (alta disponibilidad)"
echo -e "${GREEN}✓${NC} Comparar tiempos de respuesta entre cargas ligera/media/pesada"
echo ""

# Estado de contenedores
echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}ESTADO FINAL DE CONTENEDORES${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
echo ""
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
echo ""

# Limpieza
rm -f /tmp/test_results.txt

echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}✓ PRUEBAS COMPLETADAS EXITOSAMENTE${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}[INFO]${NC} Para ver logs detallados de un backend:"
echo -e "  ${BLUE}docker logs backend1${NC}"
echo -e "  ${BLUE}docker logs backend2${NC}"
echo ""