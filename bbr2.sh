#!/bin/bash
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

function printnew(){
	typeset -l CHK
	WENZHI=""
	COLOUR=""
	HUANHANG=0
	for PARSTR in "${@}"; do
		CHK="${PARSTR}"
		if echo "${CHK}" | egrep -io "^\-[[:graph:]]*" >/dev/null 2>&1; then
			case "${CHK}" in
				-black) COLOUR="\033[30m";;
				-red) COLOUR="\033[31m";;
				-green) COLOUR="\033[32m";;
				-yellow) COLOUR="\033[33m";;
				-blue) COLOUR="\033[34m";;
				-purple) COLOUR="\033[35m";;
				-cyan) COLOUR="\033[36m";;
				-white) COLOUR="\033[37m";;
				-a) HUANHANG=1 ;;
				*) COLOUR="\033[37m";;
			esac
		else
			WENZHI+="${PARSTR}"
		fi
	done
	if [[ ${HUANHANG} -eq 1 ]]; then
		printf "${COLOUR}%b%s\033[0m" "${WENZHI}"
	else
		printf "${COLOUR}%b%s\033[0m\n" "${WENZHI}"
	fi
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
	if ! command -v virt-what >/dev/null 2>&1; then
		yum install -y virt-what >/dev/null 2>&1
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
	if echo ${Text} | egrep -io "(centos[a-z ]*5|red[a-z ]*hat[a-z ]*5)" >/dev/null 2>&1; then echo centos5
	elif echo ${Text} | egrep -io "(centos[a-z ]*6|red[a-z ]*hat[a-z ]*6)" >/dev/null 2>&1; then echo centos6
	elif echo ${Text} | egrep -io "(centos[a-z ]*7|red[a-z ]*hat[a-z ]*7)" >/dev/null 2>&1; then echo centos7
	elif echo ${Text} | egrep -io "Fedora[a-z ]*[0-9]{1,2}" >/dev/null 2>&1; then echo fedora
	elif echo ${Text} | egrep -io "debian[a-z /]*[0-9]{1,2}" >/dev/null 2>&1; then echo debian
	elif echo ${Text} | egrep -io "ubuntu" >/dev/null 2>&1; then echo ubuntu
   fi
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
	sysctl -p
	sleep 1
}

function check_bbr(){
	if lsmod | grep tcp_bbr >/dev/null 2>&1; then
		printnew -green " [BBR v2] 模块运行中. "
		return 0
	else
		printnew -red " [BBR v2] 模块没有运行. "
		return 1
	fi
}

function apply_bbr(){
	if check_bbr; then
		printnew -green " [BBR v2] 模块运行中. "
		return 0
	else
		sed -i '/net\.core\.default_qdisc/d' /etc/sysctl.conf
		echo 'net.core.default_qdisc=fq' >> /etc/sysctl.conf
		sed -i '/net\.ipv4\.tcp_congestion_control/d' /etc/sysctl.conf
		echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf
		sysctl -p >/dev/null 2>&1
		if check_bbr; then
			printnew -green " [BBR v2] 模块启动成功. "
			return 0
		else
			printnew -red " [BBR v2] 模块启动失败."
			return 1
		fi
	fi
}

function uninstall_bbr(){
	if check_bbr >/dev/null 2>&1; then
		sed -i '/net\.core\.default_qdisc=/d'		  /etc/sysctl.conf
		sed -i '/net\.ipv4\.tcp_congestion_control=/d' /etc/sysctl.conf
		sysctl -p >/dev/null 2>&1
		sleep 1
		printnew -green "删除成功, 请重启系统以停止 [BBR v2] 模块."
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
		printnew -red "检测到系统没有安装 [BBR v2] 模块. "
	fi
}

function _install_v2_kernel(){
	if rpm -qa | egrep -i "kernel" | egrep -i "headers" >/dev/null 2>&1; then
		printnew -green "为避免冲突, 正在删除旧版本的kernel-headers: "
		rpm -qa | egrep -i "kernel" | egrep -i "headers" | xargs yum remove -y
	fi
	#https://github.com/xiya233/bbr2/tree/master/centos
	down_url='https://raw.githubusercontent.com/xiya233/bbr2/master/centos/'
	! wget -c ${down_url}kernel-5.2.0_rc3+-1.x86_64.rpm -O kernel-5.2.0_rc3+-1.x86_64.rpm && echo -e "\033[31m下载失败\033[0m"
	! wget -c ${down_url}kernel-headers-5.2.0_rc3+-1.x86_64.rpm -O kernel-headers-5.2.0_rc3+-1.x86_64.rpm && echo -e "\033[31m下载失败\033[0m"
	if ! yum install -y kernel-5.2.0_rc3+-1.x86_64.rpm kernel-headers-5.2.0_rc3+-1.x86_64.rpm; then
		printnew -red "内核安装失败."
		rm -rf kernel-5.2.0_rc3+-1.x86_64.rpm kernel-headers-5.2.0_rc3+-1.x86_64.rpm
		exit 1
	else
		printnew -green "内核安装成功."
	fi
	rm -rf kernel-5.2.0_rc3+-1.x86_64.rpm kernel-headers-5.2.0_rc3+-1.x86_64.rpm
	printnew -green -a "正在设置新内核的启动顺序: "
	if [[ -f /boot/grub/grub.conf ]]; then
		kernel_default="CentOS Linux (5.2.0-rc3+) 7 (Core)"
		sed -i "s/^default.*/default=${kernel_default}/" /boot/grub/grub.conf >/dev/null 2>&1
		printnew -yellow "成功. "
	else
		if ! command -v grub2-mkconfig >/dev/null 2>&1; then
			yum remove -y grub2-tools-minimal
			yum install -y grub2-tools
		fi
		grub2-mkconfig -o /boot/grub2/grub.cfg >/dev/null 2>&1
		kernel_name="CentOS Linux (5.2.0-rc3+) 7 (Core)"
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

	if ! egrep -i "${MY_SCRIPT}" ~/.bashrc >/dev/null 2>&1; then
		echo "sh ${MY_SCRIPT} install">>~/.bashrc
	fi
	printnew -green "设置成功, 请重启系统后再次执行安装. "
	read -p "输入[y/n]选择是否重启, 默认为y：" is_reboot
	[[ -z "${is_reboot}" ]] && is_reboot='y'
	[[ ${is_reboot} =~ ^[Yy]$ ]] && reboot
}

#####################################################################################
if [[ "$(Check_OS)" != "centos7" ]]; then
	printnew -red "目前仅支持CentOS 7及Redhat 7系统."
	exit 1
else
	typeset -l REINSTALL
	REINSTALL="${1}"
	if [[ -n "${REINSTALL}" && "${REINSTALL}" == "install" ]]; then
		printnew -green "将进行 [BBR v2] 模块二次安装进程."
		read -p "输入[y/n]选择是否继续, 默认为y：" is_go
		[[ -z "${is_go}" ]] && is_go='y'
		if [[ ! ${is_go} =~ ^[Yy]$ ]]; then
			printnew -red "用户取消, 程序终止."
			exit 0
		fi
	else
		printnew -green "请输入数字进行选择."
		printnew -green "   1, 安装 [BBR v2] 模块"
		printnew -green "   2, 查看 [BBR v2] 状态"
		printnew -green "   3, 删除 [BBR v2] 模块"
		printnew -green "   0, 退出脚本"
		read -p "输入[1/2/3]以选择相应模式. 默认为1: " mode
		[[ -z "${mode}" ]] && mode=1
		#while [[ ! "${forceinstall}" =~ ^[YyNn]$ ]]; do
		while [[ ! "${mode}" =~ ^[0-3]$ ]]; do
			printnew -red "无效输入."
			read -p "请重新输入数字以选择: " mode
		done
		case "${mode}" in
		1)
			_install_v2_kernel
		;;
		2)
			check_bbr
		;;
		3)
			if check_bbr >/dev/null 2>&1; then
				printnew -green "删除 [BBR v2] 模块中: "
				uninstall_bbr
			else
				printnew -red "检测到系统没有安装 [BBR v2] 模块. "
			fi
		;;
		0)
			exit 1
		;;
		*)
			printnew -red "	Error."
			exit 1
		;;
		esac
	fi

	#检测系统架构
	chk_what
	
	#删除二次登陆启动项
	if egrep -i "${MY_SCRIPT}" ~/.bashrc >/dev/null 2>&1; then
		MY_SCRIPT2=${MY_SCRIPT//\//\\/}
		sed -i "/${MY_SCRIPT2}/d" ~/.bashrc
	fi
	
	#更新启动配置并删除其它内核
	if rpm -qa | grep kernel | grep -v "$(uname -r)" >/dev/null 2>&1; then
		printnew -green "删除其它老旧内核: "
		rpm -qa | grep kernel | grep -v "$(uname -r)" | xargs yum remove -y
		cd /lib/modules/
		ls | grep -v $(uname -r) | xargs rm -rf
		cd - >/dev/null 2>&1
	fi

	if check_bbr >/dev/null 2>&1; then
		printnew "\033[41;37m提示: \033[0m\033[32m检测到 [BBR v2] 模块已在运行中. "
		exit 0
	else
		printnew -green "进行[ [BBR v2] 模块]安装进程: "
	fi
	
	printnew -a -green "优化并启用 [BBR v2] : "
	OptNET >/dev/null 2>&1
	if apply_bbr >/dev/null 2>&1; then
		printnew -green "启动成功"
	else
		printnew -red "启动失败"
	fi
fi
