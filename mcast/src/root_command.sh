set -euo pipefail

output_dir="${args[--output]:-${ini[output_dir]:-${XDG_VIDEOS_DIR:-$HOME/Videos}/Screencasts}}"
filename_pattern="${args[--filename]:-${ini[filename_pattern]:-%Y%m%d%H%M%S.mp4}}"
toggle_mode="${args[--toggle]:-}"

command -v gpu-screen-recorder >/dev/null || { echo "Error: gpu-screen-recorder not installed"; exit 1; }

recording_pid_file="/tmp/mcast.pid"
recording_filepath_file="/tmp/mcast.filepath"

build_cmd() {
  local geometry=""
  if [[ ${args[--geometry]:-} ]]; then
    geometry="${args[--geometry]}"
  elif [[ ${args[--region]:-} ]]; then
    geometry="$(slurp -d)" || { echo "Error: Failed to select region"; exit 1; }
  fi

  cmd=""
  local audio_flags=""
  if [[ ${args[--audio]:-} && ${args[--mic]:-} ]]; then
    local audio_device="${args[--audio-device]:-default_output}"
    local mic_device="${args[--mic-device]:-default_input}"
    audio_flags=" -a \"$audio_device|$mic_device\""
  elif [[ ${args[--audio]:-} ]]; then
    local device="${args[--audio-device]:-default_output}"
    audio_flags=" -a \"$device\""
  elif [[ ${args[--mic]:-} ]]; then
    local device="${args[--mic-device]:-default_input}"
    audio_flags=" -a \"$device\""
  fi
  if [[ -n "$geometry" ]]; then
    local x y w h
    IFS=',x ' read -r x y w h <<< "$geometry"
    local region_arg="-region ${w}x${h}+${x}+${y}"
    cmd="gpu-screen-recorder -w region $region_arg -f 60$audio_flags -o \"$filepath\""
  else
    cmd="gpu-screen-recorder -w screen -f 60$audio_flags -o \"$filepath\""
  fi
}

if [[ -n "$toggle_mode" ]]; then
  if [[ -f "$recording_pid_file" ]] && kill -0 "$(<"$recording_pid_file")" 2>/dev/null; then
    kill "$(<"$recording_pid_file")"
    rm -f "$recording_pid_file"
    if [[ -f "$recording_filepath_file" ]]; then
      filepath=$(<"$recording_filepath_file")
      rm -f "$recording_filepath_file"
      notify-send "Recording saved" "Recording saved in <i>${filepath}</i>." -a mcast
    fi
  else
    filename="$(date +"$filename_pattern")"
    filepath="$output_dir/$filename"
    mkdir -p "$output_dir"
    echo "$filepath" > "$recording_filepath_file"

    build_cmd
    eval "$cmd > /dev/null 2>&1 &"
    echo $! > "$recording_pid_file"
  fi
else
  filename="$(date +"$filename_pattern")"
  filepath="$output_dir/$filename"
  mkdir -p "$output_dir"

  build_cmd
  eval "$cmd"
  notify-send "Recording saved" "Recording saved in <i>${filepath}</i>." -a mcast
fi
