# entrypoint.sh
#!/bin/sh
set -e

echo "📦 워크플로우 import 중..."
n8n import:workflow --input=/home/node/news.json

echo "🚀 n8n 서버 시작..."
exec n8n start