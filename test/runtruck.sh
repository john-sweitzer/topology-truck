#!/bin/bash
export STAGE=${2:-acceptance}
export PHASE=${1:-provision}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
(cd $DIR && berks vendor cookbooks && vagrant up && 
  chef-client -z -o "test_setup,topology-truck::$PHASE" -j dna.json -Fdoc)
