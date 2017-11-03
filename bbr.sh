#!/bin/sh
# By viagram <viagram.yang@gmail.com>

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

MY_SCRIPT="$(dirname $(readlink -f $0))/$(basename $0)"

# Check If You Are Root
if [[ $EUID -ne 0 ]]; then
    clear
    echo -e "\033[31m    错误: 必须以root权限运行此脚本!\033[0m"
    exit 1
fi

function Check_OS(){
    if [[ -f /etc/redhat-release ]];then
        if egrep -i "centos.*6\..*" /etc/redhat-release >/dev/null 2>&1;then
            echo 'centos6'
        elif egrep -i "centos.*7\..*" /etc/redhat-release >/dev/null 2>&1;then
            echo 'centos7'
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

function CHK_ELREPO(){
    if ! yum list installed elrepo-release >/dev/null 2>&1;then
        echo -e "\033[32m    导入elrepo密钥中... \033[0m"
        if ! rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org; then
            if ! rpm --import http://www.elrepo.org/RPM-GPG-KEY-elrepo.org; then
                echo -e "\033[31m    导入elrepo密钥失败.\033[0m"
                exit 1
            fi
        fi
        echo -e "\033[32m    安装elrepo-releases中... \033[0m"
        if [[ "$(Check_OS)" == "centos7" ]]; then
            if ! rpm -Uvh https://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm; then
                if ! rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm; then
                    echo -e "\033[31m    安装elrepo-releases失败.\033[0m"
                    exit 1
                fi
            fi
        elif [[ "$(Check_OS)" == "centos6" ]]; then
            echo -e "\033[32m    安装elrepo-releases中... \033[0m"
            if ! rpm -Uvh https://www.elrepo.org/elrepo-release-6-8.el6.elrepo.noarch.rpm; then
                if ! rpm -Uvh http://www.elrepo.org/elrepo-release-6-8.el6.elrepo.noarch.rpm; then
                    echo -e "\033[31m    安装elrepo-releases失败.\033[0m"
                    exit 1
                fi
            fi
        fi
    fi
}

#####################################################################################

if [[ "$(Check_OS)" != "centos7" && "$(Check_OS)" != "centos6" ]]; then
    echo -e "\033[31m    目前仅支持CentOS系统.\033[0m"
    exit 1
else
    echo -e "\033[32m    检测系统架构... \033[0m"
    if ! command -v virt-what >/dev/null 2>&1; then
        yum install -y virt-what >/dev/null 2>&1
    fi
    #删除二次登陆启动项
    if egrep -i "${MY_SCRIPT}" ~/.bashrc >/dev/null 2>&1; then
        MY_SCRIPT2=${MY_SCRIPT//\//\\/}
        sed -i "/${MY_SCRIPT2}/d" ~/.bashrc
    fi
    if [[ "$(virt-what)" == "openvz" ]]; then
        echo -e "\033[31m    不支持openvz架构.\033[0m"
        exit 1
    fi
    if [[ "$(uname -m)" != "x86_64" ]]; then
        echo -e "\033[31m    目前仅支持x86_64架构.\033[0m"
    fi
    #检测内核
    CHK_ELREPO
    echo -e "\033[32m    检测系统内核... \033[0m"
    if [[ "$(Check_OS)" == "centos7" ]]; then
        BIT=7
    fi
    if [[ "$(Check_OS)" == "centos6" ]]; then
        BIT=6
    fi
    if ! command -v curl >/dev/null 2>&1; then
        echo -e "\033[32m    安装 curl 中... \033[0m"
        yum install -y curl
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
        echo -e "\033[32m    正在设置新内核的启动顺序... \033[0m"
        if [[ "$(Check_OS)" == "centos7" ]]; then
            grub2-mkconfig -o /boot/grub2/grub.cfg >/dev/null 2>&1
            grub2-set-default 0 >/dev/null 2>&1
        fi
        if [[ "$(Check_OS)" == "centos6" ]]; then
            #sed -i "s/^default.*/default=0/" /boot/grub/grub.conf
            kernel_default=$(grep '^title ' /boot/grub/grub.conf | awk -F'title ' '{print i++ " : " $2}' | grep "${NET_KERNEL}" | grep -v debug | cut -d' ' -f1 | head -n 1)
            sed -i "s/^default.*/default=${kernel_default}/" /boot/grub/grub.conf >/dev/null 2>&1
        fi
        if ! egrep -i "${MY_SCRIPT}" ~/.bashrc >/dev/null 2>&1; then
            echo "sh ${MY_SCRIPT}">>~/.bashrc
        fi
        echo -e "\033[32m    内核升级成功, 请重启系统后再次执行安装. \033[0m"
        read -p "    输入[y/n]选择是否重启, 默认为y：" is_reboot
        [[ -z "${is_reboot}" ]] && is_reboot='y'
        if [[ ${is_reboot} == "y" || ${is_reboot} == "Y" ]]; then
            reboot
            exit 0
        else
            exit 0
        fi
    }
    if [[ ${VERSION_A} -ge 4 && ${VERSION_B} -ge 10 && ${VERSION_C} -gt 0 ]]; then
        echo -e "\033[32m    内核检测通过. \033[0m"
    else
        echo -e "\033[31m    内核过旧, 升级内核中... \033[0m"
        echo -e "\033[32m    为避免冲突, 正在删除旧版本的kernel-headers... \033[0m"
        rpm -qa | egrep -i "kernel" | egrep -i "headers" | xargs yum remove -y
        #注意: ml为最新版本的内核, lt为长期支持的内核. 建议安装ml版本. https://elrepo.org/linux/kernel/el7/x86_64/RPMS/
        echo -e "\033[32m    安装最新版本ml内核中... \033[0m"
        if ! yum --enablerepo=elrepo-kernel -y install kernel-ml kernel-ml-devel kernel-ml-headers; then
            echo -e "\033[31m    安装最新版本ml内核失败.\033[0m"
            exit 1
        fi
        UP_KERNEL
    fi
    #判断是否有新的内核
    if [[ ${VERSION_X} -ge ${VERSION_A} && ${VERSION_Y} -ge ${VERSION_B} && ${VERSION_Z} -gt ${VERSION_C} ]]; then
        echo -e "\033[32m    检测到有新的内核, 是否升级? \033[0m"
        read -p "    输入[y/n]选择, 默认为y：" is_upkernel
        [[ -z "${is_upkernel}" ]] && is_upkernel='y'
        if [[ ${is_upkernel} == "y" || ${is_upkernel} == "Y" ]]; then
            echo -e "\033[32m    为避免冲突, 正在删除旧版本的kernel-headers... \033[0m"
            rpm -qa | egrep -i "kernel" | egrep -i "headers" | xargs yum remove -y
            if ! yum --enablerepo=elrepo-kernel -y update kernel-ml kernel-ml-devel kernel-ml-headers; then
                echo -e "\033[31m   升级内核失败.\033[0m"
                exit 1
            fi
            UP_KERNEL
        else
            echo -e "\033[32m    你选择不升级内核, 程序终止. \033[0m"
            exit 0
        fi
    else
        if lsmod | grep nanqinlang >/dev/null 2>&1; then
            echo -e "\033[32m    系统内核已是最新版本. \033[0m"
        fi
    fi

    #检测模块状态
    if [[ -f "/lib/modules/$(uname -r)/kernel/net/ipv4/tcp_nanqinlang.ko" ]]; then
        echo -e "\033[32m    魔改bbr模块tcp_nanqinlang已安装. \033[0m"
        if lsmod | grep nanqinlang >/dev/null 2>&1; then
            echo -e "\033[32m    魔改bbr模块tcp_nanqinlang运行中. \033[0m"
            exit 0
        else
            sed -i '/net\.ipv4\.tcp_congestion_control/d' /etc/sysctl.conf
            echo "net.ipv4.tcp_congestion_control=nanqinlang" >> /etc/sysctl.conf
            sysctl -p
            if lsmod | grep nanqinlang >/dev/null 2>&1; then
                echo -e "\033[32m    魔改bbr模块tcp_nanqinlang启动成功. \033[0m"
                exit 0
            else
                echo -e "\033[31m    魔改bbr模块tcp_nanqinlang启动失败.\033[0m"
                exit 1
            fi
        fi
    fi
    
    #更新启动配置并删除其它内核
    echo -e "\033[32m    更新启动配置并删除其它内核. \033[0m"
    if grub2-mkconfig -o /boot/grub2/grub.cfg >/dev/null 2>&1;then
        grub2-set-default 0 >/dev/null 2>&1
        if rpm -qa | grep kernel | grep -v "${KERNEL_VER}" >/dev/null 2>&1;then
            rpm -qa | grep kernel | grep -v "${KERNEL_VER}" | xargs yum remove -y
        fi
    fi
    #安装必备组件
    echo -e "\033[32m    安装必备组件包中... \033[0m"
    yum groupinstall -y "Development Tools" && yum install -y libtool gcc gcc-c++ wget
    #下载并编译模块
    if [[ ! -d make_tmp ]]; then
        mkdir make_tmp
    fi
    cd make_tmp
    echo -e "\033[32m    请选择你想要的魔改方案(默认选择温和模式):\n    1.温和模式\n    2.暴力模式\033[0m"
    read -p "    输入[1/2]以选择相应模式. 默认为1: " mode
    [[ -z "${mode}" ]] && mode=1
    while [[ ! "${mode}" =~ ^[1-2]$ ]]
    do
        echo -e "\033[31m    无效输入.\033[0m"
        echo -e "\033[32m    请重新选择\033[0m" && read -p "输入数字以选择:" mode
    done
    echo -e "\033[32m    下载魔改bbr模块tcp_nanqinlang源码中...\033[0m"
    case "${mode}" in
        1)
            if ! wget -O tcp_nanqinlang.c https://raw.githubusercontent.com/viagram/Google-BBR/master/tcp_nanqinlang-gentle.c --no-check-certificate;then
                echo -e "\033[31m    下载魔改bbr模块tcp_nanqinlang源码失败.\033[0m"
                exit 1
            fi
            ;;
        2)
            if ! wget -O tcp_nanqinlang.c https://raw.githubusercontent.com/viagram/Google-BBR/master/tcp_nanqinlang-violent.c --no-check-certificate;then
                echo -e "\033[31m    下载魔改bbr模块tcp_nanqinlang源码失败.\033[0m"
                exit 1
            fi
            ;;
        *)
            echo -e "\033[31m    出错了哦~.\033[0m"
            ;;
    esac
    echo -e "\033[32m    下载Makefile中...\033[0m"
    if ! wget -O Makefile https://raw.githubusercontent.com/viagram/Google-BBR/master/Makefile-CentOS --no-check-certificate;then
        echo -e "\033[31m    下载Makefile失败.\033[0m"
        exit 1
    fi
    echo -e "\033[32m    编译并安装模块tcp_nanqinlang中... \033[0m"
    if make; then
        if make install; then
            echo -e "\033[32m    安装成功, 优化网络设置并启用模块中... \033[0m"
            # 以前优化设置来自于网络, 具体用处嘛~~~我也不知道^_^.
            sysctl=/etc/sysctl.conf
            limits=/etc/security/limits.conf
            sed -i '/* soft nofile/d' $limits; echo '* soft nofile 512000' >> $limits
            sed -i '/* hard nofile/d' $limits; echo '* hard nofile 1024000' >> $limits
            ulimit -n 512000
            sed -i "/net.ipv4.ip_forward/d" $sysctl; echo "net.ipv4.ip_forward = 0" >> $sysctl
            sed -i "/net.ipv4.conf.default.rp_filter/d" $sysctl; echo "net.ipv4.conf.default.rp_filter = 1" >> $sysctl
            sed -i "/net.ipv4.conf.default.accept_source_route/d" $sysctl; echo "net.ipv4.conf.default.accept_source_route = 0" >> $sysctl
            sed -i "/kernel.sysrq/d" $sysctl; echo "kernel.sysrq = 0" >> $sysctl
            sed -i "/kernel.core_uses_pid/d" $sysctl; echo "kernel.core_uses_pid = 1" >> $sysctl
            sed -i "/kernel.msgmnb/d" $sysctl; echo "kernel.msgmnb = 65536" >> $sysctl
            sed -i "/kernel.msgmax/d" $sysctl; echo "kernel.msgmax = 65536" >> $sysctl
            sed -i "/kernel.shmmax/d" $sysctl; echo "kernel.shmmax = 68719476736" >> $sysctl
            sed -i "/kernel.shmall/d" $sysctl; echo "kernel.shmall = 4294967296" >> $sysctl
            sed -i "/net.ipv4.tcp_timestamps/d" $sysctl; echo "net.ipv4.tcp_timestamps = 1" >> $sysctl
            sed -i "/net.ipv4.tcp_retrans_collapse/d" $sysctl; echo "net.ipv4.tcp_retrans_collapse = 0" >> $sysctl
            sed -i "/net.ipv4.icmp_echo_ignore_broadcasts/d" $sysctl; echo "net.ipv4.icmp_echo_ignore_broadcasts = 1" >> $sysctl
            sed -i "/net.ipv4.conf.all.rp_filter/d" $sysctl; echo "net.ipv4.conf.all.rp_filter = 1" >> $sysctl
            sed -i "/fs.inotify.max_user_watches/d" $sysctl; echo "fs.inotify.max_user_watches = 65536" >> $sysctl
            sed -i "/net.ipv4.conf.default.promote_secondaries/d" $sysctl; echo "net.ipv4.conf.default.promote_secondaries = 1" >> $sysctl
            sed -i "/net.ipv4.conf.all.promote_secondaries/d" $sysctl; echo "net.ipv4.conf.all.promote_secondaries = 1" >> $sysctl
            sed -i "/kernel.hung_task_timeout_secs/d" $sysctl; echo "kernel.hung_task_timeout_secs = 0" >> $sysctl
            sed -i "/fs.file-max/d" $sysctl; echo "fs.file-max = 1024000" >> $sysctl
            sed -i "/net.core.wmem_max/d" $sysctl; echo "net.core.wmem_max = 67108864" >> $sysctl
            sed -i "/net.core.netdev_max_backlog/d" $sysctl; echo "net.core.netdev_max_backlog = 250000" >> $sysctl
            sed -i "/net.core.somaxconn/d" $sysctl; echo "net.core.somaxconn = 4096" >> $sysctl
            sed -i "/net.ipv4.tcp_syncookies/d" $sysctl; echo "net.ipv4.tcp_syncookies = 1" >> $sysctl
            sed -i "/net.ipv4.tcp_tw_reuse/d" $sysctl; echo "net.ipv4.tcp_tw_reuse = 1" >> $sysctl
            sed -i "/net.ipv4.tcp_fin_timeout/d" $sysctl; echo "net.ipv4.tcp_fin_timeout = 30" >> $sysctl
            sed -i "/net.ipv4.tcp_keepalive_time/d" $sysctl; echo "net.ipv4.tcp_keepalive_time = 1200" >> $sysctl
            sed -i "/net.ipv4.ip_local_port_range/d" $sysctl; echo "net.ipv4.ip_local_port_range = 10000" >> $sysctl
            sed -i "/net.ipv4.tcp_max_syn_backlog/d" $sysctl; echo "net.ipv4.tcp_max_syn_backlog = 8192" >> $sysctl
            sed -i "/net.ipv4.tcp_max_tw_buckets/d" $sysctl; echo "net.ipv4.tcp_max_tw_buckets = 5000" >> $sysctl
            sed -i "/net.ipv4.tcp_fastopen/d" $sysctl; echo "net.ipv4.tcp_fastopen = 3" >> $sysctl
            sed -i "/net.ipv4.tcp_rmem/d" $sysctl; echo "net.ipv4.tcp_rmem = 4096" >> $sysctl
            sed -i "/net.ipv4.tcp_wmem/d" $sysctl; echo "net.ipv4.tcp_wmem = 4096" >> $sysctl
            sed -i "/net.ipv4.tcp_mtu_probing/d" $sysctl; echo "net.ipv4.tcp_mtu_probing = 1" >> $sysctl
            sed -i "/net.core.default_qdisc/d" $sysctl; echo "net.core.default_qdisc = fq_codel" >> $sysctl
            sed -i "/net.ipv4.tcp_congestion_control/d" $sysctl; echo "net.ipv4.tcp_congestion_control = nanqinlang" >> $sysctl
            sysctl -p
            if lsmod | grep nanqinlang >/dev/null 2>&1; then
                echo -e "\033[32m    魔改bbr模块tcp_nanqinlang启动成功. \033[0m"
            else
                echo -e "\033[31m    魔改bbr模块tcp_nanqinlang启动失败.\033[0m"
                exit 1
            fi
        else
            echo -e "\033[31m    安装失败.\033[0m"
            exit 1
        fi
    else
        echo -e "\033[31m    编译失败.\033[0m"
        exit 1
    fi
    cd - >/dev/null 2>&1
    rm -rf make_tmp
fi
