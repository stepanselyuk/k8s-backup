#!/usr/bin/env bash

if [ "$(uname)" == "Darwin" ] && [ -z "$(command -v gdate)" ]; then
    echo "Please install GNU tools: brew install coreutils gnu-sed gnu-tar"
    exit 1
fi

doit() {
  read -r -n1 -e -p "$1 [y,n]: " answer
  case $answer in
  y | Y) echo yes ;;
  n | N) echo no ;;
  *) echo dont know ;;
  esac
}

# debug switch
#N=`gdate +%s%N`
#export PS4='+[$(((`gdate +%s%N`-$N)/1000000))ms][${BASH_SOURCE}:${LINENO}]: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'; set -x;

ROOT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )

SUFFIX=""

if [ -n "$1" ]; then
  SUFFIX="$1"
fi

if [ "$(uname)" == "Linux" ]; then
  SED_BIN="sed"
fi

if [ "$(uname)" == "Darwin" ]; then
  SED_BIN="gsed"
fi

# https://github.com/drbild/json2yaml
# sudo pip install json2yaml

# https://stedolan.github.io/jq/download/

# gsed - GNU version of sed installed via brew.

branch=$(date +"%Y-%m-%d")

# https://github.com/benlinton/slugify

if [ -n "$SUFFIX" ]; then
  SUFFIX=$(./_slugify.sh -acd "$SUFFIX")
  branch="$branch-$SUFFIX"
fi

# create new branch
git checkout -b "$branch"

BACKUPS_DIRECTORY="./backup"
mkdir -p "$BACKUPS_DIRECTORY"

BACKUPS_DIRECTORY_REAL=$(realpath "$BACKUPS_DIRECTORY")
echo "$BACKUPS_DIRECTORY_REAL"

cd "$BACKUPS_DIRECTORY" || exit 101

### DOWNLOADING MANIFESTS IN BUNDLES ###

# cluster resources

NAMES="$(
  kubectl api-resources --namespaced=false --verbs list -o name |
    sort |
    uniq |
    tr '\n' ,
)"

echo "Cluster resources: ${NAMES:0:-1}"
echo

kubectl get "${NAMES:0:-1}" --ignore-not-found -o json >_cluster.json

# namespaced resources

NAMES="$(
  kubectl api-resources --namespaced=true --verbs list -o name |
    grep -v "events.events.k8s.io" |
    grep -v "events" |
    sort |
    uniq |
    tr '\n' ,
)"

echo "Namespaced resources: ${NAMES:0:-1}"
echo

for ns in $(kubectl get ns -o name | $SED_BIN --expression='s/namespace\///g'); do

  echo "Namespace: $ns"

  mkdir -p "${ns}"

  kubectl --namespace="${ns}" get "${NAMES:0:-1}" --ignore-not-found -o json >"./${ns}/_bundle.json"

done

echo "===== Resources downloaded."

### CONVERTING/SEPARATING MANIFESTS ###

cd "$ROOT_DIR/converter" || exit 104

# install python packages
make install-deps

### PARSING CLUSTER JSON BUNDLE ###

make run INPUT_FILENAME="$BACKUPS_DIRECTORY_REAL/_cluster.json"

### PARSING NAMESPACES JSON BUNDLE ###

for ns in $(kubectl get ns -o name | $SED_BIN --expression='s/namespace\///g'); do

  echo "Namespace: $ns"

  make run INPUT_FILENAME="$BACKUPS_DIRECTORY_REAL/${ns}/_bundle.json"

done

cd "$ROOT_DIR" || exit 103

#git add .
#git commit -am "Backup ${branch}"
#git push -u origin "$branch"
