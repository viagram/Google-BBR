#!/bin/bash
# By viagram <viagram.yang@gmail.com>

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

zsph="/usr/bin/bbr"
myph="$(dirname $(readlink -f $0))/$(basename $0)"
MY_SCRIPT="${zsph}"

echo -ne "\033[33m"
cat <<'EOF'
###################################################################
#                     _                                           #
#              __   _(_) __ _  __ _ _ __ __ _ _ __ ___            #
#              \ \ / / |/ _` |/ _` | '__/ _` | '_ ` _ \           #
#               \ V /| | (_| | (_| | | | (_| | | | | | |          #
#                \_/ |_|\__,_|\__, |_|  \__,_|_| |_| |_|          #
#                             |___/                               #
#                                                                 #
###################################################################
EOF
echo -e "\033[0m"


function printnew(){
    typeset -l CHK
    content=''
    colour=''
    br=0
    for line in "${@}"; do
        echo "${line}" | egrep -iq '^\-[[:graph:]]*' && {
            case "${line}" in
                -black) colour="\033[30m";;
                -red) colour="\033[31m";;
                -green) colour="\033[32m";;
                -yellow) colour="\033[33m";;
                -blue) colour="\033[34m";;
                -purple) colour="\033[35m";;
                -cyan) colour="\033[36m";;
                -white) colour="\033[37m";;
                -a) br=1;;
                *) colour="\033[37m";;
            esac
        } || content+="${line}"
    done
    [[ ${br} -eq 1 ]] && echo -en "${colour}${content}\033[0m" || echo -e "${colour}${content}\033[0m"
}

# Check If You Are Root
if [[ $EUID -ne 0 ]]; then
    printnew -red "错误: 必须以root权限运行此脚本! "
    exit 1
fi
 
function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1";} #大于
function version_ge() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1";} #大于或等于
function version_lt() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1";} #小于
function version_le() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" == "$1";} #小于或等于

function chk_what(){
    printnew -a -green "检测系统架构: "
    if ! which virt-what >/dev/null 2>&1; then
        ${CMD} install -y virt-what >/dev/null 2>&1
    fi
    if [[ "$(virt-what)" == "openvz" ]]; then
        printnew -red "不支持openvz架构"
        exit 1
    else
        if [[ "$(uname -m)" != "x86_64" ]]; then
            printnew -red "目前仅支持x86_64架构."
            exit 1
        else
            printnew -green "通过"
        fi
    fi
}

function Check_OS(){
    Text=$(cat /etc/*-release)
    echo ${Text} | egrep -iq "(centos[a-z ]*5|red[a-z ]*hat[a-z ]*5)" && echo centos5 && return
    echo ${Text} | egrep -iq "(centos[a-z ]*6|red[a-z ]*hat[a-z ]*6)" && echo centos6 && return
    echo ${Text} | egrep -iq "(centos[a-z ]*7|red[a-z ]*hat[a-z ]*7)" && echo centos7 && return
    echo ${Text} | egrep -iq "(centos[a-z ]*8|red[a-z ]*hat[a-z ]*8)" && echo centos8 && return
    echo ${Text} | egrep -iq "(Rocky[a-z ]*8|red[a-z ]*hat[a-z ]*8)" && echo rockylinux8 && return
    echo ${Text} | egrep -iq "debian[a-z /]*[0-9]{1,2}" && echo debian && return
    echo ${Text} | egrep -iq "Fedora[a-z ]*[0-9]{1,2}" && echo fedora && return
    echo ${Text} | egrep -iq "OpenWRT[a-z ]*" && echo openwrt && return
    echo ${Text} | egrep -iq "ubuntu[[:space:]]*20\." && echo ubuntu20 && return
    echo ${Text} | egrep -iq "ubuntu" && echo ubuntu && return
}

function OptNET(){
    # 以前优化设置来自于网络, 具体用处嘛~~~我也不知道^_^.
    sysctl=/etc/sysctl.conf
    limits=/etc/security/limits.conf
    sed -i '/* soft nofile/d' $limits;echo '* soft nofile 1024000'>>$limits
    sed -i '/* hard nofile/d' $limits;echo '* hard nofile 1024000'>>$limits
    echo "ulimit -SHn 1024000">>/etc/profile
    ulimit -n 512000
    sed -i '/net.ipv4.ip_forward/d' $sysctl;echo 'net.ipv4.ip_forward=1'>>$sysctl
    sed -i '/net.ipv4.conf.default.rp_filter/d' $sysctl;echo 'net.ipv4.conf.default.rp_filter=1'>>$sysctl
    sed -i '/net.ipv4.conf.default.accept_source_route/d' $sysctl;echo 'net.ipv4.conf.default.accept_source_route=0'>>$sysctl
    sed -i '/kernel.sysrq/d' $sysctl;echo 'kernel.sysrq=0'>>$sysctl
    sed -i '/kernel.core_uses_pid/d' $sysctl;echo 'kernel.core_uses_pid=1'>>$sysctl
    sed -i '/kernel.msgmnb/d' $sysctl;echo 'kernel.msgmnb=65536'>>$sysctl
    sed -i '/kernel.msgmax/d' $sysctl;echo 'kernel.msgmax=65536'>>$sysctl
    sed -i '/kernel.shmmax/d' $sysctl;echo 'kernel.shmmax=68719476736'>>$sysctl
    sed -i '/kernel.shmall/d' $sysctl;echo 'kernel.shmall=4294967296'>>$sysctl
    sed -i '/net.ipv4.tcp_timestamps/d' $sysctl;echo 'net.ipv4.tcp_timestamps=0'>>$sysctl
    sed -i '/net.ipv4.tcp_retrans_collapse/d' $sysctl;echo 'net.ipv4.tcp_retrans_collapse=0'>>$sysctl
    sed -i '/net.ipv4.icmp_echo_ignore_broadcasts/d' $sysctl;echo 'net.ipv4.icmp_echo_ignore_broadcasts=1'>>$sysctl
    sed -i '/net.ipv4.conf.all.rp_filter/d' $sysctl;echo 'net.ipv4.conf.all.rp_filter=1'>>$sysctl
    sed -i '/fs.inotify.max_user_watches/d' $sysctl;echo 'fs.inotify.max_user_watches=65536'>>$sysctl
    sed -i '/net.ipv4.conf.default.promote_secondaries/d' $sysctl;echo 'net.ipv4.conf.default.promote_secondaries=1'>>$sysctl
    sed -i '/net.ipv4.conf.all.promote_secondaries/d' $sysctl;echo 'net.ipv4.conf.all.promote_secondaries=1'>>$sysctl
    sed -i '/kernel.hung_task_timeout_secs=0/d' $sysctl;echo 'kernel.hung_task_timeout_secs=0'>>$sysctl
    sed -i '/fs.file-max/d' $sysctl;echo 'fs.file-max=1024000'>>$sysctl
    sed -i '/net.core.wmem_max/d' $sysctl;echo 'net.core.wmem_max=67108864'>>$sysctl
    sed -i '/net.core.netdev_max_backlog/d' $sysctl;echo 'net.core.netdev_max_backlog=32768'>>$sysctl
    sed -i '/net.core.somaxconn/d' $sysctl;echo 'net.core.somaxconn=32768'>>$sysctl
    sed -i '/net.ipv4.tcp_syncookies/d' $sysctl;echo 'net.ipv4.tcp_syncookies=1'>>$sysctl
    sed -i '/net.ipv4.tcp_tw_reuse/d' $sysctl;echo 'net.ipv4.tcp_tw_reuse=1'>>$sysctl
    sed -i '/net.ipv4.tcp_fin_timeout/d' $sysctl;echo 'net.ipv4.tcp_fin_timeout=30'>>$sysctl
    sed -i '/net.ipv4.tcp_keepalive_time/d' $sysctl;echo 'net.ipv4.tcp_keepalive_time=1200'>>$sysctl
    sed -i '/net.ipv4.ip_local_port_range/d' $sysctl;echo 'net.ipv4.ip_local_port_range=1024 65500'>>$sysctl
    sed -i '/net.ipv4.tcp_max_syn_backlog/d' $sysctl;echo 'net.ipv4.tcp_max_syn_backlog=8192'>>$sysctl
    sed -i '/net.ipv4.tcp_max_tw_buckets/d' $sysctl;echo 'net.ipv4.tcp_max_tw_buckets=6000'>>$sysctl
    sed -i '/net.ipv4.tcp_fastopen/d' $sysctl;echo 'net.ipv4.tcp_fastopen=3'>>$sysctl
    sed -i '/net.ipv4.tcp_rmem/d' $sysctl;echo 'net.ipv4.tcp_rmem=4096'>>$sysctl
    sed -i '/net.ipv4.tcp_wmem/d' $sysctl;echo 'net.ipv4.tcp_wmem=4096'>>$sysctl
    sed -i '/net.ipv4.tcp_mtu_probing/d' $sysctl;echo 'net.ipv4.tcp_mtu_probing=1'>>$sysctl
    sed -i '/net.ipv4.tcp_ecn/d' $sysctl;echo 'net.ipv4.tcp_ecn=1'>>$sysctl
    sed -i '/net.ipv4.tcp_ecn_fallback/d' $sysctl;echo 'net.ipv4.tcp_ecn_fallback=1'>>$sysctl
    sysctl -p
    sleep 1
}

function check_elrepo(){
    printnew -a -green "检查elrepo安装源: "
    if ! ${CMD} list installed elrepo-release >/dev/null 2>&1; then
        printnew -red "失败"
        printnew -a -green "导入elrepo密钥: "
        if ! rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org >/dev/null 2>&1; then
        #if ! rpm --import http://www.elrepo.org/RPM-GPG-KEY-elrepo.org >/dev/null 2>&1; then
            printnew -red "失败"
            exit 1
        else
            printnew -green "成功"
        fi
        printnew -a -green "安装elrepo-releases: "
        if [[ "$(Check_OS)" == "centos8" || "$(Check_OS)" == "rockylinux8" ]]; then
            if ! rpm -Uvh https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm >/dev/null 2>&1; then
            #if ! rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm >/dev/null 2>&1; then
                printnew -red "失败"
                exit 1
            else
                printnew -green "成功"
            fi
        elif [[ "$(Check_OS)" == "centos7" ]]; then
            if ! rpm -Uvh https://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm >/dev/null 2>&1; then
            #if ! rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm >/dev/null 2>&1; then
                printnew -red "失败"
                exit 1
            else
                printnew -green "成功"
            fi
        elif [[ "$(Check_OS)" == "centos6" ]]; then
            if ! rpm -Uvh https://www.elrepo.org/elrepo-release-6-8.el6.elrepo.noarch.rpm >/dev/null 2>&1; then
            #if ! rpm -Uvh http://www.elrepo.org/elrepo-release-6-8.el6.elrepo.noarch.rpm >/dev/null 2>&1; then
                printnew -red "失败"
                exit 1
            else
                printnew -green "成功"
            fi
        else
            printnew -red "失败, 暂不支持该系统"
        fi
    else
        printnew -green "通过"
    fi
}

function check_bbr(){
    if lsmod | grep tcp_bbr >/dev/null 2>&1; then
        printnew -green " [Google BBR] 模块运行中. "
        return 0
    else
        printnew -red " [Google BBR] 模块没有运行. "
        return 1
    fi
}

function apply_bbr(){
    if check_bbr; then
        printnew -green " [Google BBR] 模块运行中. "
        return 0
    else
        sed -i '/net\.core\.default_qdisc/d' /etc/sysctl.conf
        echo 'net.core.default_qdisc=fq' >> /etc/sysctl.conf
        sed -i '/net\.ipv4\.tcp_congestion_control/d' /etc/sysctl.conf
        echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf
        sysctl -p >/dev/null 2>&1
        if check_bbr; then
            printnew -green " [Google BBR] 模块启动成功. "
            return 0
        else
            printnew -red " [Google BBR] 模块启动失败."
            return 1
        fi
    fi
}

function uninstall_bbr(){
    if check_bbr >/dev/null 2>&1; then
        sed -i '/net\.core\.default_qdisc=/d'          /etc/sysctl.conf
        sed -i '/net\.ipv4\.tcp_congestion_control=/d' /etc/sysctl.conf
        sysctl -p >/dev/null 2>&1
        sleep 1
        printnew -green "删除成功, 请重启系统以停止 [Google BBR] 模块."
        read -p "输入[y/n]以选择是否重启系统. 默认为y: " yn_reboot
        [[ -z "${yn_reboot}" ]] && yn_reboot=y
        while [[ ! "${yn_reboot}" =~ ^[YyNn]$ ]]; do
            printnew -red "无效输入."
            read -p "请重新输入: " yn_reboot
        done
        if [[ ${yn_reboot} =~ ^[Yy]$ ]]; then
            printnew -green "重启系统中: "
            sleep 1
            reboot
        fi
    else
        printnew -red "检测到系统没有安装 [Google BBR] 模块. "
    fi
}

function update_kernel(){
    if rpm -qa | egrep -i "kernel" | egrep -i "headers" >/dev/null 2>&1; then
        printnew -green "为避免冲突, 正在删除旧版本的kernel-headers: "
        rpm -qa | egrep -i "kernel" | egrep -i "headers" | xargs ${CMD} remove -y
    fi
    #注意: ml为最新版本的内核, lt为长期支持的内核. 建议安装ml版本. https://elrepo.org/linux/kernel/el7/x86_64/RPMS/
    if [[ "$(Check_OS)" == "centos6" ]]; then
        kernel_upver='4.18.20-1'
        if version_ge "$(uname -r | egrep -io '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}-[0-9]{1,3}')" "${kernel_upver}"; then
            printnew -green "暂无可升级的新版本内核."
            return
        fi
        printnew -green -a "安装${kernel_upver}版本内核: "
        if ! rpm -Uvh https://github.com/viagram/Google-BBR/raw/master/kernel-ml-${kernel_upver}.el6.elrepo.x86_64.rpm >/dev/null 2>&1; then
            printnew -red "失败"
            exit 1
        else
            printnew -green "成功"
        fi
        printnew -green -a  "安装${kernel_upver}版本devel: "
        if ! rpm -Uvh https://github.com/viagram/Google-BBR/raw/master/kernel-ml-devel-${kernel_upver}.el6.elrepo.x86_64.rpm>/dev/null 2>&1; then
            printnew -red "失败"
            exit 1
        else
            printnew -green "成功"
        fi
        printnew -green -a "安装${kernel_upver}版本headers: "
        if ! rpm -Uvh https://github.com/viagram/Google-BBR/raw/master/kernel-ml-headers-${kernel_upver}.el6.elrepo.x86_64.rpm >/dev/null 2>&1; then
            printnew -red "失败"
            exit 1
        else
            printnew -green "成功"
        fi
    elif [[ "$(Check_OS)" == "centos7" ]]; then
        printnew -green "安装最新版本ml内核: "
        if ! ${CMD} --enablerepo=elrepo-kernel -y install kernel-ml kernel-ml-devel kernel-ml-headers; then
            printnew -red "内核安装失败."
            exit 1
        else
            printnew -green "内核安装成功."
        fi
    elif [[ "$(Check_OS)" == "centos8" ||  "$(Check_OS)" == "rockylinux8" ]]; then
        printnew -green "安装最新版本ml内核: "
        if ! ${CMD} --enablerepo=elrepo-kernel -y install kernel-ml kernel-ml-devel kernel-ml-headers; then
            printnew -red "内核安装失败."
            exit 1
        else
            printnew -green "内核安装成功."
        fi
    fi
    printnew -green -a "正在设置新内核的启动顺序: "
    if [[ "$(Check_OS)" == "centos7" || "$(Check_OS)" == "centos8" || "$(Check_OS)" == "rockylinux8" ]]; then
        if [[ -f /boot/grub/grub.conf ]]; then
            kernel_list=$(cat /boot/grub/grub.conf | egrep -io "CentOS Linux[[:print:]]*\(core\)")
            kernel_ver=$(echo "${kernel_list}" | egrep -io '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}-[0-9]{1,3}' | sort -Vur | head -n1)
            kernel_default=$(egrep '^title ' /boot/grub/grub.conf | awk -F'title ' '{print i++ " : " $2}' | egrep  -i ${kernel_ver} | egrep -v debug | awk '{print $1}' | head -n 1)
            sed -i "s/^default.*/default=${kernel_default}/" /boot/grub/grub.conf >/dev/null 2>&1
            printnew -yellow "成功. "
        else
            if ! which grub2-mkconfig >/dev/null 2>&1; then
                ${CMD} remove -y grub2-tools-minimal
                ${CMD} install -y grub2-tools
            fi
            grub_cfg="";
            [[ -f /boot/grub2/grub.cfg ]] && grub_cfg=/boot/grub2/grub.cfg
            [[ -z ${grub_cfg} ]] && [[ -f /boot/efi/EFI/centos/grub.cfg ]] && grub_cfg=/boot/efi/EFI/centos/grub.cfg
            [[ -z ${grub_cfg} ]] && (printnew -red "没找linux启动文件.";exit 1)
            grub2-mkconfig -o ${grub_cfg} >/dev/null 2>&1
            grub2-mkconfig -o /boot/grub2/grub.cfg >/dev/null 2>&1
            kernel_list=$(cat ${grub_cfg} | egrep -io "CentOS Linux[[:print:]]*\(core\)")
            kernel_ver=$(echo "${kernel_list}" | egrep -io '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}-[0-9]{1,3}' | sort -Vur | head -n1)
            kernel_name=$(echo "${kernel_list}" | egrep -i ${kernel_ver} | sort -Vur | head -n1)
            grub2-set-default "${kernel_name}"
            kernel_now=$(grub2-editenv list | awk -F '=' '{print $2}')
            if test "${kernel_name}" == "${kernel_now}"; then
                printnew -yellow "成功. "
                printnew -green "最新内核: ${kernel_name}"
                printnew -green "默认内核: ${kernel_now}"
            else
                printnew -red "失败. "
                exit 1
            fi
        fi
    fi
    if [[ "$(Check_OS)" == "centos6" ]]; then
        #sed -i "s/^default.*/default=0/" /boot/grub/grub.conf
        kernel_default=$(egrep '^title ' /boot/grub/grub.conf | awk -F'title ' '{print i++ " : " $2}' | egrep "${NET_KERNEL}" | egrep -v debug | awk '{print $1}' | head -n 1)
        sed -i "s/^default.*/default=${kernel_default}/" /boot/grub/grub.conf >/dev/null 2>&1
        printnew -yellow "成功. "
    fi
    if ! egrep -i "${MY_SCRIPT}" ~/.bashrc >/dev/null 2>&1; then
        echo "sh ${MY_SCRIPT} install">>~/.bashrc
    fi
    [[ ${grub_cfg} == "/boot/efi/EFI/centos/grub.cfg" ]] && ${CMD} install -y efibootmgr >/dev/null 2>&1
    printnew -green "设置成功, 请重启系统后再次执行安装. "
    read -p "输入[y/n]选择是否重启, 默认为y：" is_reboot
    [[ -z "${is_reboot}" ]] && is_reboot='y'
    if [[ ${is_reboot} =~ ^[Yy]$ ]]; then
        reboot -f
        exit 0
    else
        exit 0
    fi
}

function chk_kernel(){
    printnew -a -green "检测系统内核: "
    if ! which curl >/dev/null 2>&1; then
        ${CMD} install -y curl >/dev/null 2>&1
    fi
    if [[ "$(Check_OS)" == "centos6" ]]; then
        kernel_bs="lt"
    elif [[ "$(Check_OS)" == "centos7" ]]; then
        kernel_bs="ml"
    fi
    KERNEL_NET=$(${CMD} --enablerepo=elrepo-kernel list kernel-${kernel_bs} | egrep -io '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}-[0-9]{1,3}' | sort -Vur | head -n1)
    KERNEL_VER=$(uname -r | egrep -io '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}-[0-9]{1,3}')

    if version_gt ${KERNEL_VER} '5.9.0'; then
        printnew -green "通过"
        #判断是否有新的内核
        printnew -green -a "当前内核: "
        printnew -yellow ${KERNEL_VER}
        printnew -green -a "最新内核: "
        printnew -yellow ${KERNEL_NET}
        if version_gt ${KERNEL_NET} ${KERNEL_VER}; then
            printnew -green "检测到有新的内核, 是否升级? "
            read -p "输入[y/n]选择, 默认为y：" is_upkernel
            [[ -z "${is_upkernel}" ]] && is_upkernel='y'
            if [[ ${is_upkernel} =~ ^[Yy]$ ]]; then
                update_kernel
            else
                printnew -red "你选择不升级内核, 程序终止. "
                exit 0
            fi
        else
            printnew -green "系统内核已是最新版本. "
        fi
    else
        printnew -red "失败"
        if version_lt ${KERNEL_NET} '4.9.0'; then
            if [[ "$(Check_OS)" == "centos6" ]]; then
                printnew -green "尝试升级内核."
                update_kernel
            else
                printnew -red "暂无支持Google BBR的内核版本."
                exit 1
            fi
        else
            printnew -green "内核过旧, 升级内核."
            update_kernel
        fi
    fi
}
#####################################################################################
if [[ "$(Check_OS)" != "rockylinux8" && "$(Check_OS)" != "centos8" && "$(Check_OS)" != "centos7" && "$(Check_OS)" != "centos6" ]]; then
    printnew -red "目前仅支持(CentOS|Redhat)6,7,8及rockylinux8系统."
    exit 1
else
    [[ "$(Check_OS)" == "rockylinux8" || "$(Check_OS)" == "centos8" ]] && CMD=dnf
    [[ "$(Check_OS)" == "centos6" || "$(Check_OS)" == "centos7" ]] && CMD=yum
    zsph="/usr/bin/bbr"
    myph="$(dirname $(readlink -f $0))/$(basename $0)"
    if [[ -f ${myph} ]]; then
        if [[ ${myph} != ${zsph} ]]; then
            echo -e "\033[32m    安装路径: ${zsph}\033[0m"
            cp -rf ${myph} ${zsph}
            chmod +x ${zsph}
            rm -rf ${myph}
        fi
    fi
    typeset -l REINSTALL
    REINSTALL="${1}"
    if [[ -n "${REINSTALL}" && "${REINSTALL}" == "install" ]]; then
        printnew -green "将进行 [Google BBR] 模块二次安装进程."
        read -p "输入[y/n]选择是否继续, 默认为y：" is_go
        [[ -z "${is_go}" ]] && is_go='y'
        if [[ ! ${is_go} =~ ^[Yy]$ ]]; then
            printnew -red "用户取消, 程序终止."
            exit 0
        fi
    else
        printnew -green "请输入数字进行选择."
        printnew -green "   1, 安装 [Google BBR] 模块"
        printnew -green "   2, 查看 [Google BBR] 状态"
        printnew -green "   3, 删除 [Google BBR] 模块"
        read -p "输入[1/2/3]以选择相应模式. 默认为1: " mode
        [[ -z "${mode}" ]] && mode=1
        #while [[ ! "${forceinstall}" =~ ^[YyNn]$ ]]; do
        while [[ ! "${mode}" =~ ^[1-3]$ ]]; do
            printnew -red "无效输入."
            read -p "请重新输入数字以选择: " mode
        done
        if [[ ${mode} -eq 3 ]]; then
            if check_bbr >/dev/null 2>&1; then
                printnew -green "删除 [Google BBR] 模块中: "
                uninstall_bbr
            else
                printnew -red "检测到系统没有安装 [Google BBR] 模块. "
            fi
            exit 0
        fi
        if [[ ${mode} -eq 2 ]]; then
            # 查看 [Google BBR] 状态
            check_bbr
            exit 0
        fi
    fi

    #检测系统架构
    chk_what
    #检测内核
    check_elrepo
    ${CMD} -y remove qemu-guest-agent
    chk_kernel
    
    #删除二次登陆启动项
    if egrep -i "${MY_SCRIPT}" ~/.bashrc >/dev/null 2>&1; then
        MY_SCRIPT2=${MY_SCRIPT//\//\\/}
        sed -i "/${MY_SCRIPT2}/d" ~/.bashrc
    fi
    
    #更新启动配置并删除其它内核
    if rpm -qa | grep kernel | grep -v "$(uname -r)" >/dev/null 2>&1; then
        printnew -green "删除其它老旧内核: "
        rpm -qa | grep kernel | grep -v "$(uname -r)" | xargs ${CMD} remove -y
        cd /lib/modules/
        ls | grep -v $(uname -r) | xargs rm -rf
        cd - >/dev/null 2>&1
    fi

    if check_bbr >/dev/null 2>&1; then
        printnew "\033[41;37m提示: \033[0m\033[32m检测到 [Google BBR] 模块已在运行中. "
        exit 0
    else
        printnew -green "进行[ [Google BBR] 模块]安装进程: "
    fi
    
    printnew -a -green "优化并启用 [Google BBR] : "
    OptNET >/dev/null 2>&1
    if apply_bbr >/dev/null 2>&1; then
        printnew -green "启动成功"
    else
        printnew -red "启动失败"
    fi
fi
