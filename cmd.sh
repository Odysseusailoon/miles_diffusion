echo "=== ci-monitor oracle ==="
BASE=https://ci-monitor-1.tail134ba0.ts.net
echo "-- control: h100-novita5-gpu --"
curl -sk --max-time 30 "$BASE/api/runner/disk?runner=h100-novita5-gpu" -w "\nHTTP:%{http_code}\n" | head -40
echo "-- RX: h100-novita-temp (85.234.79.233) --"
curl -sk --max-time 30 "$BASE/api/runner/disk?runner=h100-novita-temp" -w "\nHTTP:%{http_code}\n" | head -60
echo "-- http80 fallback control --"
curl -s --max-time 20 "http://ci-monitor-1.tail134ba0.ts.net/api/runner/disk?runner=h100-novita5-gpu" -w "\nHTTP:%{http_code}\n" | head -20
echo "=== B18DONE ==="
