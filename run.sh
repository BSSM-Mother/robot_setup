#!/bin/bash
# 라즈베리파이 자동 설정 메인 스크립트

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}라즈베리파이 로봇 시스템 자동 설정${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""

# 함수: 스크립트 실행 확인
run_script() {
    local script_name=$1
    local script_path="$SCRIPT_DIR/$script_name"
    
    if [ ! -f "$script_path" ]; then
        echo -e "${RED}오류: $script_path를 찾을 수 없습니다${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}실행: $script_name${NC}"
    chmod +x "$script_path"
    
    # 첫 번째 전달 인자가 있으면 전달
    if [ -n "$2" ]; then
        bash "$script_path" "$2"
    else
        bash "$script_path"
    fi
    echo ""
}

# 옵션 처리
SKIP_ROS2=false
SKIP_SYSTEM=false
SKIP_ROSDEP=false
SKIP_PYTHON=false
SKIP_BUILD=false
AUTO_LAUNCH=false
REPO_URL=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-ros2)
            SKIP_ROS2=true
            shift
            ;;
        --skip-system)
            SKIP_SYSTEM=true
            shift
            ;;
        --skip-rosdep)
            SKIP_ROSDEP=true
            shift
            ;;
        --skip-python)
            SKIP_PYTHON=true
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --launch)
            AUTO_LAUNCH=true
            shift
            ;;
        --repo)
            REPO_URL="$2"
            shift 2
            ;;
        --help)
            echo "사용법: $0 [옵션]"
            echo ""
            echo "옵션:"
            echo "  --skip-ros2       ROS2 설치 건너뛰기"
            echo "  --skip-system     시스템 의존성 설치 건너뛰기"
            echo "  --skip-rosdep     ROS 의존성 설치 건너뛰기"
            echo "  --skip-python     Python 의존성 설치 건너뛰기"
            echo "  --skip-build      워크스페이스 빌드 건너뛰기"
            echo "  --launch          빌드 후 시스템 자동 실행"
            echo "  --repo <url>      레포지토리 URL 지정 (기본: bitbyte08/robot_workspace)"
            echo "  --help            이 도움말 표시"
            exit 0
            ;;
        *)
            echo -e "${RED}알 수 없는 옵션: $1${NC}"
            exit 1
            ;;
    esac
done

# 서로 다른 단계 실행
if [ "$SKIP_ROS2" = false ]; then
    run_script "ros2_install.sh" || { echo -e "${RED}ROS2 설치 실패${NC}"; exit 1; }
else
    echo -e "${YELLOW}건너뜀: ROS2 설치${NC}"
fi

if [ "$SKIP_SYSTEM" = false ]; then
    run_script "system_dependencies.sh" || { echo -e "${RED}시스템 의존성 설치 실패${NC}"; exit 1; }
else
    echo -e "${YELLOW}건너뜀: 시스템 의존성 설치${NC}"
fi

if [ "$SKIP_ROSDEP" = false ]; then
    run_script "ros_dependencies.sh" || { echo -e "${RED}ROS 의존성 설치 실패${NC}"; exit 1; }
else
    echo -e "${YELLOW}건너뜀: ROS 의존성 설치${NC}"
fi

if [ "$SKIP_PYTHON" = false ]; then
    run_script "python_dependencies.sh" || { echo -e "${RED}Python 의존성 설치 실패${NC}"; exit 1; }
else
    echo -e "${YELLOW}건너뜀: Python 의존성 설치${NC}"
fi

if [ "$SKIP_BUILD" = false ]; then
    run_script "workspace_build.sh" "$REPO_URL" || { echo -e "${RED}워크스페이스 빌드 실패${NC}"; exit 1; }
else
    echo -e "${YELLOW}건너뜀: 워크스페이스 빌드${NC}"
fi

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}✓ 모든 설정 완료!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""

# 자동 실행 옵션
if [ "$AUTO_LAUNCH" = true ]; then
    echo -e "${YELLOW}시스템 실행 준비 중...${NC}"
    
    # ROS_DISTRO 감지 및 환경 로드
    ROS_DISTRO=$(detect_ros_distro)
    WORKSPACE_DIR="$(cd "${SCRIPT_DIR}/../robot_workspace" && pwd)"
    
    # 환경 변수 설정
    source /opt/ros/$ROS_DISTRO/setup.bash
    source "$WORKSPACE_DIR/install/setup.bash"
    
    echo -e "${GREEN}로봇 시스템 시작 중...${NC}"
    echo ""
    ros2 launch robot_launch system.launch.py
else
    echo "다음 단계:"
    echo "1. 터미널을 다시 열거나 다음 명령 실행:"
    echo "   source ~/.bashrc"
    echo ""
    echo "2. 로봇 시스템 시작:"
    echo "   source ~/robot_workspace/install/setup.bash"
    echo "   ros2 launch robot_launch system.launch.py"
    echo ""
    echo "또는 한 명령으로:"
    echo "   bash $SCRIPT_DIR/run.sh --launch"
    echo ""
