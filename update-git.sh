#!/bin/sh

find ~/devstack ~/openstack -name .git -type d | while read dir; do
    pushd $(dirname "$dir")>/dev/null
    out=$(mktemp)
    git pull >"$out" 2>&1
    if [ $? != 0 ]; then
        echo "$dir failed"
        cat "$out"
    fi
    rm $out
    popd>/dev/null
done
