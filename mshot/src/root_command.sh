if [[ ${args[--only-copy]} ]]; then
  filepath="$(mktemp --suffix=.png)"
  trap 'rm -f "$filepath"' EXIT
else
  output_dir="${args[--output]:-${ini[output_dir]:-${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots}}"
  filename_pattern="${args[--filename]:-${ini[filename_pattern]:-%Y%m%d%H%M%S.png}}"
  filename="$(date +"$filename_pattern")"
  filepath="$output_dir/$filename"
  mkdir -p "$output_dir"
fi

cmd=(grim)

use_pointer=""
[[ ${ini[pointer_default]} == true ]] || [[ ${args[--pointer]} ]] && use_pointer=true
[[ $use_pointer ]] && cmd+=(-c)

if [[ ${args[--window]} ]]; then
  geometry=$(mmsg -x | awk '/x / {x=$3} /y / {y=$3} /width / {w=$3} /height / {h=$3} END {print x","y" "w"x"h}')
  if [[ -z "$geometry" ]]; then
    echo "Error: No active window found or mmsg failed." >&2
    exit 1
  fi
  cmd+=(-g "$geometry")
elif [[ ${args[--geometry]} ]]; then
  cmd+=(-g "${args[--geometry]}")
fi

if [[ ${args[--freeze]} ]]; then
  cursor_flag=""
  [[ -z $use_pointer ]] && cursor_flag="--hide-cursor"
  if [[ ${args[--region]} ]]; then
    wayfreeze $cursor_flag & PID=$!
    sleep .1
    slurp -d | "${cmd[@]}" -g- "$filepath"
    kill $PID 2>/dev/null || true
  else
    wayfreeze $cursor_flag & PID=$!
    sleep .1
    "${cmd[@]}" "$filepath"
    kill $PID 2>/dev/null || true
  fi
elif [[ ${args[--region]} ]]; then
  slurp -d | "${cmd[@]}" -g- "$filepath"
else
  "${cmd[@]}" "$filepath"
fi

if [[ ${args[--annotate]} ]]; then
  satty --filename "$filepath" --output-filename "$filepath" \
    --actions-on-enter save-to-file --early-exit --disable-notifications
fi

notify_title="Screenshot saved"

if [[ ${args[--only-copy]} ]]; then
  wl-copy < "$filepath"
  message="Image copied to the clipboard."
  notify_title="Screenshot captured"
elif [[ ! ${args[--no-copy]} ]]; then
  wl-copy < "$filepath"
  message="Image saved in <i>${filepath}</i> and copied to the clipboard."
else
  message="Image saved in <i>${filepath}</i>."
fi

notify-send "$notify_title" "${message}" -i "${filepath}" -a mshot
