repo() {
  local found=0

  local all_sources=""

  if [[ -f "$PREFIX/etc/apt/sources.list" ]]; then
    all_sources+=$(cat "$PREFIX/etc/apt/sources.list" 2>/dev/null)
    all_sources+=$'\n'
  fi

  if [[ -d "$PREFIX/etc/apt/sources.list.d" ]]; then
    all_sources+=$(cat "$PREFIX/etc/apt/sources.list.d/"*.list 2>/dev/null || true)
  fi

  local official_mirrors=(
    # Official
    "packages.termux.dev"
    "linux.domainesia.com"
    # India
    "mirror.niranjan.co"
    "mirror.bardia.tech"
    "mirrors.saswata.cc"
    "mirrors.ravidwivedi.in"
    "mirrors.in.sahilister.net"
    "mirror.albony.in"
    # Korea / Japan
    "mirror.textcord.xyz"
    "mirrors.krnk.org"
    "mirror.rinarin.dev"
    "mirror.jeonnam.school"
    # Vietnam / Southeast Asia
    "mirrors.nguyenhoang.cloud"
    "mirror.meowsmp.net"
    "mirror.freedif.org"
    "tmx.xvx.my.id"
    # Taiwan
    "mirror.twds.com.tw"
    # Indonesia
    "mirror.nevacloud.com"
    # China
    "mirrors.cbrx.io"
    "mirrors.iscas.ac.cn"
    "mirrors.sau.edu.cn"
    "mirrors.sdu.edu.cn"
    "mirrors.aliyun.com"
    "mirrors.cernet.edu.cn"
    "mirrors.cqupt.edu.cn"
    "mirrors.sustech.edu.cn"
    "mirrors.bfsu.edu.cn"
    "mirrors.pku.edu.cn"
    "mirrors.hust.edu.cn"
    "mirrors.tuna.tsinghua.edu.cn"
    "mirror.sjtu.edu.cn"
    "mirror.nyist.edu.cn"
    "mirrors.ustc.edu.cn"
    "mirrors.zju.edu.cn"
    "mirrors.nju.edu.cn"
    # Europe
    "grimler.se"
    "mirror.polido.pt"
    "termux.3am.dev"
    "mirrors.medzik.dev"
    "mirror.accum.se"
    "ro.mirror.flokinet.net"
    "md.mirrors.hacktegic.com"
    "is.mirror.flokinet.net"
    "mirror.termux.dev"
    "termux.mentality.rip"
    "nl.mirror.flokinet.net"
    "termux.cdn.lumito.net"
    "mirror.leitecastro.com"
    "mirror.bouwhuis.network"
    "termux.librehat.com"
    "mirror.autkin.net"
    "mirror.sunred.org"
    "ftp.agdsn.de"
    "ftp.fau.de"
    "mirrors.cfe.re"
    "mirrors.de.sahilister.net"
    "gnlug.org"
    "mirror.mwt.me"
    "mirror.quantum5.ca"
    # USA
    "mirrors.utermux.dev"
    "plug-mirror.rcac.purdue.edu"
    "mirror.vern.cc"
    "dl.kcubeterm.com"
    "termux.danyael.xyz"
    # Canada
    "mirror.csclub.uwaterloo.ca"
    # Australia
    "mirrors.middlendian.com"
    # Others
    "mirror.fcix.net"
    "repository.su"
    "mirror.mephi.ru"
  )

  for mirror in "${official_mirrors[@]}"; do
    if echo "$all_sources" | grep -q "$mirror"; then
      found=1
      break
    fi
  done

  if [[ "$found" -eq 1 ]]; then
    echo "Repository=OK" >> "$STATE_FILE"
  else
    echo "Repository=BROKEN" >> "$STATE_FILE"
  fi
}
