#!/bin/bash

result=$(curl -X POST -H "Content-type: application/json" -H "Accept:application/json" -H "Authorization: Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiIxYWQ3NjUxYy0zNzkwLTQ3ZWMtOTkxNC0xMjdlMDM0MTEyM2QiLCJkb21haW4iOiJ0ZXN0c2lnbWEuY29tIn0.5PsU_F4jTipqncDc0MyZbEA3mKflqkrvRGe06A6BbdaOwEz1wHExGR_mmn41FBjQygXVgLGv6RqZIVLTNpgv0w" https://app.testsigma.com/api/v1/execution_results -d "{\"executionId\": \"2090\"}")

echo "result: '$result'"
