#!/bin/bash
# ROS2 설치 스크립트 (우분투 버전 자동 감지)

set -e

echo "=========================================="
echo "ROS2 설치 시작"
echo "=========================================="

source /etc/os-release
UBUNTU_VERSION=$VERSION_CODENAME
ARCH=$(dpkg --print-architecture)

# 명시적 ROS_DISTRO 옵션 처리
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

# 명시적으로 지정되지 않았으면 우분투 버전으로 감지
if [ -z "$ROS_DISTRO" ]; then
    echo "[1/6] 우분투 버전 확인 중..."
    echo "감지된 버전: $UBUNTU_VERSION"

    # 버전별 ROS2 매핑
    case $UBUNTU_VERSION in
        focal)
            ROS_DISTRO="foxy"
            echo "Ubuntu 20.04 (Focal) -> ROS2 Foxy 설치"
            ;;
        jammy)
            ROS_DISTRO="humble"
            echo "Ubuntu 22.04 (Jammy) -> ROS2 Humble 설치"
            ;;
        noble)
            ROS_DISTRO="jazzy"
            echo "Ubuntu 24.04 (Noble) -> ROS2 Jazzy 설치"
            ;;
        *)
            echo "지원하지 않는 우분투 버전: $UBUNTU_VERSION"
            echo "지원 버전: focal, jammy, noble"
            exit 1
            ;;
    esac
else
    echo "[1/6] 명시적으로 지정된 ROS_DISTRO 사용: $ROS_DISTRO"
fi

if [ "$ROS_DISTRO" = "jazzy" ] && [ "$ARCH" = "armhf" ]; then
    echo "Jazzy는 armhf 아키텍처를 지원하지 않습니다. (현재: $ARCH)"
    echo "Ubuntu 24.04에서는 arm64 아키텍처를 사용하거나 배포판을 변경하세요."
    exit 1
fi

# 저장소 설정
echo "[2/6] ROS2 저장소 설정 중..."
sudo apt-get install -y curl gnupg lsb-release ca-certificates
sudo mkdir -p /usr/share/keyrings
curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key | sudo gpg --dearmor --yes -o /usr/share/keyrings/ros-archive-keyring.gpg
sudo chmod a+r /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $UBUNTU_VERSION main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

# 시스템 업데이트
echo "[3/7] 시스템 업데이트 중..."
sudo apt-get update
sudo apt-get upgrade -y || true

# 패키지 상태 복구
echo "[4/7] 패키지 상태 복구 중..."
sudo dpkg --configure -a
sudo apt-get install -f -y
sudo apt-get full-upgrade -y

# 로케일 설정
echo "[5/7] 로케일 설정 중..."
sudo apt-get install -y locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

# ROS2 설치
echo "[6/7] ROS2 $ROS_DISTRO 설치 중..."
sudo apt-get update
if ! sudo apt-get install -y ros-$ROS_DISTRO-ros-core; then
    echo "ROS2 설치 실패. 패키지 상태 진단 정보를 출력합니다."
    sudo apt-mark showhold || true
    apt-cache policy zlib1g zlib1g-dev | sed -n '1,40p' || true
    apt-cache policy ros-$ROS_DISTRO-tracetools ros-$ROS_DISTRO-rmw-cyclonedds-cpp | sed -n '1,80p' || true
    echo "권장 조치: sudo apt-get install -f -y ; sudo apt-get full-upgrade -y ; sudo apt autoremove -y"
    exit 1
fi

echo "[7/7] 환경 설정 중..."
echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> ~/.bashrc

echo "=========================================="
echo "ROS2 $ROS_DISTRO 설치 완료!"
echo "=========================================="
