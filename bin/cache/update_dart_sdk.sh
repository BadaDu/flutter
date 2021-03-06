#!/bin/bash
# Copyright 2016 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

FLUTTER_ROOT=$(dirname $(dirname $(dirname "${BASH_SOURCE[0]}")))

DART_SDK_PATH="$FLUTTER_ROOT/bin/cache/dart-sdk"
DART_SDK_STAMP_PATH="$FLUTTER_ROOT/bin/cache/dart-sdk.stamp"
DART_SDK_VERSION=`cat "$FLUTTER_ROOT/bin/cache/dart-sdk.version"`

if [ ! -f "$DART_SDK_STAMP_PATH" ] || [ "$DART_SDK_VERSION" != `cat "$DART_SDK_STAMP_PATH"` ]; then
  echo "Downloading Dart SDK $DART_SDK_VERSION..."

  case "$(uname -s)" in
    Darwin)
      DART_ZIP_NAME="dartsdk-macos-x64-release.zip"
      ;;
    Linux)
      DART_ZIP_NAME="dartsdk-linux-x64-release.zip"
      ;;
    *)
      echo "Unknown operating system. Cannot install Dart SDK."
      exit 1
      ;;
  esac

  DART_CHANNEL="stable"

  if [[ $DART_SDK_VERSION == *"-dev."* ]]
  then
    DART_CHANNEL="dev"
  fi

  DART_SDK_URL="http://storage.googleapis.com/dart-archive/channels/$DART_CHANNEL/raw/$DART_SDK_VERSION/sdk/$DART_ZIP_NAME"

  rm -rf -- "$DART_SDK_PATH"
  mkdir -p -- "$DART_SDK_PATH"
  DART_SDK_ZIP="$FLUTTER_ROOT/bin/cache/dart-sdk.zip"

  curl --progress-bar -continue-at=- --location --output "$DART_SDK_ZIP" "$DART_SDK_URL"
  unzip -o -q "$DART_SDK_ZIP" -d "$FLUTTER_ROOT/bin/cache"
  rm -f -- "$DART_SDK_ZIP"
  echo "$DART_SDK_VERSION" > "$DART_SDK_STAMP_PATH"
fi
