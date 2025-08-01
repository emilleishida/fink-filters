#!/bin/bash
# Copyright 2022-2025 AstroLab Software
# Author: Julien Peloton
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
## Script to launch the python test suite and measure the coverage.
## Must be launched as fink_test
set -e

SERROR="\xE2\x9D\x8C"

message_help="""
Run the test suite of the modules\n\n
Usage:\n
    \t./run_tests.sh [-s <survey>] [--single_module]\n\n

Note you need Spark 3.1.3+ installed to fully test the modules.
"""

export ROOTPATH=`pwd`
# Grab the command line arguments
NO_SPARK=false
while [ "$#" -gt 0 ]; do
  case "$1" in
    -h)
      echo -e $message_help
      exit
      ;;
    -s)
      SURVEY=$2
      shift 2
      ;;
    --single_module)
      SINGLE_MODULE_PATH=$2
      shift 2
      ;;
  esac
done

# Add coverage_daemon to the pythonpath.
export PYTHONPATH="${SPARK_HOME}/python/test_coverage:$PYTHONPATH"
export COVERAGE_PROCESS_START="${ROOTPATH}/.coveragerc"

# single module testing
if [[ -n "${SINGLE_MODULE_PATH}" ]]; then
  coverage run \
   --source=${ROOTPATH} \
   --rcfile ${ROOTPATH}/.coveragerc ${SINGLE_MODULE_PATH}

  # Combine individual reports in one
  coverage combine

  unset COVERAGE_PROCESS_START

  coverage report -m
  coverage html

  exit 0

fi

# Run the test suite on the utilities
for filename in fink_filters/*.py
do
  # Run test suite + coverage
  coverage run \
    --source=${ROOTPATH} \
    --rcfile ${ROOTPATH}/.coveragerc $filename
done

if [[ $SURVEY == "" ]]; then
  echo -e "${SERROR} You need to specify a survey, e.g. ./run_test.sh -s ztf [options]"
  exit 1
fi

# Run the test for classification
for filename in fink_filters/${SURVEY}/*.py
do
  echo $filename
  # Run test suite + coverage
  coverage run \
    --source=${ROOTPATH} \
    --rcfile ${ROOTPATH}/.coveragerc $filename
done


# Run the test suite for after the night filters
for filename in fink_filters/${SURVEY}/filter_*/*.py
do
  echo $filename
  # Run test suite + coverage
  coverage run \
    --source=${ROOTPATH} \
    --rcfile ${ROOTPATH}/.coveragerc $filename
done

# Run the test suite for livestream filters
for filename in fink_filters/${SURVEY}/livestream/*/*.py
do
  echo $filename
  # Run test suite + coverage
  coverage run \
    --source=${ROOTPATH} \
    --rcfile ${ROOTPATH}/.coveragerc $filename
done


# Combine individual reports in one
coverage combine

unset COVERAGE_PROCESS_START

coverage report
coverage html
