# shellcheck shell=bash
# Checked-in landing authority for this Firstmate distribution.
#
# This file is sourced through each caller's SCRIPT_DIR.  The pause is a source
# invariant, not a marker, config value, environment switch, or task-metadata
# default: missing or redirected runtime state can therefore never turn the
# pause into permission.  A later reviewed source pin may replace these refusals
# only when it carries a real positive authority and reviewed-head verifier.

FM_LANDING_POLICY="paused-v1"

fm_landing_policy_refusal() {
  printf 'error: landing is disabled by checked-in Firstmate policy %s; no merge authority was granted\n' \
    "$FM_LANDING_POLICY" >&2
  return 1
}

fm_landing_policy_require_yolo_off() { # <on|off>
  [ "${1:-}" = off ] && return 0
  printf 'error: --yolo on is disabled by checked-in Firstmate policy %s\n' \
    "$FM_LANDING_POLICY" >&2
  return 1
}

fm_landing_policy_refuse_meta_yolo_on() { # <task-meta>
  local meta=${1:-} line
  # Absence is not authority, but it is the ordinary "no task record" case
  # owned by the relaunch path below this preflight. Every path shape that does
  # exist must be a plain regular file: do not follow a symlink or open a FIFO,
  # device, socket, or directory while deciding whether operational imports may
  # run.
  if [ ! -e "$meta" ] && [ ! -L "$meta" ]; then
    return 0
  fi
  if [ -L "$meta" ] || [ ! -f "$meta" ]; then
    printf 'error: relaunch metadata path is not a regular non-symlink file: %s\n' "$meta" >&2
    return 1
  fi
  if ! exec 9< "$meta"; then
    printf 'error: relaunch metadata cannot be opened safely: %s\n' "$meta" >&2
    return 1
  fi
  # Recheck after open so a stable path replacement cannot turn the validated
  # name into a symlink or special file before parsing. /dev/fd is available on
  # the supported macOS and Linux shells and proves the opened object is regular.
  if [ -L "$meta" ] || [ ! -f "$meta" ] || [ ! -f /dev/fd/9 ]; then
    exec 9<&-
    printf 'error: relaunch metadata changed to an unsafe path during preflight: %s\n' "$meta" >&2
    return 1
  fi
  while IFS= read -r line <&9 || [ -n "$line" ]; do
    if [ "$line" = yolo=on ]; then
      exec 9<&-
      fm_landing_policy_require_yolo_off on
      return 1
    fi
  done
  exec 9<&-
  return 0
}

fm_landing_policy_refuse_floating_update() {
  printf 'error: /updatefirstmate is disabled by checked-in Firstmate policy %s; install a reviewed full commit pin instead\n' \
    "$FM_LANDING_POLICY" >&2
  return 1
}
