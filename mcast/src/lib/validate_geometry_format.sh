## Geometry format validation
## Expected format: 'X,Y WxH' (e.g., '100,200 800x600')
validate_geometry_format() {
  local input="$1"
  
  # Pattern: X,Y WxH where X, Y, W, H are non-negative integers
  if [[ ! "$input" =~ ^[0-9]+,[0-9]+\ [0-9]+x[0-9]+$ ]]; then
    echo "invalid format: Expected 'X,Y WxH' (e.g., '100,200 800x600')"
  fi
}
