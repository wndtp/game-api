#!/bin/bash

# ================= 설정 항목 =================
TARGET_URL="http://localhost:3000/health"
DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/1514134537175564382/O2pDpeBtHq6L4MeWYAzfUkZrtqeJOdVwpyiWW_IrtyMWkg8bVf6cnfvq2Lm6BNXmOf3z"
SERVER_NAME="103-API-Server"
# ============================================

# API 상태 체크
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$TARGET_URL")

# 응답 코드가 200이 아니면 장애로 판단
if [ "$HTTP_STATUS" -ne 200 ]; then
    echo "[$(date)] 장애 감지! HTTP 상태 코드: $HTTP_STATUS"
    
    # 1. 장애 감지 알림
    curl -H "Content-Type: application/json" -X POST -d '{
        "embeds": [{
            "title": "🤖 [Auto-Healing] 장애 감지 및 복구 시작",
            "description": "서버: '"$SERVER_NAME"'\n상태 코드: '"$HTTP_STATUS"'\n\n❌ API 응답에 실패하여 PM2 재시작을 시도합니다.",
            "color": 16711680
        }]
    }' "$DISCORD_WEBHOOK_URL"

    # 2. PM2 프로세스 강제 재시작 (절대경로)
    /usr/bin/pm2 restart all --update-env >> /home/ubuntu/scripts/auto_heal.log 2>&1

    # 3. 15초 대기 후 부활 확인
    sleep 15
    RETRY_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$TARGET_URL")

    if [ "$RETRY_STATUS" -eq 200 ]; then
        # 4. 복구 성공 알림
        curl -H "Content-Type: application/json" -X POST -d '{
            "embeds": [{
                "title": "✅ [Auto-Healing] 복구 완료",
                "description": "서버: '"$SERVER_NAME"'\n\n👍 PM2 재시작 후 서버가 정상(HTTP 200)으로 부활했습니다!",
                "color": 65280
            }]
        }' "$DISCORD_WEBHOOK_URL"
    else
        # 5. 복구 실패 알림
        curl -H "Content-Type: application/json" -X POST -d '{
            "embeds": [{
                "title": "🚨 [Auto-Healing] 복구 실패 (초비상)",
                "description": "서버: '"$SERVER_NAME"'\n\n🔥 재시작 후에도 응답이 없습니다! 수동 점검이 필요합니다.",
                "color": 16711680
            }]
        }' "$DISCORD_WEBHOOK_URL"
    fi
fi
