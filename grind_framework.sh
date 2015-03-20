#!/bin/bash
if [ -z "$flex_sdk" ]; then source properties.sh; fi;

$flex_bin/compc -o "$build_dir/libs/GrindFramework.swc" \
	-debug=$debug \
	-swf-version=11 \
	-target-player=10.2 \
	-sp "$grind_framework/src" \
	-is "$grind_framework/src" \
	-external-library-path+="$flex_sdk/frameworks/libs",libs \
	-define CONFIG::LOGGING $logging \
	-define CONFIG::FLASH_10_1 true

