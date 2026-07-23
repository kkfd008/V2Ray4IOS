#!/usr/bin/env bash
# =============================================================================
# V2Ray4IOS 自动化构建脚本
# =============================================================================
# 用途：一键编译 Xray-core 桥接层、构建 Xcode 项目、导出 IPA
# 环境：macOS 13.0+ / Xcode 15.0+ / Go 1.21+
#
# 用法：
#   ./scripts/build.sh [command]
#
# 命令：
#   xray      - 仅编译 XrayCore.xcframework
#   ios       - 仅编译 iOS App（Archive + Export IPA）
#   all       - 全部流程（默认）
#   clean     - 清理构建产物
#   check     - 检查环境依赖
# =============================================================================

set -euo pipefail

# ── 配置 ────────────────────────────────────────────────────────────────────
readonly PROJECT_NAME="V2RayClient"
readonly PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
readonly BUILD_DIR="${PROJECT_DIR}/.build"
readonly DERIVED_DATA="${BUILD_DIR}/DerivedData"
readonly ARCHIVE_DIR="${BUILD_DIR}/Archive"
readonly IPA_DIR="${BUILD_DIR}/IPA"
readonly XRAY_WRAPPER_DIR="${BUILD_DIR}/xray-wrapper"
readonly XCFRAMEWORK_DIR="${PROJECT_DIR}/V2RayClient/Frameworks"

readonly MAIN_TARGET="V2RayClient"
readonly EXTENSION_TARGET="PacketTunnel"
readonly MAIN_BUNDLE_ID="com.v2ray.client"
readonly EXTENSION_BUNDLE_ID="${MAIN_BUNDLE_ID}.packet-tunnel"
readonly APP_GROUP="group.com.v2ray.client"
readonly TEAM_ID="${DEVELOPMENT_TEAM:-}"
readonly IOS_VERSION="15.0"
readonly SCHEME="V2RayClient"

# 颜色
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# ── 工具函数 ────────────────────────────────────────────────────────────────

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_step()  { echo -e "\n${CYAN}════════════════════════════════════════════════════════════${NC}"; echo -e "${CYAN}  $*${NC}"; echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"; }

die() {
    log_error "$@"
    exit 1
}

# ── 环境检查 ────────────────────────────────────────────────────────────────

check_environment() {
    log_step "检查构建环境"

    local errors=0

    # 检查 macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "此脚本仅支持 macOS 环境"
        ((errors++))
    fi

    # 检查 Xcode
    if ! command -v xcodebuild &>/dev/null; then
        log_error "未找到 xcodebuild，请安装 Xcode"
        ((errors++))
    else
        log_info "xcodebuild: $(xcodebuild -version | head -1)"
    fi

    # 检查 Xcode 项目
    if [[ ! -f "${PROJECT_DIR}/V2RayClient/${PROJECT_NAME}.xcodeproj/project.pbxproj" ]]; then
        log_warn "未找到 Xcode 项目文件，请先按照 README.md 创建 Xcode 项目"
    fi

    # 检查 Go
    if ! command -v go &>/dev/null; then
        log_error "未找到 Go，请先安装 Go 1.21+"
        ((errors++))
    else
        log_info "Go: $(go version)"
    fi

    # 检查 gomobile
    if ! command -v gomobile &>/dev/null; then
        log_warn "未找到 gomobile，将自动安装"
        go install golang.org/x/mobile/cmd/gomobile@latest
        go install golang.org/x/mobile/cmd/gobind@latest
        gomobile init
    else
        log_info "gomobile: $(gomobile version 2>&1 || echo 'installed')"
    fi

    # 检查 Xray 封装层
    if [[ ! -f "${XRAY_WRAPPER_DIR}/main.go" ]]; then
        log_error "未找到 ${XRAY_WRAPPER_DIR}/main.go"
        ((errors++))
    fi

    return "$errors"
}

# ── 编译 Xray-core ──────────────────────────────────────────────────────────

build_xray_framework() {
    log_step "编译 XrayCore.xcframework"

    mkdir -p "${XCFRAMEWORK_DIR}"

    cd "${XRAY_WRAPPER_DIR}"

    # 下载依赖
    log_info "下载 Go 模块依赖..."
    go mod tidy
    go mod download

    # 编译
    log_info "开始 gomobile bind（此过程可能需要 5-15 分钟）..."
    gomobile bind \
        -target=ios \
        -iosversion="${IOS_VERSION}" \
        -o "${XCFRAMEWORK_DIR}/XrayCore.xcframework" \
        .

    if [[ -d "${XCFRAMEWORK_DIR}/XrayCore.xcframework" ]]; then
        log_info "XrayCore.xcframework 编译成功"
        log_info "输出: ${XCFRAMEWORK_DIR}/XrayCore.xcframework"
    else
        die "XrayCore.xcframework 编译失败"
    fi
}

# ── 构建 iOS App ────────────────────────────────────────────────────────────

build_ios_app() {
    log_step "构建 iOS App"

    local xcodeproj="${PROJECT_DIR}/V2RayClient/${PROJECT_NAME}.xcodeproj"

    if [[ ! -d "$xcodeproj" ]]; then
        die "未找到 Xcode 项目: ${xcodeproj}"
    fi

    # 检查 XrayCore.xcframework
    if [[ ! -d "${XCFRAMEWORK_DIR}/XrayCore.xcframework" ]]; then
        log_warn "XrayCore.xcframework 未找到，将先编译"
        build_xray_framework
    fi

    # 清理
    rm -rf "${DERIVED_DATA}" "${ARCHIVE_DIR}" "${IPA_DIR}"
    mkdir -p "${DERIVED_DATA}" "${ARCHIVE_DIR}" "${IPA_DIR}"

    # 设置 Team ID
    local team_args=""
    if [[ -n "$TEAM_ID" ]]; then
        team_args="DEVELOPMENT_TEAM=${TEAM_ID}"
    fi

    # Archive
    log_info "开始 Archive..."
    xcodebuild archive \
        -project "$xcodeproj" \
        -scheme "$SCHEME" \
        -configuration Release \
        -destination "generic/platform=iOS" \
        -derivedDataPath "${DERIVED_DATA}" \
        -archivePath "${ARCHIVE_DIR}/${PROJECT_NAME}" \
        $team_args \
        CODE_SIGN_STYLE=Automatic \
        | tee "${BUILD_DIR}/archive.log"

    if [[ ! -d "${ARCHIVE_DIR}/${PROJECT_NAME}.xcarchive" ]]; then
        die "Archive 失败，请查看 ${BUILD_DIR}/archive.log"
    fi

    log_info "Archive 成功: ${ARCHIVE_DIR}/${PROJECT_NAME}.xcarchive"

    # 导出 IPA
    log_info "开始导出 IPA..."

    local export_plist="${BUILD_DIR}/ExportOptions.plist"
    if [[ ! -f "$export_plist" ]]; then
        generate_export_plist "$export_plist"
    fi

    xcodebuild -exportArchive \
        -archivePath "${ARCHIVE_DIR}/${PROJECT_NAME}.xcarchive" \
        -exportPath "${IPA_DIR}" \
        -exportOptionsPlist "$export_plist" \
        | tee "${BUILD_DIR}/export.log"

    # 查找 IPA
    local ipa_file
    ipa_file=$(find "${IPA_DIR}" -name "*.ipa" -type f | head -1)

    if [[ -z "$ipa_file" ]]; then
        die "IPA 导出失败，请查看 ${BUILD_DIR}/export.log"
    fi

    local ipa_size
    ipa_size=$(du -h "$ipa_file" | cut -f1)

    log_info "IPA 导出成功"
    log_info "文件: ${ipa_file}"
    log_info "大小: ${ipa_size}"
}

# ── 生成 ExportOptions.plist ────────────────────────────────────────────────

generate_export_plist() {
    local output="$1"

    log_info "生成 ExportOptions.plist..."

    cat > "$output" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
    <key>compileBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <false/>
    <key>provisioningProfiles</key>
    <dict>
        <key>${MAIN_BUNDLE_ID}</key>
        <string>V2RayClient Development</string>
        <key>${EXTENSION_BUNDLE_ID}</key>
        <string>PacketTunnel Development</string>
    </dict>
</dict>
</plist>
EOF

    log_info "ExportOptions.plist 已生成: ${output}"
}

# ── 清理 ────────────────────────────────────────────────────────────────────

clean() {
    log_step "清理构建产物"

    rm -rf "${BUILD_DIR}/DerivedData"
    rm -rf "${BUILD_DIR}/Archive"
    rm -rf "${BUILD_DIR}/IPA"
    rm -f  "${BUILD_DIR}/archive.log"
    rm -f  "${BUILD_DIR}/export.log"

    log_info "清理完成"
}

clean_all() {
    clean
    log_info "清理 XrayCore.xcframework..."
    rm -rf "${XCFRAMEWORK_DIR}/XrayCore.xcframework"
    log_info "全部清理完成"
}

# ── 主流程 ──────────────────────────────────────────────────────────────────

main() {
    local cmd="${1:-all}"
    shift || true

    cd "${PROJECT_DIR}"

    case "$cmd" in
        check)
            check_environment
            log_info "环境检查通过"
            ;;
        xray)
            check_environment
            build_xray_framework
            ;;
        ios)
            build_ios_app
            ;;
        all)
            check_environment
            build_xray_framework
            build_ios_app
            ;;
        clean)
            clean
            ;;
        cleanall)
            clean_all
            ;;
        *)
            echo "用法: $(basename "$0") {check|xray|ios|all|clean|cleanall}"
            echo ""
            echo "  check    检查构建环境依赖"
            echo "  xray     仅编译 XrayCore.xcframework"
            echo "  ios      仅构建 iOS App（Archive + Export IPA）"
            echo "  all      完整构建流程（默认）"
            echo "  clean    清理构建产物"
            echo "  cleanall 清理全部产物（含 XrayCore.xcframework）"
            echo ""
            echo "环境变量:"
            echo "  DEVELOPMENT_TEAM    Apple Developer Team ID（用于签名）"
            exit 1
            ;;
    esac

    log_step "构建完成"
}

main "$@"