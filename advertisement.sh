#!/bin/bash
if [ -z "$flex_sdk" ]; then source properties.sh; fi;

$flex_bin/compc -o "$build_dir/libs/AdvertisementPlugin.swc" \
	-debug=$debug \
	-swf-version=11 \
	-target-player=10.2 \
	-sp "$advertisement_plugin/src" \
	-is "$advertisement_plugin/src" \
	-external-library-path+="$flex_sdk/frameworks/libs",libs \
	-define CONFIG::LOGGING $logging

