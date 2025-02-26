#!/usr/bin/env bash
# https://stackoverflow.com/questions/59895/how-do-i-get-the-directory-where-a-bash-script-is-located-from-within-the-script
script_source=${BASH_SOURCE[0]}
while [ -L "$script_source" ]; do # resolve $script_source until the file is no longer a symlink
  script_target=$(readlink "$script_source")
  if [[ $script_target == /* ]]; then
    #echo "script_source '$script_source' is an absolute symlink to '$script_target'"
    script_source=$script_target
  else
    script_dir=$( dirname "$script_source" )
    #echo "script_source '$script_source' is a relative symlink to '$script_target' (relative to '$script_dir')"
    script_source=$script_dir/$script_target # if $script_source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  fi
done
#echo "script_source is '$script_source'"
script_resolves_dir=$( dirname "$script_source" )
script_dir=$( cd -P "$( dirname "$script_source" )" >/dev/null 2>&1 && pwd )
script_source=$(basename $script_source)
#if [ "$script_dir" != "$script_resolves_dir" ]; then
#  echo "script_dir '$script_resolves_dir' resolves to '$script_dir'"
#fi
#echo "script_dir is '$script_dir'"
echo "script_source : $script_source"
unset script_target script_resolves_dir
script_base_dir=$(dirname $script_dir)
#echo "script_base_dir is '$script_base_dir'"

cd $script_dir

rm -f */*.pkg.tar.gz
rm -f */filelist
rm -f */build.log
rm -rf */pkg
rm -rf */src

