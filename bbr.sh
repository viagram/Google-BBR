#!/bin/sh
# By viagram <viagram.yang@gmail.com>

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

MY_SCRIPT="$(dirname $(readlink -f $0))/$(basename $0)"

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

function Check_OS(){
    if [[ -f /etc/redhat-release ]];then
        if egrep -i "centos.*6\..*" /etc/redhat-release >/dev/null 2>&1;then
            echo 'centos6'
        elif egrep -i "centos.*7\..*" /etc/redhat-release >/dev/null 2>&1;then
            echo 'centos7'
        elif egrep -i "Red.*Hat.*6\..*" /etc/redhat-release >/dev/null 2>&1;then
            echo 'redhat6'
        elif egrep -i "Red.*Hat.*7\..*" /etc/redhat-release >/dev/null 2>&1;then
            echo 'redhat7'
        fi
    elif [[ -f /etc/issue ]];then
        if egrep -i "debian" /etc/issue >/dev/null 2>&1;then
            echo 'debian'
        elif egrep -i "ubuntu" /etc/issue >/dev/null 2>&1;then
            echo 'ubuntu'
        fi
    else
        echo 'unknown'
    fi
}

function printnew(){
    typeset -l CHK
    WENZHI=""
    RIGHT=0
    HUANHANG=0
    for PARSTR in "${@}";do
        CHK="${PARSTR}"
        if echo "${CHK}" | egrep -io "^\-[[:graph:]]*" >/dev/null 2>&1; then
            if [[ "${CHK}" == "-black" ]]; then
                COLOUR="\033[30m"
            elif [[ "${CHK}" == "-red" ]]; then
                COLOUR="\033[31m"
            elif [[ "${CHK}" == "-green" ]]; then
                COLOUR="\033[32m"
            elif [[ "${CHK}" == "-yellow" ]]; then
                COLOUR="\033[33m"
            elif [[ "${CHK}" == "-blue" ]]; then
                COLOUR="\033[34m"
            elif [[ "${CHK}" == "-purple" ]]; then
                COLOUR="\033[35m"
            elif [[ "${CHK}" == "-cyan" ]]; then
                COLOUR="\033[36m"
            elif [[ "${CHK}" == "-white" ]]; then
                COLOUR="\033[37m"
            elif [[ "${CHK}" == "-a" ]]; then
                HUANHANG=1
            elif [[ "${CHK}" == "-r" ]]; then
                RIGHT=1
            fi
        else
            WENZHI+="${PARSTR}"
        fi
    done
    COUNT=$(echo -n "${WENZHI}" | wc -L)
    if [[ ${RIGHT} -eq 1 ]];then
        tput cup $(tput lines) $[$(tput cols)-${COUNT}]
        printf "${COLOUR}%b%-${COUNT}s\033[0m" "${WENZHI}"
        tput cup $(tput lines) 0
    else
        tput cup $(tput lines) 0
        if [[ ${HUANHANG} -eq 1 ]];then
            printf "${COLOUR}%b%-${COUNT}s\033[0m" "${WENZHI}"
            tput cup $(tput lines) ${COUNT}
        else
            printf "${COLOUR}%b%-${COUNT}s\033[0m\n" "${WENZHI}"
        fi
    fi
}

function OptNET(){
    # 以前优化设置来自于网络, 具体用处嘛~~~我也不知道^_^.
    sysctl=/etc/sysctl.conf
    limits=/etc/security/limits.conf
        sed -i '/* soft nofile/d' $limits; echo '* soft nofile 512000'>>$limits
    sed -i '/* hard nofile/d' $limits; echo '* hard nofile 1024000'>>$limits
    ulimit -n 512000
    sed -i '/net.ipv4.ip_forward/d' $sysctl; echo 'net.ipv4.ip_forward=0'>>$sysctl
    sed -i '/net.ipv4.conf.default.rp_filter/d' $sysctl; echo 'net.ipv4.conf.default.rp_filter=1'>>$sysctl
    sed -i '/net.ipv4.conf.default.accept_source_route/d' $sysctl; echo 'net.ipv4.conf.default.accept_source_route=0'>>$sysctl
    sed -i '/kernel.sysrq/d' $sysctl; echo 'kernel.sysrq=0'>>$sysctl
    sed -i '/kernel.core_uses_pid/d' $sysctl; echo 'kernel.core_uses_pid=1'>>$sysctl
    sed -i '/kernel.msgmnb/d' $sysctl; echo 'kernel.msgmnb=65536'>>$sysctl
    sed -i '/kernel.msgmax/d' $sysctl; echo 'kernel.msgmax=65536'>>$sysctl
    sed -i '/kernel.shmmax/d' $sysctl; echo 'kernel.shmmax=68719476736'>>$sysctl
    sed -i '/kernel.shmall/d' $sysctl; echo 'kernel.shmall=4294967296'>>$sysctl
    sed -i '/net.ipv4.tcp_timestamps/d' $sysctl; echo 'net.ipv4.tcp_timestamps=1'>>$sysctl
    sed -i '/net.ipv4.tcp_retrans_collapse/d' $sysctl; echo 'net.ipv4.tcp_retrans_collapse=0'>>$sysctl
    sed -i '/net.ipv4.icmp_echo_ignore_broadcasts/d' $sysctl; echo 'net.ipv4.icmp_echo_ignore_broadcasts=1'>>$sysctl
    sed -i '/net.ipv4.conf.all.rp_filter/d' $sysctl; echo 'net.ipv4.conf.all.rp_filter=1'>>$sysctl
    sed -i '/fs.inotify.max_user_watches/d' $sysctl; echo 'fs.inotify.max_user_watches=65536'>>$sysctl
    sed -i '/net.ipv4.conf.default.promote_secondaries/d' $sysctl; echo 'net.ipv4.conf.default.promote_secondaries=1'>>$sysctl
    sed -i '/net.ipv4.conf.all.promote_secondaries/d' $sysctl; echo 'net.ipv4.conf.all.promote_secondaries=1'>>$sysctl
    sed -i '/kernel.hung_task_timeout_secs=0/d' $sysctl; echo 'kernel.hung_task_timeout_secs=0'>>$sysctl
    sed -i '/fs.file-max/d' $sysctl; echo 'fs.file-max=1024000'>>$sysctl
    sed -i '/net.core.wmem_max/d' $sysctl; echo 'net.core.wmem_max=67108864'>>$sysctl
    sed -i '/net.core.netdev_max_backlog/d' $sysctl; echo 'net.core.netdev_max_backlog=250000'>>$sysctl
    sed -i '/net.core.somaxconn/d' $sysctl; echo 'net.core.somaxconn=4096'>>$sysctl
    sed -i '/net.ipv4.tcp_syncookies/d' $sysctl; echo 'net.ipv4.tcp_syncookies=1'>>$sysctl
    sed -i '/net.ipv4.tcp_tw_reuse/d' $sysctl; echo 'net.ipv4.tcp_tw_reuse=1'>>$sysctl
    sed -i '/net.ipv4.tcp_fin_timeout/d' $sysctl; echo 'net.ipv4.tcp_fin_timeout=30'>>$sysctl
    sed -i '/net.ipv4.tcp_keepalive_time/d' $sysctl; echo 'net.ipv4.tcp_keepalive_time=1200'>>$sysctl
    sed -i '/net.ipv4.ip_local_port_range/d' $sysctl; echo 'net.ipv4.ip_local_port_range=10000'>>$sysctl
    sed -i '/net.ipv4.tcp_max_syn_backlog/d' $sysctl; echo 'net.ipv4.tcp_max_syn_backlog=8192'>>$sysctl
    sed -i '/net.ipv4.tcp_max_tw_buckets/d' $sysctl; echo 'net.ipv4.tcp_max_tw_buckets=5000'>>$sysctl
    sed -i '/net.ipv4.tcp_fastopen/d' $sysctl; echo 'net.ipv4.tcp_fastopen=3'>>$sysctl
    sed -i '/net.ipv4.tcp_rmem/d' $sysctl; echo 'net.ipv4.tcp_rmem=4096'>>$sysctl
    sed -i '/net.ipv4.tcp_wmem/d' $sysctl; echo 'net.ipv4.tcp_wmem=4096'>>$sysctl
    sed -i '/net.ipv4.tcp_mtu_probing/d' $sysctl; echo 'net.ipv4.tcp_mtu_probing=1'>>$sysctl
    sysctl -p
}

function CHK_ELREPO(){
    printnew -a -green "检查elrepo安装源... "
    if ! yum list installed elrepo-release >/dev/null 2>&1;then
        printnew -r -red "失败"
        printnew -a -green "导入elrepo密钥... "
        #if ! rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org >/dev/null 2>&1; then
        if ! rpm --import http://www.elrepo.org/RPM-GPG-KEY-elrepo.org >/dev/null 2>&1; then
            printnew -r -red "失败"
            exit 1
        else
            printnew -r -green "成功"
        fi
        printnew -a -green "安装elrepo-releases... "
        if [[ "$(Check_OS)" == "centos7" || "$(Check_OS)" == "redhat7" ]]; then
            #if ! rpm -Uvh https://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm >/dev/null 2>&1; then
            if ! rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm >/dev/null 2>&1; then
                printnew -r -red "失败"
                exit 1
            else
                printnew -r -green "成功"
            fi
        elif [[ "$(Check_OS)" == "centos6" || "$(Check_OS)" == "redhat6" ]]; then
            #if ! rpm -Uvh https://www.elrepo.org/elrepo-release-6-8.el6.elrepo.noarch.rpm >/dev/null 2>&1; then
            if ! rpm -Uvh http://www.elrepo.org/elrepo-release-6-8.el6.elrepo.noarch.rpm >/dev/null 2>&1; then
                printnew -r -red "失败"
                exit 1
            else
                printnew -r -green "成功"
            fi
        else
            printnew -r -red "失败, 暂不支持该系统"
        fi
    else
        printnew -r -green "通过"
    fi
}

function CHK_BBR(){
    BBR_KO="/lib/modules/$(uname -r)/kernel/net/ipv4/tcp_nanqinlang.ko"
    if [[ -e "${BBR_KO}" ]]; then
        printnew -green "魔改bbr模块tcp_nanqinlang已安装. "
        if lsmod | grep nanqinlang >/dev/null 2>&1; then
            printnew -green "魔改bbr模块tcp_nanqinlang运行. "
            return 0
        else
            sed -i '/net\.core\.default_qdisc/d' /etc/sysctl.conf
            echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
            sed -i '/net\.ipv4\.tcp_congestion_control/d' /etc/sysctl.conf
            echo "net.ipv4.tcp_congestion_control=nanqinlang" >> /etc/sysctl.conf
            sysctl -p
            insmod ${BBR_KO}
            depmod -a
            if lsmod | grep nanqinlang >/dev/null 2>&1; then
                printnew -green "魔改bbr模块tcp_nanqinlang启动成功. "
                return 0
            else
                printnew -red "魔改bbr模块tcp_nanqinlang启动失败."
                return 1
            fi
        fi
    else
        return 1
    fi
}

function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; } #大于
function version_ge() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"; } #大于或等于
function version_lt() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1"; } #小于
function version_le() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" == "$1"; } #小于或等于

# Check If You Are Root
if [[ $EUID -ne 0 ]]; then
    printnew -red "错误: 必须以root权限运行此脚本! "
    exit 1
fi

#####################################################################################

if [[ "$(Check_OS)" != "centos7" && "$(Check_OS)" != "centos6" && "$(Check_OS)" != "redhat7" && "$(Check_OS)" != "redhat6" ]]; then
    printnew -red "目前仅支持CentOS6,7及Redhat6,7系统."
    exit 1
else
    typeset -l REINSTALL
    REINSTALL="${1}"
    if [[ -n "${REINSTALL}" && "${REINSTALL}" == "install" ]]; then
        #删除二次登陆启动项
        if egrep -i "${MY_SCRIPT}" ~/.bashrc >/dev/null 2>&1; then
            MY_SCRIPT2=${MY_SCRIPT//\//\\/}
            sed -i "/${MY_SCRIPT2}/d" ~/.bashrc
        fi
        printnew -green "将进行[魔改bbr模块]二次安装进程."
        read -p "输入[y/n]选择是否继续, 默认为y：" is_go
        [[ -z "${is_go}" ]] && is_go='y'
        if [[ ${is_go} != "y" && ${is_go} != "Y" ]]; then
            printnew -red "用户取消, 程序终止."
            exit 0
        fi
    else
        if ! CHK_BBR >/dev/null 2>&1;then
            printnew -green "将进行[魔改bbr模块]首次安装进程."
            read -p "输入[y/n]选择是否继续, 默认为y：" is_go
            [[ -z "${is_go}" ]] && is_go='y'
            if [[ ${is_go} != "y" && ${is_go} != "Y" ]]; then
                printnew -red "用户取消, 程序终止."
                exit 0
            fi
        else
            printnew -green "将进行[魔改bbr模块]安装检测."
            read -p "输入[y/n]选择是否继续, 默认为y：" is_go
            [[ -z "${is_go}" ]] && is_go='y'
            if [[ ${is_go} != "y" && ${is_go} != "Y" ]]; then
                printnew -red "用户取消, 程序终止."
                exit 0
            fi
        fi
    fi
    printnew -a -green "检测系统架构... "
    if ! command -v virt-what >/dev/null 2>&1; then
        yum install -y virt-what >/dev/null 2>&1
    fi
    if [[ "$(virt-what)" == "openvz" ]]; then
        printnew -r -red "不支持openvz架构"
        exit 1
    else
        printnew -r -green "通过"
    fi
    if [[ "$(uname -m)" != "x86_64" ]]; then
        printnew -red "目前仅支持x86_64架构."
    fi
    #检测内核
    CHK_ELREPO
    printnew -a -green "检测系统内核... "
    if [[ "$(Check_OS)" == "centos7" || "$(Check_OS)" == "redhat7" ]]; then
        BIT=7
    fi
    if [[ "$(Check_OS)" == "centos6" || "$(Check_OS)" == "redhat6" ]]; then
        BIT=6
    fi
    if ! command -v curl >/dev/null 2>&1; then
        yum install -y curl >/dev/null 2>&1
    fi

    GET_INFO=$(echo N | yum --enablerepo=elrepo-kernel install kernel-ml)
    echo ${GET_INFO} | egrep -io '/tmp/[[:graph:]]*[yumtx]' | xargs rm -f
    KERNEL_NET=$(echo ${GET_INFO} | egrep -io '[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}-[0-9]{1,3}' | sort -Vu)
    KERNEL_VER=$(uname -r | egrep -io '^[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}-[0-9]{1,3}')
    function UP_KERNEL(){
        if rpm -qa | egrep -i "kernel" | egrep -i "headers" >/dev/null 2>&1;then
            printnew -green "为避免冲突, 正在删除旧版本的kernel-headers... "
            rpm -qa | egrep -i "kernel" | egrep -i "headers" | xargs yum remove -y
        fi
        #注意: ml为最新版本的内核, lt为长期支持的内核. 建议安装ml版本. https://elrepo.org/linux/kernel/el7/x86_64/RPMS/
        printnew -green "安装最新版本ml内核... "
        if ! yum --enablerepo=elrepo-kernel -y install kernel-ml kernel-ml-devel kernel-ml-headers; then
            printnew -red "内核安装失败."
            exit 1
        else
            printnew -green "内核安装成功."
        fi
        printnew -green "正在设置新内核的启动顺序... "
        if [[ "$(Check_OS)" == "centos7" || "$(Check_OS)" == "redhat7" ]]; then
            grub2-mkconfig -o /boot/grub2/grub.cfg >/dev/null 2>&1
            grub2-set-default 0 >/dev/null 2>&1
        fi
        if [[ "$(Check_OS)" == "centos6" || "$(Check_OS)" == "redhat6" ]]; then
            #sed -i "s/^default.*/default=0/" /boot/grub/grub.conf
            kernel_default=$(grep '^title ' /boot/grub/grub.conf | awk -F'title ' '{print i++ " : " $2}' | grep "${NET_KERNEL}" | grep -v debug | cut -d' ' -f1 | head -n 1)
            sed -i "s/^default.*/default=${kernel_default}/" /boot/grub/grub.conf >/dev/null 2>&1
        fi
        if ! egrep -i "${MY_SCRIPT}" ~/.bashrc >/dev/null 2>&1; then
            echo "sh ${MY_SCRIPT} install">>~/.bashrc
        fi
        printnew -green "设置成功, 请重启系统后再次执行安装. "
        read -p "输入[y/n]选择是否重启, 默认为y：" is_reboot
        [[ -z "${is_reboot}" ]] && is_reboot='y'
        if [[ ${is_reboot} == "y" || ${is_reboot} == "Y" ]]; then
            reboot
            exit 0
        else
            exit 0
        fi
    }
    if version_gt ${KERNEL_NET} '4.10.0'; then
        printnew -r -green "通过"
    else
        printnew -r -red "失败"
        printnew -green "内核过旧, 升级内核... "
        UP_KERNEL
    fi
    #判断是否有新的内核
    if version_gt ${KERNEL_NET} ${KERNEL_VER}; then
        printnew -green "当前内核: ${KERNEL_VER}"
        printnew -green "最新内核: ${KERNEL_NET} "
        printnew -green "检测到有新的内核, 是否升级? "
        read -p "输入[y/n]选择, 默认为y：" is_upkernel
        [[ -z "${is_upkernel}" ]] && is_upkernel='y'
        if [[ ${is_upkernel} == "y" || ${is_upkernel} == "Y" ]]; then
            UP_KERNEL
        else
            printnew -red "你选择不升级内核, 程序终止. "
            exit 0
        fi
    else
        if lsmod | grep nanqinlang >/dev/null 2>&1; then
            printnew -green "系统内核已是最新版本. "
        fi
    fi

    #检测模块状态
    if CHK_BBR; then
        exit 0
    fi
    
    #更新启动配置并删除其它内核
    if rpm -qa | grep kernel | grep -v "${KERNEL_VER}" >/dev/null 2>&1;then
        printnew -green "删除其它老旧内核... "
        rpm -qa | grep kernel | grep -v "${KERNEL_VER}" | xargs yum remove -y
    fi
    
    #安装必备组件
    printnew -green "安装必备组件包... "
    yum groupinstall -y "Development Tools"
    yum install -y libtool gcc gcc-c++ wget
    #下载并编译模块
    if [[ ! -d make_tmp ]]; then
        mkdir make_tmp
    fi
    cd make_tmp
    printnew -green "将安装[魔改bbr模块], 是否继续? "
    read -p "输入[y/n]选择, 默认为y：" is_InstallBBR
    [[ -z "${is_InstallBBR}" ]] && is_InstallBBR='y'
    if [[ ${is_InstallBBR} == "y" || ${is_InstallBBR} == "Y" ]]; then
        printnew -a -green "下载魔改bbr源码..."
        if ! wget -O tcp_nanqinlang.c https://raw.githubusercontent.com/viagram/Google-BBR/master/tcp_nanqinlang.c --no-check-certificate >/dev/null 2>&1;then
            printnew -r -red "下载失败"
            exit 1
        else
            printnew -r -green "下载成功"
        fi
    else
        printnew -red "你选择不安装bbr, 程序终止. "
        exit 0
    fi
    printnew -a -green "下载Makefile..."
    if ! wget -O Makefile https://raw.githubusercontent.com/viagram/Google-BBR/master/Makefile-CentOS --no-check-certificate >/dev/null 2>&1;then
        printnew -r -red "下载失败" 
        exit 1
    else
        printnew -r -green "下载成功"
    fi
    printnew -a -green "编译并安装魔改方案... "
    if make >/dev/null 2>&1; then
        if make install >/dev/null 2>&1; then
            printnew -r -green "安装成功"
            printnew -a -green "优化并启用魔改方案... "
            OptNET >/dev/null 2>&1
            if CHK_BBR >/dev/null 2>&1; then
                printnew -r -green "启动成功"
            else
                printnew -r -red "启动失败"
                exit 1
            fi
        else
            printnew -r -red "安装失败"
            exit 1
        fi
    else
        printnew -r -red "编译失败"
        exit 1
    fi
    cd - >/dev/null 2>&1
    rm -rf make_tmp
fi
