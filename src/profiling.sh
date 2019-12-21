# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Name: profiling.sh - part of the BeakerLib project
#   Description: functions to profile beakerlib itself
#
#   Author: Dalibor Pospisil <dapospis@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2008-2019 Red Hat, Inc. All rights reserved.
#
#   This copyrighted material is made available to anyone wishing
#   to use, modify, copy, or redistribute it subject to the terms
#   and conditions of the GNU General Public License version 2.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free
#   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
#   Boston, MA 02110-1301, USA.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo "${__INTERNAL_SOURCED}" | grep -qF -- " ${BASH_SOURCE} " && return || __INTERNAL_SOURCED+=" ${BASH_SOURCE} "

: <<'=cut'
=pod

=head1 NAME

BeakerLib - profiling - helper for profiling beakerlib itself

=head1 DESCRIPTION

Functions for generating and processing the beakerlib performance profile.

=cut

: <<'=cut'
=pod

=head2 Beakerlib Profiling

=head3 Enable profiling

Set environment variable BEAKERLIB_PROFILING=1

    BEAKERLIB_PROFILING=1 make run

A file /dev/shm/beakerlib_profile will be created for later processing.

=head3 Process the profile

    profiling.sh process

=cut

__INTERNAL_PROFILING_DB=/dev/shm/beakerlib_profile

if [[ -n "$BEAKERLIB_PROFILING" ]]; then
  > $__INTERNAL_PROFILING_DB
  if [[ -n "$EPOCHREALTIME" ]]; then
    __INTERNAL_PROFILING_TIME='$EPOCHREALTIME'
    __INTERNAL_PROFILING_TIME_FMT='%f'
  else
    __INTERNAL_PROFILING_TIME='$(date +%s.%N)'
    __INTERNAL_PROFILING_TIME_FMT='%f'
  fi
  eval "__INTERNAL_PROFILING() {
    printf \"$__INTERNAL_PROFILING_TIME_FMT|\${BASH_SOURCE[1]}(\${BASH_LINENO[0]})|\${FUNCNAME[*]:1}|%q\n\" $__INTERNAL_PROFILING_TIME \"\$BASH_COMMAND\" >> $__INTERNAL_PROFILING_DB
  }"
  if [[ -z "$1" ]]; then
    set -o functrace; trap "__INTERNAL_PROFILING" DEBUG
  fi
fi

return >/dev/null 2>&1


__INTERNAL_profilingPrint() {
  cat $__INTERNAL_PROFILING_DB
}
__INTERNAL_profiling_process() {
  local prev_func curr_func counting duration prev_ts
  declare -A hits duration
  hits[main]=1
  local ts src func command f
  while IFS='|' read -r ts src func command; do
    ts=${ts//[^0-9]/}
    curr_func=($func)
    [[ ${#func} -gt ${#prev_func} ]] && let hits[$curr_func]++
    [[ -n "$prev_ts" ]] && {
      # count func duration
      for f in $prev_func; do
        let duration[$f]+=$((ts-prev_ts))
      done
    }
    #echo "$ts $src $func: $command"
    prev_func=$func
    prev_ts=$ts
  done < <(head -n -2 $__INTERNAL_PROFILING_DB)
  for f in ${!hits[*]}; do
    echo "$f - hits: ${hits[$f]}, duration: $(echo "scale=6; ${duration[$f]} / ${hits[$f]} / 1000000" | bc) s, total duration $(echo "scale=6; ${duration[$f]} / 1000000" | bc) s"
  done
}


case $1 in
  process)
    __INTERNAL_profiling_process
    ;;
esac


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# AUTHORS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
: <<'=cut'
=pod

=head1 AUTHORS

=over

=item *

Dalibor Pospisil <dapospis@redhat.com>

=back

=cut
