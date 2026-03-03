#!/bin/bash
# Robot ROS2 Systemd Service 설치 스크립트

set -e

# 옵션 처리 (호환성을 위해)
while [[ $# -gt 0 ]]; do
    case $1 in
        --distro)
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

echo "=========================================="
echo "Robot ROS2 Systemd Service 설치"
echo "=========================================="

# 현재 스크립트 디렉토리
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_FILE="$SCRIPT_DIR/robot_ros.service"
CURRENT_USER="${SUDO_USER:-$USER}"

if [ ! -f "$SERVICE_FILE" ]; then
    echo "오류: $SERVICE_FILE를 찾을 수 없습니다"
    exit 1
fi

echo "[1/4] Service 파일 권한 설정 중..."
chmod 644 "$SERVICE_FILE"

echo "[2/4] Service 파일을 systemd로 복사 중..."
sed "s|__USER__|$CURRENT_USER|g" "$SERVICE_FILE" | sudo tee /etc/systemd/system/robot_ros.service > /dev/null

echo "사용자: $CURRENT_USER"

echo "[3/4] Systemd 데몬 새로고침 중..."
sudo systemctl daemon-reload

echo "[4/4] Service 활성화 중..."
sudo systemctl enable robot_ros.service

echo ""
echo "=========================================="
echo "✓ Service 설치 완료!"
echo "=========================================="
echo ""
echo "사용법:"
echo "  시작:     sudo systemctl start robot_ros"
echo "  중지:     sudo systemctl stop robot_ros"
echo "  재시작:   sudo systemctl restart robot_ros"
echo "  상태:     sudo systemctl status robot_ros"
echo "  로그:     sudo journalctl -u robot_ros -f"
echo ""
echo "부팅 시 자동 시작 설정됨"
echo ""
