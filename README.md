# 魔改 Google-BBR 网络加速脚本

感谢: 

  nanqinlang   <https://github.com/nanqinlang-tcp/tcp_nanqinlang>

注意: 

  脚本目前理论支持CentOS6,7和Redhat6,7, 由于Redhat是商业系统, 所以我仅在CentOS6,7上完美测试成功.且据南琴浪大牛说CentOS(Redhat)上还有些Bug, 因此建议不要用于生产环境. 
  嗯, 等他(她)修复. @nanqinlang

安装方法1:

    wget -O bbr.sh https://github.com/viagram/Google-BBR/raw/master/bbr.sh && sh bbr.sh

安装方法2:

    curl -skLo bbr.sh https://github.com/viagram/Google-BBR/raw/master/bbr.sh && sh bbr.sh

按提示操作, 基本按几下回车键即可.
