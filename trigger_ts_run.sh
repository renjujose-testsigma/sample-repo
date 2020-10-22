#!/bin/bash

TESTSIGMA_USER_NAME=renju.jose@testsigma.com
TESTSIGMA_PASSWORD=testsigma123
TESTSIGMA_TEST_PLAN_RUN_URL=https://app.testsigma.com/rest/execution/2438/run
MAX_WAIT_TIME_FOR_SCRIPT_TO_EXIT=180
#********END USER_INPUTS***********

get_status(){
    RUN_RESPONSE=$(curl -u $TESTSIGMA_USER_NAME:$TESTSIGMA_PASSWORD --silent --write-out "HTTPSTATUS:%{http_code}" -X GET $TESTSIGMA_TEST_PLAN_RUN_URL/$HTTP_BODY/status)
    echo "Status_Response_Complete: $RUN_RESPONSE "
    # extract the body
    RUN_BODY=$(echo $RUN_RESPONSE | sed -e 's/HTTPSTATUS\:.*//g')
    # extract the status
    RUN_STATUS=$(echo $RUN_RESPONSE | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    echo "Response_Status: $RUN_STATUS"
    # print the body
    echo "Run Status..."
    echo "$RUN_BODY"
    EXECUTION_STATUS=$(echo $RUN_BODY | getJsonValue status)

    echo "Execution Status: $EXECUTION_STATUS"


}
function checkTestPlanRunStatus(){
  IS_TEST_RUN_COMPLETED=0
  for((i=0; i<= NO_OF_POLLS;i++))
  do
    get_status
    if [ $EXECUTION_STATUS -eq 2 ]
     then
      echo "Sleep/Wait for $SLEEP_TIME seconds before next poll....."
      sleep $SLEEP_TIME

    else
      IS_TEST_RUN_COMPLETED=1
      echo "Automated Tests Execution completed...\n total script execution time:$(((i+1)*SLEEP_TIME/60)) minutes"
      break
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

function exitcode(){

}



echo "************Testsigma:Start executing automated tests ... ************"

##########GLOBAL variables####################################################
POLL_INTERVAL_FOR_RUN_STATUS=3
NO_OF_POLLS=$((MAX_WAIT_TIME_FOR_SCRIPT_TO_EXIT/POLL_INTERVAL_FOR_RUN_STATUS))
SLEEP_TIME=$((POLL_INTERVAL_FOR_RUN_STATUS * 60))
JSON_FILE_NAME=testsigma.json
REPORT_FILE_NAME=$JSON_OUTPUT_REPORTS_DIR/$JSON_FILE_NAME
LOG_CONTENT=""
##############################################################################
echo "NO of polls $NO_OF_POLLS"
# store the whole response with the status at the and
HTTP_RESPONSE=$(curl -u $TESTSIGMA_USER_NAME:$TESTSIGMA_PASSWORD --silent --write-out "HTTPSTATUS:%{http_code}" -X POST $TESTSIGMA_TEST_PLAN_RUN_URL)
# extract the body
echo "HTTP_RESPONSE=$HTTP_RESPONSE \n"
HTTP_BODY=$(echo $HTTP_RESPONSE | sed -e 's/HTTPSTATUS\:.*//g')
# extract the status
HTTP_STATUS=$(echo $HTTP_RESPONSE | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

# print the body
echo "Run_ID:$HTTP_BODY"

# example using the status
if [ ! $HTTP_STATUS -eq 200  ]; then

  echo "Failed to executed automated tests!!"
  echo "Error [HTTP status: $HTTP_STATUS]"
  exit 1 #Exit with a failure.
else
  checkTestPlanRunStatus
  saveFinalResponseToAFile

fi

echo "Final response: $RUN_BODY"
echo "************Testsigma:Completed executing automated tests ... ************"
