config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/msnap"
config_file="$config_dir/mcast.conf"
if [[ ! -f "$config_file" ]]; then
  mkdir -p "$config_dir"
  cp "./mcast.conf" "$config_file"
fi
CONFIG_FILE="$config_file"
ini_load "$config_file"
