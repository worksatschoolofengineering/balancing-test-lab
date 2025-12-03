bash
#!/bin/bash

echo "═══════════════════════════════════════════════"
echo "SCREENSHOTS COMPLEMENTARIOS - LABORATORIO"
echo "═══════════════════════════════════════════════"
echo ""

echo "[1/4] IPs de contenedores y pruebas directas"
echo "─────────────────────────────────────────────"
echo ""

# Obtener IPs
BACKEND1_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' backend1)
BACKEND2_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' backend2)

echo "🔵 Backend 1 IP: $BACKEND1_IP"
curl -s http://$BACKEND1_IP
echo ""
echo ""

echo "🟢 Backend 2 IP: $BACKEND2_IP"
curl -s http://$BACKEND2_IP
echo ""
echo ""

echo "[2/4] Prueba de alternancia via balanceador"
echo "─────────────────────────────────────────────"
for i in {1..10}; do
    echo -n "Petición $i: "
    curl -s http://localhost:8080 | grep -o "Backend [12]"
done
echo ""
echo ""

echo "[3/4] Estado de contenedores"
echo "─────────────────────────────────────────────"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo ""

echo "[4/4] Configuración actual del balanceador"
echo "─────────────────────────────────────────────"
cat ~/lab-docker/loadbalancer/default.conf
echo ""
echo ""

echo "═══════════════════════════════════════════════"
echo "✓ Screenshots complementarios listos"
echo "═══════════════════════════════════════════════"
echo ""
echo "PENDIENTES:"
echo "  • Screenshot de navegador en http://$(hostname -I | awk '{print $1}'):8080/"
echo "  • Screenshot de 'docker stats' mientras corre 'ab'"
