#!/usr/bin/env bash
# Generated and installed by your custom buildpack.
# Purpose: Resolve and export SE_EPHE_PATH at dyno startup.

# Prefer graceful behavior at login time; never crash the dyno shell.
set +eu

resolve_with_bundle() {
  if command -v bundle >/dev/null 2>&1; then
    local dir
    # 'bundle info --path' prints the gem directory; append vendor/swe_data
    dir="$(bundle info astroscript --path 2>/dev/null)"
    if [ -n "$dir" ]; then
      printf '%s\n' "${dir%/}/vendor/swe_data"
      return 0
    fi
  fi
  return 1
}

resolve_with_ruby() {
  if command -v ruby >/dev/null 2>&1; then
    ruby -e 'begin
      require "rubygems"
      spec = Gem::Specification.find_by_name("astroscript")
      puts File.join(spec.gem_dir, "vendor", "swe_data")
    rescue Exception
      # silent fallback
    end'
  fi
}

EPHE=""
EPHE="$(resolve_with_bundle)"
if [ -n "$EPHE" ]; then
  echo "Resolved Swiss Ephemeris data path with bundle: $EPHE"
else
  # echo "Failed to resolve Swiss Ephemeris data path with bundle, trying ruby"
  EPHE="$(resolve_with_ruby)"
fi

if [ -n "$EPHE" ]; then
  echo "Resolved Swiss Ephemeris data path with ruby: $EPHE"
fi

if [ -n "$EPHE" ]; then
  export SE_EPHE_PATH="$EPHE"
  echo "[aistrologer-buildpack-post] Set env var SE_EPHE_PATH to $EPHE"
fi

unset EPHE
