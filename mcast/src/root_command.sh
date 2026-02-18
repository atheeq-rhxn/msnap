output_dir="${args[--output]:-${ini[output_dir]:-${XDG_VIDEOS_DIR:-$HOME/Videos}/Screencasts}}"
filename_pattern="${args[--filename]:-${ini[filename_pattern]:-%Y%m%d%H%M%S.mp4}}"
toggle_mode="${args[--toggle]:-}"

recording_pid_file="/tmp/mcast.pid"
recording_filepath_file="/tmp/mcast.filepath"

build_cmd() {
  local geometry=""
  if [[ ${args[--geometry]:-} ]]; then
    geometry="${args[--geometry]}"
  elif [[ ${args[--region]:-} ]]; then
    geometry="$(slurp -d)" || { echo "Error: Failed to select region" >&2; exit 1; }
  fi

  cmd=(gpu-screen-recorder)

  if [[ -n "$geometry" ]]; then
    local x y w h
    IFS=',x ' read -r x y w h <<< "$geometry"
    cmd+=(-w region -region "${w}x${h}+${x}+${y}")
  else
    cmd+=(-w screen)
  fi

  if [[ ${args[--audio]:-} && ${args[--mic]:-} ]]; then
    cmd+=(-a "${args[--audio-device]:-default_output}|${args[--mic-device]:-default_input}")
  elif [[ ${args[--audio]:-} ]]; then
    cmd+=(-a "${args[--audio-device]:-default_output}")
  elif [[ ${args[--mic]:-} ]]; then
    cmd+=(-a "${args[--mic-device]:-default_input}")
  fi

  cmd+=(-o "$filepath")
}

if [[ -n "$toggle_mode" ]]; then
  if [[ -f "$recording_pid_file" ]]; then
    pid=$(<"$recording_pid_file")
    if kill -0 "$pid" 2>/dev/null; then
      kill -2 "$pid"
    fi
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
    "${cmd[@]}" > /dev/null 2>&1 &
    echo $! > "$recording_pid_file"
  fi
else
  filename="$(date +"$filename_pattern")"
  filepath="$output_dir/$filename"
  mkdir -p "$output_dir"

  build_cmd
  "${cmd[@]}"
  notify-send "Recording saved" "Recording saved in <i>${filepath}</i>." -a mcast
fi