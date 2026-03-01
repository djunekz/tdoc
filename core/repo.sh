repo() {
  local found=0

  # Semua sumber apt yang perlu dicek
  local all_sources=""

  # sources.list utama
  if [[ -f "$PREFIX/etc/apt/sources.list" ]]; then
    all_sources+=$(cat "$PREFIX/etc/apt/sources.list" 2>/dev/null)
    all_sources+=$'\n'
  fi

  # sources.list.d/
  if [[ -d "$PREFIX/etc/apt/sources.list.d" ]]; then
    all_sources+=$(cat "$PREFIX/etc/apt/sources.list.d/"*.list 2>/dev/null || true)
  fi

  local official_mirrors=(
    "packages.termux.dev"
    "mirror.albony.in"
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
    "mirrors.utermux.dev"
    "plug-mirror.rcac.purdue.edu"
    "mirror.vern.cc"
    "dl.kcubeterm.com"
    "termux.danyael.xyz"
    "mirror.csclub.uwaterloo.ca"
    "mirror.fcix.net"
    "mirrors.middlendian.com"
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
