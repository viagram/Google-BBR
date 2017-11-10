#!/bin/sh
# By viagram <viagram.yang@gmail.com>

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

MY_SCRIPT="$(dirname $(readlink -f $0))/$(basename $0)"

echo -e "\033[33m"
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

# Check If You Are Root
if [[ $EUID -ne 0 ]]; then
    printnew -red "错误: 必须以root权限运行此脚本! "
    exit 1
fi

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
    sed -i 's/* soft nofile[[:print:]]*/* soft nofile 512000/g' $limits
    sed -i 's/* hard nofile[[:print:]]*/* hard nofile 1024000/g' $limits
    ulimit -n 512000
    sed -i "s/net.ipv4.ip_forward[[:print:]]*/net.ipv4.ip_forward=0/g" $sysctl
    sed -i "s/net.ipv4.conf.default.rp_filter[[:print:]]*/net.ipv4.conf.default.rp_filter=1/g" $sysctl
    sed -i "s/net.ipv4.conf.default.accept_source_route[[:print:]]*/net.ipv4.conf.default.accept_source_route=0/g" $sysctl
    sed -i "s/kernel.sysrq[[:print:]]*/kernel.sysrq=0/g" $sysctl
    sed -i "s/kernel.core_uses_pid[[:print:]]*/kernel.core_uses_pid=1/g" $sysctl
    sed -i "s/kernel.msgmnb[[:print:]]*/kernel.msgmnb=65536/g" $sysctl
    sed -i "s/kernel.msgmax[[:print:]]*/kernel.msgmax=65536/g" $sysctl
    sed -i "s/kernel.shmmax[[:print:]]*/kernel.shmmax=68719476736/g" $sysctl
    sed -i "s/kernel.shmal[[:print:]]*/kernel.shmall=4294967296/g" $sysctl
    sed -i "s/net.ipv4.tcp_timestamps[[:print:]]*/net.ipv4.tcp_timestamps=1/g" $sysctl
    sed -i "s/net.ipv4.tcp_retrans_collapse[[:print:]]*/net.ipv4.tcp_retrans_collapse=0/g" $sysctl
    sed -i "s/net.ipv4.icmp_echo_ignore_broadcasts[[:print:]]*/net.ipv4.icmp_echo_ignore_broadcasts=1/g" $sysctl
    sed -i "s/net.ipv4.conf.all.rp_filter[[:print:]]*/net.ipv4.conf.all.rp_filter=1/g" $sysctl
    sed -i "s/fs.inotify.max_user_watches[[:print:]]*/fs.inotify.max_user_watches=65536/g" $sysctl
    sed -i "s/net.ipv4.conf.default.promote_secondaries[[:print:]]*/net.ipv4.conf.default.promote_secondaries=1/g" $sysctl
    sed -i "s/net.ipv4.conf.all.promote_secondaries[[:print:]]*/net.ipv4.conf.all.promote_secondaries=1/g" $sysctl
    sed -i "s/kernel.hung_task_timeout_secs[[:print:]]*/kernel.hung_task_timeout_secs=0/g" $sysctl
    sed -i "s/fs.file-max[[:print:]]*/fs.file-max=1024000/g" $sysctl
    sed -i "s/net.core.wmem_max[[:print:]]*/net.core.wmem_max=67108864/g" $sysctl
    sed -i "s/net.core.netdev_max_backlog[[:print:]]*/net.core.netdev_max_backlog=250000/g" $sysctl
    sed -i "s/net.core.somaxconn[[:print:]]*/net.core.somaxconn=4096/g" $sysctl
    sed -i "s/net.ipv4.tcp_syncookies[[:print:]]*/net.ipv4.tcp_syncookies=1/g" $sysctl
    sed -i "s/net.ipv4.tcp_tw_reuse[[:print:]]*/net.ipv4.tcp_tw_reuse=1/g" $sysctl
    sed -i "s/net.ipv4.tcp_fin_timeout[[:print:]]*/net.ipv4.tcp_fin_timeout=30/g" $sysctl
    sed -i "s/net.ipv4.tcp_keepalive_time[[:print:]]*/net.ipv4.tcp_keepalive_time=1200/g" $sysctl
    sed -i "s/net.ipv4.ip_local_port_range[[:print:]]*/net.ipv4.ip_local_port_range=10000/g" $sysctl
    sed -i "s/net.ipv4.tcp_max_syn_backlog[[:print:]]*/net.ipv4.tcp_max_syn_backlog=8192/g" $sysctl
    sed -i "s/net.ipv4.tcp_max_tw_buckets[[:print:]]*/net.ipv4.tcp_max_tw_buckets=5000/g" $sysctl
    sed -i "s/net.ipv4.tcp_fastopen[[:print:]]*/net.ipv4.tcp_fastopen=3/g" $sysctl
    sed -i "s/net.ipv4.tcp_rmem[[:print:]]*/net.ipv4.tcp_rmem=4096/g" $sysctl
    sed -i "s/net.ipv4.tcp_wmem[[:print:]]*/net.ipv4.tcp_wmem=4096/g" $sysctl
    sed -i "s/net.ipv4.tcp_mtu_probing[[:print:]]*/net.ipv4.tcp_mtu_probing=1/g" $sysctl
    sed -i "s/net.core.default_qdisc[[:print:]]*/net.core.default_qdisc=fq_codel/g" $sysctl
    sed -i "s/net.ipv4.tcp_congestion_control[[:print:]]*/net.ipv4.tcp_congestion_control=nanqinlang/g" $sysctl
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
    if [[ -f "/lib/modules/$(uname -r)/kernel/net/ipv4/tcp_nanqinlang.ko" ]]; then
        printnew -green "魔改bbr模块tcp_nanqinlang已安装. "
        if lsmod | grep nanqinlang >/dev/null 2>&1; then
            printnew -green "魔改bbr模块tcp_nanqinlang运行. "
            return 0
        else
            sed -i '/net\.ipv4\.tcp_congestion_control/d' /etc/sysctl.conf
            echo "net.ipv4.tcp_congestion_control=nanqinlang" >> /etc/sysctl.conf
            sysctl -p
            if lsmod | grep nanqinlang >/dev/null 2>&1; then
                printnew -green "魔改bbr模块tcp_nanqinlang启动成功. "
                return 0
            else
                printnew -red "魔改bbr模块tcp_nanqinlang启动失败."
                return 0
            fi
        fi
    else
        return 1
    fi
}
#####################################################################################

if [[ "$(Check_OS)" != "centos7" && "$(Check_OS)" != "centos6" && "$(Check_OS)" != "redhat7" && "$(Check_OS)" != "redhat6" ]]; then
    printnew -red "目前仅支持CentOS6,7及Redhat6,7系统."
    exit 1
else
    typeset -l REINSTALL
    REINSTALL="${1}"
    if [[ -n "${REINSTALL}" && "${REINSTALL}" == "install" ]]; then
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
            printnew -green "将进行[魔改bbr模块]检测进程."
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
    #删除二次登陆启动项
    if egrep -i "${MY_SCRIPT}" ~/.bashrc >/dev/null 2>&1; then
        MY_SCRIPT2=${MY_SCRIPT//\//\\/}
        sed -i "/${MY_SCRIPT2}/d" ~/.bashrc
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
    KERNEL_NET=$(echo ${GET_INFO} | egrep -io '[0-9]{1}\.[0-9]{1,2}\.[0-9]{1,2}[-$]' | egrep -io '[0-9]{1}\.[0-9]{1,2}\.[0-9]{1,2}' | head -n1)
    YUMLOG_TMP=$(echo ${GET_INFO} | egrep -io '/tmp/[[:graph:]]*[yumtx]')
    rm -f "${YUMLOG_TMP}"
    VERSION_X=$(echo ${KERNEL_NET} | awk -F '.' '{print $1}')
    VERSION_Y=$(echo ${KERNEL_NET} | awk -F '.' '{print $2}')
    VERSION_Z=$(echo ${KERNEL_NET} | awk -F '.' '{print $3}')
    KERNEL_VER=$(uname -r | egrep -io '^[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}')
    VERSION_A=$(echo ${KERNEL_VER} | awk -F '.' '{print $1}')
    VERSION_B=$(echo ${KERNEL_VER} | awk -F '.' '{print $2}')
    VERSION_C=$(echo ${KERNEL_VER} | awk -F '.' '{print $3}')
    function UP_KERNEL(){
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
        printnew -green "初始化成功, 请重启系统后再次执行安装. "
        read -p "输入[y/n]选择是否重启, 默认为y：" is_reboot
        [[ -z "${is_reboot}" ]] && is_reboot='y'
        if [[ ${is_reboot} == "y" || ${is_reboot} == "Y" ]]; then
            reboot
            exit 0
        else
            exit 0
        fi
    }
    if [[ ${VERSION_A} -ge 4 && ${VERSION_B} -ge 10 && ${VERSION_C} -gt 0 ]]; then
        printnew -r -green "通过"
    else
        printnew -r -red "失败"
        printnew -green "内核过旧, 升级内核... "
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
        UP_KERNEL
    fi
    #判断是否有新的内核
    if [[ ${VERSION_X} -ge ${VERSION_A} && ${VERSION_Y} -ge ${VERSION_B} && ${VERSION_Z} -gt ${VERSION_C} ]]; then
        printnew -green "检测到有新的内核, 是否升级? "
        read -p "输入[y/n]选择, 默认为y：" is_upkernel
        [[ -z "${is_upkernel}" ]] && is_upkernel='y'
        if [[ ${is_upkernel} == "y" || ${is_upkernel} == "Y" ]]; then
            if rpm -qa | egrep -i "kernel" | egrep -i "headers" >/dev/null 2>&1;then
                printnew -green "为避免冲突, 正在删除旧版本的kernel-headers... "
                rpm -qa | egrep -i "kernel" | egrep -i "headers" | xargs yum remove -y
            fi
            if ! yum --enablerepo=elrepo-kernel -y update kernel-ml kernel-ml-devel kernel-ml-headers; then
                printnew -red "升级内核失败."
                exit 1
            fi
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
    printnew -green "请选择你想要的魔改方案:\n    1.温和模式\n    2.暴力模式"
    read -p "输入[1/2]以选择相应模式. 默认为1: " mode
    [[ -z "${mode}" ]] && mode=1
    while [[ ! "${mode}" =~ ^[1-2]$ ]]
    do
        printnew -red "无效输入."
        printnew "请重新选择" && read -p "输入数字以选择:" mode
    done
    printnew -a -green "下载魔改bbr源码..."
    case "${mode}" in
        1)
            if ! wget -O tcp_nanqinlang.c https://raw.githubusercontent.com/viagram/Google-BBR/master/tcp_nanqinlang-gentle.c --no-check-certificate >/dev/null 2>&1;then
                printnew -r -red "下载失败"
                exit 1
            else
                printnew -r -green "下载成功"
            fi
            ;;
        2)
            if ! wget -O tcp_nanqinlang.c https://raw.githubusercontent.com/viagram/Google-BBR/master/tcp_nanqinlang-violent.c --no-check-certificate >/dev/null 2>&1;then
                printnew -r -red "下载失败"
                exit 1
            else
                printnew -r -green "下载成功"
            fi
            ;;
        *)
            printnew -r -red "出错了哦~~"
            ;;
    esac
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
            if lsmod | grep nanqinlang >/dev/null 2>&1; then
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
