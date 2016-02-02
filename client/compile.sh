#!/bin/bash

# Crypton Client, Copyright 2013, 2014, 2015 SpiderOak, Inc.
#
# This file is part of Crypton Client.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# cross-platform way to grab this script's directory
pushd `dirname $0` > /dev/null
SCRIPT_PATH=`pwd -P`
popd > /dev/null
UGLIFY_PATH="$SCRIPT_PATH/node_modules/uglify-js/bin/uglifyjs"
JSON_PATH="$SCRIPT_PATH/node_modules/.bin/json"

has_md5 () {
  for PROG in md5 md5sum; do
    if which $PROG >/dev/null 2>&1; then
       MD5=$PROG
       break
    fi
  done

  if [[ -z $MD5 ]]; then
    echo "No suitable MD5 program found; install one of md5 or md5sum"
    exit 1
  fi
}

has_uglify () {
  if [ ! -f $UGLIFY_PATH ]; then
    if [ $1 ]; then
      echo "Uglifyjs installation failed. Please install it manually."
      exit 1
    fi

    echo "Uglifyjs not found. Attempting to install it..."
    cd $SCRIPT_PATH
    npm install &> /dev/null
    has_uglify 1
  fi
}

has_json() {
  if [ ! -f $UGLIFY_PATH ]; then
    if [ $1 ]; then
      echo "Json installation failed. Please install it manually."
      exit 1
    fi

    echo "Json not found. Attempting to install it..."
    cd $SCRIPT_PATH
    npm install &> /dev/null
    has_json 1
  fi
}

daemon () {
  chsum1=""

  while [[ true ]]
  do
    chsum2=`find src/ -type f -exec $MD5 {} \;`
    if [[ $chsum1 != $chsum2 ]] ; then
      compile
      chsum1=`find src/ -type f -exec $MD5 {} \;`
      echo "Watching..."
    fi
    sleep 2
  done
}

compile () {
  echo "Compiling client code to crypton.js..."
  VERSION=`cat $SCRIPT_PATH/package.json | $JSON_PATH version`
  mkdir -p dist
  cat \
    $SCRIPT_PATH/src/core.js \
    $SCRIPT_PATH/src/account.js \
    $SCRIPT_PATH/src/session.js \
    $SCRIPT_PATH/src/container.js \
    $SCRIPT_PATH/src/transaction.js \
    $SCRIPT_PATH/src/peer.js \
    $SCRIPT_PATH/src/message.js \
    $SCRIPT_PATH/src/inbox.js \
    $SCRIPT_PATH/src/diff.js \
    $SCRIPT_PATH/src/work.js \
    $SCRIPT_PATH/src/card.js \
    $SCRIPT_PATH/src/item.js \
    $SCRIPT_PATH/src/history.js \
    $SCRIPT_PATH/src/errors.js \
    $SCRIPT_PATH/node_modules/bcryptjs/dist/bcrypt.js \
    $SCRIPT_PATH/node_modules/circular-json/build/circular-json.js \
    $SCRIPT_PATH/src/vendor/*.js \
    | sed 's/PACKAGE_VERSION/'$VERSION'/' \
    > dist/crypton.js
  $UGLIFY_PATH dist/crypton.js > dist/crypton.min.js
}

case $1 in
  --once)
    has_uglify
    compile
    ;;
  *)
    has_md5
    has_uglify
    daemon
    ;;
esac
