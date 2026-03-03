#!/bin/bash
# Python 의존성 설치 스크립트

set -e

echo "=========================================="
echo "Python 의존성 설치 시작"
echo "=========================================="

# 아키텍처 감지
ARCH=$(dpkg --print-architecture)
echo "감지된 아키텍처: $ARCH"

# ROS_DISTRO 감지 함수
detect_ros_distro() {
    for distro in jazzy humble foxy; do
        if [ -f "/opt/ros/$distro/setup.bash" ]; then
            echo "$distro"
            return 0
        fi
    done
    echo "humble"
}

# 옵션 처리
ROS_DISTRO=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --distro)
            ROS_DISTRO="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# 명시적으로 지정되지 않았으면 감지
if [ -z "$ROS_DISTRO" ]; then
    ROS_DISTRO=$(detect_ros_distro)
    echo "감지된 ROS 배포판: $ROS_DISTRO"
else
    echo "명시적으로 지정된 ROS 배포판: $ROS_DISTRO"
fi

if [ ! -f "/opt/ros/$ROS_DISTRO/setup.bash" ]; then
    echo "에러: /opt/ros/$ROS_DISTRO/setup.bash를 찾을 수 없습니다. 먼저 ROS2를 설치하세요."
    exit 1
fi
source /opt/ros/$ROS_DISTRO/setup.bash

echo "[1/2] pip 환경 확인 중..."
python3 -m pip --version >/dev/null

echo "[2/2] 프로젝트 Python 의존성 설치 중..."
# robot_perception 패키지의 requirements.txt가 있으면 설치
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/robot_workspace"

if [ -f "$WORKSPACE_DIR/src/robot_perception/requirements.txt" ]; then
    echo "robot_perception 의존성 설치 중..."
    python3 -m pip install --break-system-packages -r "$WORKSPACE_DIR/src/robot_perception/requirements.txt"
fi

# 공통 Python 패키지 (ARM 아키텍처에 맞춰 설치)
echo "공통 Python 패키지 설치 중..."

# ARM 아키텍처 (라즈베리파이 등)는 최적화 플래그와 함께 설치
if [[ "$ARCH" == "armv7l" || "$ARCH" == "aarch64" ]]; then
    echo "ARM 아키텍처 감지: Raspberry Pi 최적화 설치 시작..."
    
    # 환경 변수 설정 - ARM CPU 최적화
    export OPENBLAS_CORETYPE=ARMV7
    export CFLAGS="-fPIC"
    
    # 기본 패키지 설치
    python3 -m pip install --break-system-packages --upgrade pip wheel setuptools
    
    # NumPy 호환 버전 (소스 컴파일)
    python3 -m pip install --break-system-packages --no-cache-dir "numpy==1.23.5"
    
    # OpenCV
    python3 -m pip install --break-system-packages --no-cache-dir "opencv-contrib-python==4.7.0.72"
    
    # SciPy, Matplotlib
    python3 -m pip install --break-system-packages --no-cache-dir scipy matplotlib
    
    # PyTorch + YOLO (ARMv7l/aarch64 최적화)
    echo "PyTorch ARM 버전 설치 중..."
    if [ "$ARCH" == "armv7l" ]; then
        # ARMv7l: 소스 컴파일 옵션 포함
        python3 -m pip install --break-system-packages --no-cache-dir --no-binary :all: \
            "torch==2.0.1" "torchvision==0.15.2" --index-url https://download.pytorch.org/whl/armv7l
    else
        # aarch64 (Raspberry Pi 4/5)
        python3 -m pip install --break-system-packages --no-cache-dir \
            "torch==2.0.1" "torchvision==0.15.2" --index-url https://download.pytorch.org/whl/cpu
    fi
    
    # Ultralytics YOLO (특정 호환 버전)
    echo "설치 중: ultralytics==8.0.156 (라즈베리파이 호환 버전)..."
    if ! python3 -m pip install --break-system-packages --no-cache-dir "ultralytics==8.0.156" 2>/dev/null; then
        echo "⚠️ ultralytics==8.0.156 설치 실패. 대체 버전 설치 중..."
        python3 -m pip uninstall -y ultralytics torch torchvision --break-system-packages 2>/dev/null || true
        python3 -m pip install --break-system-packages --no-cache-dir "ultralytics==8.0.0"
    fi
else
    # x86_64 또는 다른 아키텍처는 표준 설치
    python3 -m pip install --break-system-packages \
        "numpy<2" \
        scipy \
        matplotlib \
        opencv-python \
        torch \
        torchvision \
        ultralytics
fi

echo "==========================================="
echo "Python 의존성 설치 완료!"
echo "=========================================="
