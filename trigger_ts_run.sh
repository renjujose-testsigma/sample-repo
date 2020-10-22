#!/bin/bash
#********START USER_INPUTS*********
TESTSIGMA_USER_NAME=renju.jose@testsigma.com
TESTSIGMA_PASSWORD=testsigma123
TESTSIGMA_TEST_PLAN_RUN_URL=https://app.testsigma.com/rest/execution/2090/run
MAX_WAIT_TIME_FOR_SCRIPT_TO_EXIT=60
#********END USER_INPUTS***********
##########GLOBAL variables####################################################
POLL_INTERVAL_FOR_RUN_STATUS=1
NO_OF_POLLS=$((MAX_WAIT_TIME_FOR_SCRIPT_TO_EXIT/POLL_INTERVAL_FOR_RUN_STATUS))
SLEEP_TIME=$((POLL_INTERVAL_FOR_RUN_STATUS * 10))
JSON_FILE_NAME=testsigma.json
REPORT_FILE_NAME=$JSON_OUTPUT_REPORTS_DIR/$JSON_FILE_NAME
LOG_CONTENT=""
##############################################################################

#####################FUNCTIONS########################
function get_status(){
    RUN_RESPONSE=$(curl -u $TESTSIGMA_USER_NAME:$TESTSIGMA_PASSWORD --silent --write-out "HTTPSTATUS:%{http_code}" -X GET $TESTSIGMA_TEST_PLAN_RUN_URL/$HTTP_BODY/status)
    # extract the body
    RUN_BODY=$(echo $RUN_RESPONSE | sed -e 's/HTTPSTATUS\:.*//g')
    # extract the response status
    RUN_STATUS=$(echo $RUN_RESPONSE | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    # extract exec status
    EXECUTION_STATUS=$(echo $RUN_BODY | getJsonValue status)
}

function checkTestPlanRunStatus(){
  IS_TEST_RUN_COMPLETED=0
  for ((i=0;i<=NO_OF_POLLS;i++))
  do
    get_status
    if [ $EXECUTION_STATUS -eq 2 ]; then
      echo "Poll #$(($i+1)) - Test Execution in progress... Wait for $SLEEP_TIME seconds before next poll.."
      sleep $SLEEP_TIME
    elif [ $EXECUTION_STATUS -eq 0 ]; then
      IS_TEST_RUN_COMPLETED=1
      echo "Poll #$(($i+1)) - Tests Execution completed..."
      TOTALRUNSECONDS=$(($(($i+1))*$SLEEP_TIME))
      echo "Total script run time: $(convertsecs $TOTALRUNSECONDS)"
      break
    else
      echo "Unexpected Execution status. Please check run results for more details."
    fi
  done
}

function saveFinalResponseToAFile(){
  if [ $IS_TEST_RUN_COMPLETED -eq 0 ]
     then
      LOG_CONTENT="Wait time exceeded specified maximum time(MAX_WAIT_TIME_FOR_SCRIPT_TO_EXIT). Please log-in to Testsigma to check Test Plan run status.
      You can visit the URL specified in \"app_url\" JSON param For landing in Test Plan run page directly.
      Ex: \"app_url\":\"https://dev.testsigma.com/#/projects/31/applications/53/version/72/report/executions/197/runs/819/environments\""

    fi
echo "Reports dir::$REPORT_FILE_NAME"
echo "$LOG_CONTENT \n $RUN_BODY"
echo "$RUN_BODY" >> $REPORT_FILE_NAME
}

function getJsonValue() {
json_key=$1
awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/\042'$json_key'\042/){print $(i+1)}}}' | tr -d '"'
}

function convertsecs(){
  ((h=${1}/3600))
  ((m=(${1}%3600)/60))
  ((s=${1}%60))
  printf "%02d hours %02d minutes %02d seconds" $h $m $s
}
######################################################

echo "************Testsigma:Start executing automated tests ... ************"

# store the whole response with the status at the end
HTTP_RESPONSE=$(curl -u $TESTSIGMA_USER_NAME:$TESTSIGMA_PASSWORD --silent --write-out "HTTPSTATUS:%{http_code}" -X POST $TESTSIGMA_TEST_PLAN_RUN_URL)

# extract the body
HTTP_BODY=$(echo $HTTP_RESPONSE | sed -e 's/HTTPSTATUS\:.*//g')

# extract the status
HTTP_STATUS=$(echo $HTTP_RESPONSE | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

# print the body
NUMBERS_REGEX="^[0-9].*"
if [[ $HTTP_BODY =~ $NUMBERS_REGEX ]]; then
  echo "Run ID: $HTTP_BODY"
else
  echo "$HTTP_BODY"
fi

# example using the status
if [ ! $HTTP_STATUS -eq 200  ]; then
  echo "Failed to start Test Plan execution! Status Code: $HTTP_STATUS"
  exit 1 #Exit with a failure.
else
  echo "Number of maximum polls to be done: $NO_OF_POLLS"
  checkTestPlanRunStatus
fi

echo "************************************************"
echo "Result JSON Response: $RUN_BODY"
echo "************Testsigma:Completed executing automated tests ... ************"