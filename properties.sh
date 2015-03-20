#!/bin/bash

export PLAYERGLOBAL_HOME=$flex_sdk/frameworks/libs/player
export flex_sdk=~/grindbuild/flex_sdk
export flex_bin=$flex_sdk/bin
export debug=false
export logging=false

export subtitles_plugin=../SubtitlesPlugin
export advertisement_plugin=../AdvertisementPlugin
export grind_framework=../GrindFramework

export build_dir=build
[ -d $build_dir/libs ] || mkdir -p $build_dir/libs

