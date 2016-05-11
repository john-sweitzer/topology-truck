#!/bin/bash
export STAGE=${2:-acceptance}
export PHASE=${1:-provision}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR
mkdir -p "data_bags/topologies"


if [ "$PHASE" == "publish" ]; then
  # reset topo data bag
  cp "fixtures/topologies/singlenode_default.json" "data_bags/topologies/singlenode_default.json"
  # setup test repo with two commits
  rm -rf ".git"
  rm -rf "topologies"
  git init
  mkdir -p "topologies/SingleNode"
  cp "fixtures/topologies/singlenode_default.json" "topologies/SingleNode/singlenode_default.json"
  cp "fixtures/topologies/twonode_default.json" "topologies/SingleNode/twonode_default.json"
  git add -f "topologies"
  git commit -m "Initial commit"
  cp "fixtures/topologies/singlenode_default2.json" "topologies/SingleNode/singlenode_default.json"
  git add -f topologies
  git commit -m "Update single node topo"
else
  # create topo data bag only if it doesnt exist
  cp -n "fixtures/topologies/singlenode_default.json" "data_bags/topologies/singlenode_default.json"
fi

(berks vendor cookbooks && vagrant up && 
  chef-client -z -o "test_setup,topology-truck::$PHASE" -j dna.json -Fdoc)

# cleanup
rm -rf ".git"
  