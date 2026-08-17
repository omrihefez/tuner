#!/bin/bash
set -euo pipefail
TOKEN=$(node -e "console.log(require('/home/omri/.local/share/com.vercel.cli/auth.json').token)")
curl -sf "https://api.vercel.com/v9/projects/prj_Se9EWsbcw9VUJKDVNuWh7tw65nPR?teamId=team_1JqV1IChqxsh933CUDYmVvGQ" \
  -H "Authorization: Bearer $TOKEN" | grep -q '"type":"github"'
