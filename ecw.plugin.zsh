# CLI Support for ECW and OPSSH functions from host PC
#
# Maintained by Nick Hudson nick.hudson@motorolasolutions.com
#

: ${ECW_DEFAULT_ACTION:=opssh}
zmodload zsh/regex

function ecw() {
  emulate -L zsh
  local action=${1:$ECW_DEFAULT_ACTION}
  local ecw_site=${2}
  local ops=ecx.dellroad.org
  local ssh=`which ssh`
  local scp=`which scp`
  local d2u=`which dos2unix`
  local opssh=/usr/bin/opssh
  local opscp=/usr/bin/opscp
  local opsite=/usr/bin/opsite
  local ssh_opts1=-A
  local ssh_opts2=-t
  local ssh_opts3=-q
  local tmp_file=/tmp/ecw_fonehome

 # Lets get cluster information
  local node=$(echo $ecw_site | cut -d . -f1)
  local cluster=$(echo $ecw_site | cut -d . -f2 | cut -b2,3)
  local site=$(echo $ecw_site | cut -d . -f3)

  if [[ $node == 'n1' ]]; then
    local _node=node1
  fi
  if [[ $node == 'n2' ]]; then
    local _node=node2
  else
    local _node=node1
  fi

  if [[ $cluster =~ [1-9] ]]; then
    _cluster=cluster$cluster
  else
    _cluster=cluster1
  fi

  local _ecw_site=$_node.$_cluster.$site
  local passwd=$($ssh $ssh_opts1 $ssh_opts2 $ssh_opts3 $ops $opsite --password $site)
  local version=$($ssh $ssh_opts1 $ssh_opts2 $ssh_opts3 $ops $opsite --version $site)
  local fonehome=("${(@f)$($ssh $ssh_opts1 $ssh_opts2 $ssh_opts3 $ops $opsite --fonehome $site |$d2u)}")

  _get_fonehome_ports() {
    for _site ($fonehome) {
      _node_name=$(echo $_site | cut -d: -f1)
      _fonehome=$(echo $_site | cut -d: -f2)
      if [[ $_ecw_site == $_node_name ]]; then
        __fonehome_port=$_fonehome
      fi
    }
  }

  if [[ $action == "opssh" ]]; then
    echo ""
    echo $fg_bold[red]"********************************************************************" $reset_color
    echo " Logging into" $fg_bold[red]"$_ecw_site" $reset_color
    echo " The ecw version for $_ecw_site is:" $fg_bold[red]"$version" $reset_color
    echo " The password for $_ecw_site is:" $fg_bold[red]"$passwd" $reset_color
    echo $fg_bold[red]"********************************************************************" $reset_color
    echo ""

    $ssh $ssh_opts1 $ssh_opts2 $ssh_opts3 $ops $opssh $_ecw_site
  fi

  if [[ $action == 'passwd' ]]; then
    echo ""
    echo $fg_bold[red]"********************************************************************" $reset_color
    echo " The password for $ecw_site is:" $fg_bold[red]"$passwd" $reset_color
    echo $fg_bold[red]"********************************************************************" $reset_color
    echo ""
  fi

  if [[ $action == 'version' ]]; then
    echo ""
    echo $fg_bold[red]"********************************************************************" $reset_color
    echo " The ecw version for $ecw_site is:" $fg_bold[red]"$version" $reset_color
    echo $fg_bold[red]"********************************************************************" $reset_color
    echo ""
  fi

  if [[ $action == 'opscp' ]]; then
    _get_fonehome_ports
    echo ""
    echo $fg_bold[red]"********************************************************************" $reset_color
    echo " Transferring files to/from:" $fg_bold[red]"$_ecw_site" $reset_color
    echo $fg_bold[red]"********************************************************************" $reset_color
    echo ""
    $scp -qP $__fonehome_port -oProxyCommand="$ssh -W %h:%p $ops" $3 $4
  fi
}
