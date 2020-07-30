#!/bin/bash

# script runs with 
#   api-key = to send result to the api
#   course-test-url = private repo with tests
#   user-key = token to download private repos

# script will clone student solution and tests
# move tests to student lessons dirs
# run tests for each lesson
# send result to the api with lesson name, course name, username

# GITHUB_REPOSITORY = url to the repo 
# GITHUB_ACTOR = username

# python-introduction-template
# variables-and-types
#  - hello.py
 
# test-python-introduction !private
# test-variables-and-types
#  - hello_test.py

set -ue

API_KEY=$1
COURSE_TEST_URL=$2
USER_KEY=$3

export INPUT_GRADE="good job, contact me @frozen6heart"
export INPUT_URL="good job, contact me @frozen6heart"
export INPUT_TOKEN="good job, contact me @frozen6heart"

TEST=${COURSE_TEST_URL##*/test-}
TEST_FULL="$TEST/test-"
SOLUTION="solution"

SOLUTION_URL="https://github.com/${GITHUB_REPOSITORY}"
TEST_URL="https://$USER_KEY@github.com/${COURSE_TEST_URL}"

printf "📝 hello $GITHUB_ACTOR\n"
printf "⚙️  building enviroment\n"
printf "⚙️  cloning solutions\n"
git clone $SOLUTION_URL $SOLUTION
git clone $TEST_URL $TEST
printf "⚙️  cloning finished\n"

# copy test file to solution dirs
find $TEST -type f -name '*test*' -print0 | xargs -n 1 -0 -I {} bash -c 'set -e; f={}; cp $f $0/${f:$1}' $SOLUTION ${#TEST_FULL}
curl_js=$(curl -w '' -s https://lrn.dev/api/curriculum/courses/168 | jq -c '.lessons[] | select(.type=="project") | {name: .name, index: .index}')
# list of all dirs
z=$(find $TEST -mindepth 1 -maxdepth 1 -type d -name "test*" -print0 | xargs -n 1 -0 -I {} bash -c 't={}; printf "${t##$0/test-}\n"' $TEST)

send_result(){
    data=$(jq -aRs . <<< ${5})
    # apikey user lesson status logs
    curl -s -X POST "https://lrn.dev/api/service/grade" -H "x-grade-secret: ${1}" -H "accept: application/json" -H "Content-Type: application/json" -d "{\"username\":\"${2}\", \"lesson\":\"${3}\", \"status\": \"${4}\", \"logs\": ${data}}" > /dev/null
}

for project in $curl_js; do
    LESSON_NAME=$(echo $project | jq -r '.name' | sed s/-js-intro//g)
    echo $LESSON_NAME

    FILENAME=$(find "$SOLUTION/$LESSON_NAME" -type f -name "*test*" -print0 | xargs -n 1 -0 -I {} bash -c 't={}; printf "$t"')
    set +e
    result=$(node $FILENAME)
    last="$?"
    echo ${result}
    set -e
    if [[ $last -eq 0 ]]; then
        printf "✅ $LESSON_NAME-$TEST tests passed 💞\n"
        send_result $API_KEY $GITHUB_ACTOR $LESSON_NAME-$TEST "done" "${result}"
    else
        printf "🚫 $LESSON_NAME-$TEST tests failed 💔\n"
        send_result $API_KEY $GITHUB_ACTOR $LESSON_NAME-$TEST "failed" "${result}"
        exit 1
    fi

done

printf "👾👾👾 done 👾👾👾\n"
