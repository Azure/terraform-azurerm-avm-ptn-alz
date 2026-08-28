---
description: |
  Automated issue triage for Azure Verified Modules Terraform module repositories. Checks for duplicates, classifies issues with existing repo labels, discovers related pull requests, links clear fixes, closes issues that are conclusively resolved, and posts a triage summary comment on new, reopened, or manually selected issues.
network:
  allowed:
  - defaults
  - github
  - learn.microsoft.com
  - registry.terraform.io
  - terraform
# Run on new issues, reopened issues, allow manual reruns
"on":
  issues:
    types:
    - opened
    - reopened
  roles: all
  workflow_dispatch:
    inputs:
      issue_number:
        description: 'Issue number to triage (required for on-demand manual runs)'
        required: true
        type: string
# The compiler-generated agent, output and conclusion jobs share a static
# concurrency group per workflow. `features.group-concurrency-queue: false`
# below strips `queue: max` from those groups, so Actions applies its default
# `single` queueing and keeps only the newest pending run — a third arrival
# discards the middle one. Fanning several issues out at once therefore lost
# conclusion jobs and their failure reports. Discriminating by issue number
# gives each dispatched run its own group. Stripped from the compiled lock.
concurrency:
  group: "gh-aw-${{ github.workflow }}-${{ github.event.inputs.issue_number || github.event.issue.number || github.run_id }}"
  job-discriminator: ${{ github.event.inputs.issue_number || github.event.issue.number || github.run_id }}
# Read-only permissions for triage
permissions:
  contents: read
  issues: read
  models: read
  pull-requests: read
  copilot-requests: write
features:
  group-concurrency-queue: false
engine:
  model: claude-sonnet-5
safe-outputs:
  add-comment:
    max: 1
    target: "*"
    hide-older-comments: true
  add-labels:
    max: 10
    target: "*"
    # Opt out of issue-intent metadata (ADR-46207 flipped this default to on).
    # When enabled, labels are sent via the GraphQL `update_issue_suggestions`
    # path, where GitHub records anything below HIGH confidence as a suggestion
    # instead of applying it — while gh-aw still logs "Successfully added N
    # labels". Forcing the REST path applies every label the agent selects.
    issue-intent: false
  set-issue-type:
    allowed:
    - Bug
    - Feature
    - Task
    max: 1
    target: "*"
    issue-intent: false
  close-issue:
    max: 1
    target: "*"
    # List form lets the agent pick the reason per closure. A scalar would lock
    # every closure to one reason, which recorded fix-confirmed closures as
    # "duplicate". The first entry is the fallback when the agent omits one.
    state-reason:
    - duplicate
    - completed
  update-pull-request:
    title: false
    body: true
    operation: append
    footer: false
    max: 1
    target: "*"
  threat-detection:
    # Same workaround as the agent job below; custom `steps:` only inject into
    # the agent job, so the detection job needs its own copy. A failed detection
    # install yields conclusion=warning, which blocks every non-reviewable safe
    # output (add-labels, set-issue-type, close-issue) under policy WTD3.
    steps:
    - name: Force Copilot CLI download (workaround github/gh-aw#52327)
      run: sudo rm -rf /opt/hostedtoolcache/copilot-cli || true
steps:
# Workaround for github/gh-aw#52327: when the installer finds a cached
# copilot-cli within its 14-day TTL it only prepends the cache dir to PATH and
# never writes /usr/local/bin/copilot, but the agent harness spawns that exact
# path and fails with ENOENT. Removing the cache forces the download branch,
# which does write /usr/local/bin/copilot. Remove once upstream is fixed.
- name: Force Copilot CLI download (workaround github/gh-aw#52327)
  run: sudo rm -rf /opt/hostedtoolcache/copilot-cli || true
- env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  name: Fetch label definitions
  run: |
    mkdir -p /tmp/gh-aw/agent
    LABELS_FILE=/tmp/gh-aw/agent/repo-labels.json
    gh api "repos/${{ github.repository }}/labels?per_page=100" | jq '[.[] | {name, description}]' > "$LABELS_FILE" || echo '[]' > "$LABELS_FILE"
- name: Resolve target issue number
  env:
    ISSUE_NUMBER: ${{ github.event.inputs.issue_number || github.event.issue.number }}
  run: |
    echo "${ISSUE_NUMBER}" > /tmp/gh-aw/agent/issue-number.txt
- name: Fetch current issue type
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    GH_AW_GITHUB_REPOSITORY: ${{ github.repository }}
    ISSUE_NUMBER: ${{ github.event.inputs.issue_number || github.event.issue.number }}
  run: |
    set -o pipefail
    TYPE_FILE=/tmp/gh-aw/agent/issue-type.txt
    RAW=$(mktemp)
    # The agent's issue-reading tool does not return the native issue type, and
    # the `Type: …` labels and the template's "### Issue Type?" field are not it.
    if gh api "repos/${GH_AW_GITHUB_REPOSITORY}/issues/${ISSUE_NUMBER}" \
      --jq '.type.name // "NONE"' > "${RAW}"; then
      tr -d '\r' < "${RAW}" | head -n 1 > "${TYPE_FILE}"
    else
      echo "UNKNOWN" > "${TYPE_FILE}"
    fi
    rm -f "${RAW}"
- name: Fetch release status
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    GH_AW_GITHUB_REPOSITORY: ${{ github.repository }}
    DEFAULT_BRANCH: ${{ github.event.repository.default_branch }}
  run: |
    set -o pipefail
    OUT=/tmp/gh-aw/agent/release-status.json
    # Comparing the newest release tag against the default branch yields exactly
    # the commits that are merged but not yet released. Membership in that set is
    # the whole released/unreleased question, decided here rather than inferred.
    #
    # The newest release is picked by sorting on published_at rather than asking
    # /releases/latest, which does not always agree: on
    # terraform-azurerm-avm-res-netapp-netappaccount it answers 0.2.0 (May 2025)
    # while v0.3.0 (Dec 2025) is the real newest. Comparing against a stale tag
    # makes already-released fixes look unreleased, which is the wrong direction
    # to be wrong in — it would label an issue as awaiting a release that exists.
    LATEST=$(mktemp)
    if ! gh api --paginate "repos/${GH_AW_GITHUB_REPOSITORY}/releases?per_page=100" > "${LATEST}" 2>/dev/null; then
      printf '%s\n' '{"loaded":false,"has_release":null,"latest_tag":null,"latest_published_at":null,"ahead_by":0,"unreleased_shas":[],"unreleased_pr_numbers":[]}' > "${OUT}"
      rm -f "${LATEST}"
      exit 0
    fi
    # --paginate concatenates one array per page, so flatten before sorting.
    NEWEST=$(jq -s -r '
      [ .[][]? | select((.draft | not) and (.prerelease | not)) ]
      | sort_by(.published_at)
      | last
      | if . == null then "" else "\(.tag_name)\t\(.published_at)" end
    ' "${LATEST}" 2>/dev/null | tr -d '\r' | head -n 1)
    rm -f "${LATEST}"
    TAG=${NEWEST%%$'\t'*}
    PUB=${NEWEST#*$'\t'}
    if [ "${PUB}" = "${TAG}" ]; then PUB=""; fi
    if [ -z "${TAG}" ]; then
      printf '%s\n' '{"loaded":true,"has_release":false,"latest_tag":null,"latest_published_at":null,"ahead_by":0,"unreleased_shas":[],"unreleased_pr_numbers":[]}' > "${OUT}"
      exit 0
    fi
    CMP=$(mktemp)
    if gh api "repos/${GH_AW_GITHUB_REPOSITORY}/compare/${TAG}...${DEFAULT_BRANCH}" > "${CMP}" 2>/dev/null &&
       jq -e 'type == "object" and has("commits")' "${CMP}" > /dev/null 2>&1; then
      jq --arg tag "${TAG}" --arg pub "${PUB}" '{
        loaded: true,
        has_release: true,
        latest_tag: $tag,
        latest_published_at: $pub,
        ahead_by: (.ahead_by // 0),
        unreleased_shas: [.commits[]?.sha],
        unreleased_pr_numbers: ([.commits[]?.commit.message | scan("#([0-9]+)") | .[0] | tonumber] | unique)
      }' "${CMP}" > "${OUT}" ||
        printf '%s\n' "{\"loaded\":false,\"has_release\":true,\"latest_tag\":\"${TAG}\"}" > "${OUT}"
    else
      printf '%s\n' "{\"loaded\":false,\"has_release\":true,\"latest_tag\":\"${TAG}\"}" > "${OUT}"
    fi
    rm -f "${CMP}"
- name: Fetch issue close and reopen history
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    GH_AW_GITHUB_REPOSITORY: ${{ github.repository }}
    ISSUE_NUMBER: ${{ github.event.inputs.issue_number || github.event.issue.number }}
  run: |
    set -o pipefail
    HISTORY_FILE=/tmp/gh-aw/agent/issue-state-history.json
    EVENTS_FILE=$(mktemp)
    if gh api --paginate "repos/${GH_AW_GITHUB_REPOSITORY}/issues/${ISSUE_NUMBER}/events?per_page=100" \
      | jq -s '[.[][] | select(.event == "closed" or .event == "reopened") | {
          event,
          created_at,
          actor: {
            login: .actor.login,
            type: .actor.type
          }
        }]' > "${EVENTS_FILE}"; then
      jq -n --slurpfile events "${EVENTS_FILE}" '{loaded: true, events: $events[0]}' > "${HISTORY_FILE}"
    else
      echo '{"loaded":false,"events":[]}' > "${HISTORY_FILE}"
    fi
    rm -f "${EVENTS_FILE}"
- name: Prefetch PR candidate evidence for target issue
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    GH_AW_GITHUB_REPOSITORY: ${{ github.repository }}
    ISSUE_NUMBER: ${{ github.event.inputs.issue_number || github.event.issue.number }}
  run: |
    set -o pipefail
    mkdir -p /tmp/gh-aw/agent
    STATUS_FILE=/tmp/gh-aw/agent/pr-candidate-status.json
    INDEX_FILE=/tmp/gh-aw/agent/pr-candidate-screening-index.json
    INDEX_VERSION=1
    REPO="${GH_AW_GITHUB_REPOSITORY}"
    NUM="${ISSUE_NUMBER}"
    write_failure_contracts() {
      FAILURE_MESSAGE="$1"
      jq -n --arg issue "${NUM}" --arg repo "${REPO}" --arg error "${FAILURE_MESSAGE}" --argjson version "${INDEX_VERSION}" \
        '{
          version:$version,
          issue_number:($issue | tonumber? // $issue),
          repository:$repo,
          loaded:false,
          complete:false,
          success:false,
          errors:[$error],
          candidate_count:0,
          required_inspection:[],
          open_inventory_screening:[]
        }' > "${INDEX_FILE}"
      jq -n \
        --arg issue "${NUM}" \
        --arg repo "${REPO}" \
        --arg error "${FAILURE_MESSAGE}" \
        --arg index_path "${INDEX_FILE}" \
        --argjson index_version "${INDEX_VERSION}" \
        '{
          issue_number:($issue | tonumber? // $issue),
          repository:$repo,
          loaded:false,
          complete:false,
          success:false,
          errors:[$error],
          candidate_count:0,
          open_inventory_count:0,
          merged_inventory_count:0,
          required_inspection_count:0,
          required_inspection_numbers:[],
          exact_required_inspection_count:0,
          exact_required_inspection_numbers:[],
          timeline_required_inspection_count:0,
          timeline_required_inspection_numbers:[],
          commit_required_inspection_count:0,
          commit_required_inspection_numbers:[],
          screening_index_path:$index_path,
          index_version:$index_version
        }' > "${STATUS_FILE}"
    }
    if ! printf '%s' "${REPO}" | grep -Eq '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' \
      || ! printf '%s' "${NUM}" | grep -Eq '^[1-9][0-9]*$'; then
      write_failure_contracts "invalid repository or issue number"
      exit 0
    fi
    WORK_DIR=$(mktemp -d)
    CANDIDATES_JSONL="${WORK_DIR}/candidates.jsonl"
    ERRORS_FILE="${WORK_DIR}/errors.txt"
    : > "${CANDIDATES_JSONL}"
    : > "${ERRORS_FILE}"
    COMPLETE=true
    # Conservative fallback written up front: if this step dies before the final
    # write below, the agent still finds an honest "incomplete" file rather than a
    # stale or missing one, so it never treats a failed load as a false success.
    write_failure_contracts "prefetch step did not finish"
    record_error() {
      echo "$1" >> "${ERRORS_FILE}"
      COMPLETE=false
    }
    ISSUE_RAW="${WORK_DIR}/issue.json"
    if ! gh api "repos/${REPO}/issues/${NUM}" > "${ISSUE_RAW}" 2>>"${ERRORS_FILE}"; then
      echo '{"title":"","body":""}' > "${ISSUE_RAW}"
      record_error "issue metadata: gh api fetch failed for issue #${NUM}"
    fi
    # Source 1: issue timeline - cross-referenced PRs, including non-closing mentions.
    TIMELINE_RAW="${WORK_DIR}/timeline.jsonl"
    if gh api --paginate "repos/${REPO}/issues/${NUM}/timeline?per_page=100" > "${TIMELINE_RAW}" 2>>"${ERRORS_FILE}"; then
      jq -c -s --arg repo "${REPO}" '
        add // []
        | .[]
        | select(.event == "cross-referenced")
        | (.source.issue? // empty)
        | select(.repository_url == ("https://api.github.com/repos/" + $repo))
        | select(.pull_request != null)
        | {
            number: .number,
            title: .title,
            url: .html_url,
            state: (.state // "unknown" | ascii_upcase),
            draft: (.draft // false),
            merged: (.pull_request.merged_at != null),
            body: (.body // ""),
            source: "timeline_cross_reference",
            detail: "Timeline cross-reference on the issue (includes non-closing mentions)"
          }
      ' "${TIMELINE_RAW}" >> "${CANDIDATES_JSONL}" 2>>"${ERRORS_FILE}" || record_error "timeline: jq processing failed for issue #${NUM}"
    else
      record_error "timeline: gh api fetch failed for issue #${NUM}"
    fi
    # Sources 2-4: an exhaustive, paginated PR scan. It provides exact title/body
    # matches and commit references across every PR state, plus a compact inventory
    # of every currently open PR so reference-free fixes remain discoverable.
    GRAPHQL_QUERY="${WORK_DIR}/pr-scan.graphql"
    cat > "${GRAPHQL_QUERY}" <<'GRAPHQL_EOF'
    query($owner: String!, $repo: String!, $endCursor: String) {
      repository(owner: $owner, name: $repo) {
        pullRequests(first: 50, after: $endCursor, states: [OPEN, CLOSED, MERGED], orderBy: {field: UPDATED_AT, direction: DESC}) {
          pageInfo { hasNextPage endCursor }
          nodes {
            number
            title
            url
            state
            isDraft
            merged
            body
            commits(first: 100) {
              pageInfo { hasNextPage }
              nodes { commit { oid message } }
            }
            files(first: 30) {
              pageInfo { hasNextPage }
              nodes { path }
            }
            mergedAt
          }
        }
      }
    }
    GRAPHQL_EOF
    OWNER_NAME="${REPO%%/*}"
    REPO_NAME="${REPO##*/}"
    PR_SCAN_RAW="${WORK_DIR}/pr-scan.jsonl"
    # Recently merged PRs are inventoried alongside open ones so an issue that was
    # already fixed on the default branch can be recognised even when nothing in
    # the issue references the fixing PR. Bounded by age and count to keep the
    # candidate set reviewable on long-lived repositories.
    MERGED_CUTOFF="$(date -u -d '180 days ago' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo '1970-01-01T00:00:00Z')"
    if gh api graphql --paginate -F query="@${GRAPHQL_QUERY}" -f owner="${OWNER_NAME}" -f repo="${REPO_NAME}" > "${PR_SCAN_RAW}" 2>>"${ERRORS_FILE}"; then
      jq -c -s --arg num "${NUM}" --arg repo "${REPO}" --arg cutoff "${MERGED_CUTOFF}" '
        ("#" + $num + "\\b") as $numRef
        | ($repo + "#" + $num + "\\b") as $qualRef
        | ("(?i)\\b(refs?|fixes?|closes?|resolves?)\\b[[:space:]]*#" + $num + "\\b") as $bodyRef
        | [.[].data.repository.pullRequests.nodes[]?] as $prs
        | (
            [$prs[] | select((.merged == true) and ((.mergedAt // "") >= $cutoff))]
            | sort_by(.mergedAt) | reverse | .[0:25]
            | .[]
            | {number:.number, title:.title, url:.url, state:.state, draft:.isDraft, merged:.merged, body:(.body // ""),
               source:"merged_pr_inventory", detail:"Recently merged PR; screen for a fix that already shipped on the default branch",
               file_names:[.files.nodes[]?.path], files_truncated:(.files.pageInfo.hasNextPage // false)}
          ),
          (
          $prs[]
        | . as $pr
        | (
            (if $pr.state == "OPEN" then
              [{number:$pr.number, title:$pr.title, url:$pr.url, state:$pr.state, draft:$pr.isDraft, merged:$pr.merged, body:($pr.body // ""),
                source:"open_pr_inventory", detail:"Current open PR; screen title, body excerpt, and changed-file names for relevance",
                file_names:[$pr.files.nodes[]?.path], files_truncated:($pr.files.pageInfo.hasNextPage // false)}]
            else [] end)
            +
            (if (($pr.title // "") | test($numRef) or (($pr.title // "") | test($qualRef))) then
              [{number:$pr.number, title:$pr.title, url:$pr.url, state:$pr.state, draft:$pr.isDraft, merged:$pr.merged, body:($pr.body // ""), source:"issue_number_search_title", detail:("PR title contains #" + $num + " or a repo-qualified reference")}]
            else [] end)
            +
            (if (($pr.body // "") | test($numRef) or (($pr.body // "") | test($qualRef))) then
              [{number:$pr.number, title:$pr.title, url:$pr.url, state:$pr.state, draft:$pr.isDraft, merged:$pr.merged, body:($pr.body // ""), source:"issue_number_search_body", detail:("PR body contains #" + $num + " or a repo-qualified reference")}]
            else [] end)
            +
            [
              ($pr.commits.nodes[]? | .commit
               | select((.message | test($numRef)) or (.message | test($qualRef)))
               | {
                   number: $pr.number, title: $pr.title, url: $pr.url, state: $pr.state, draft: $pr.isDraft, merged: $pr.merged, body: ($pr.body // ""),
                   source: (if (.message | test($bodyRef)) then "commit_body_refs" else "commit_message_reference" end),
                   sha: .oid, message: .message,
                   detail: ("Commit message references #" + $num)
                 }
              )
            ]
          )
          | .[]
          )
      ' "${PR_SCAN_RAW}" >> "${CANDIDATES_JSONL}" 2>>"${ERRORS_FILE}" || record_error "graphql pr scan: jq processing failed for issue #${NUM}"
      TRUNCATED_COMMITS=$(jq -s '[.[].data.repository.pullRequests.nodes[]? | select(.commits.pageInfo.hasNextPage == true)] | length' "${PR_SCAN_RAW}" 2>>"${ERRORS_FILE}") \
        || { TRUNCATED_COMMITS=1; record_error "graphql pr scan: jq commit-pagination check failed"; }
      if [ "${TRUNCATED_COMMITS}" -gt 0 ]; then
        record_error "graphql pr scan: ${TRUNCATED_COMMITS} PR(s) have more than 100 commits; commit-reference evidence is incomplete"
      fi
      LAST_HAS_NEXT=$(jq -s '[.[].data.repository.pullRequests.pageInfo.hasNextPage] | last // false' "${PR_SCAN_RAW}" 2>>"${ERRORS_FILE}")
      if [ "${LAST_HAS_NEXT}" = "true" ]; then
        record_error "graphql pr scan: pagination did not complete (hasNextPage still true) - results may be partial"
      fi
    else
      record_error "graphql pr scan: gh api graphql fetch failed for repo ${REPO}"
    fi
    # Source 3: exact issue-number search across PR comments (all states, no date limit).
    for VARIANT in "#${NUM}" "${REPO}#${NUM}"; do
      SAFE_NAME=$(echo "${VARIANT}" | tr -c 'a-zA-Z0-9' '_')
      COMMENT_SEARCH_RAW="${WORK_DIR}/comment-search-${SAFE_NAME}.jsonl"
      if gh api --paginate --method GET search/issues -f q="repo:${REPO} is:pr in:comments \"${VARIANT}\"" > "${COMMENT_SEARCH_RAW}" 2>>"${ERRORS_FILE}"; then
        jq -c -s '
          [.[] | (.items // [])[]?]
          | .[]
          | {
              number: .number, title: .title, url: .html_url, state: (.state | ascii_upcase),
              draft: (.draft // false), merged: (.pull_request.merged_at != null),
              body: (.body // ""), source: "issue_number_search_comment",
              detail: "Matched via GitHub search in a PR comment"
            }
        ' "${COMMENT_SEARCH_RAW}" >> "${CANDIDATES_JSONL}" 2>>"${ERRORS_FILE}" || record_error "comment search: jq processing failed for variant ${VARIANT}"
        SEARCH_TOTAL=$(jq -s '[.[].total_count // 0] | max // 0' "${COMMENT_SEARCH_RAW}" 2>>"${ERRORS_FILE}") \
          || { SEARCH_TOTAL=1; record_error "comment search: jq total-count check failed for variant ${VARIANT}"; }
        SEARCH_COLLECTED=$(jq -s '[.[] | (.items // []) | length] | add // 0' "${COMMENT_SEARCH_RAW}" 2>>"${ERRORS_FILE}") \
          || { SEARCH_COLLECTED=0; record_error "comment search: jq result-count check failed for variant ${VARIANT}"; }
        if [ "${SEARCH_TOTAL}" -gt "${SEARCH_COLLECTED}" ]; then
          record_error "comment search: GitHub search returned ${SEARCH_COLLECTED} of ${SEARCH_TOTAL} results for ${VARIANT} (1000-result cap or incomplete pagination)"
        fi
      else
        record_error "comment search: gh api search fetch failed for variant ${VARIANT}"
      fi
    done
    # Merge and de-dupe by PR number, preserving every source and its evidence so
    # Step 6 can report related/partial PRs even when they are not linked.
    if [ -s "${CANDIDATES_JSONL}" ]; then
      jq -c -s '
        group_by(.number)
        | map({
            number: .[0].number,
            title: (first(.[] | select(.title != null and .title != "") | .title) // .[0].title),
            url: (first(.[] | select(.url != null and .url != "") | .url) // .[0].url),
            state: (first(.[] | select(.state != null and .state != "") | .state) // .[0].state),
            draft: (any(.[]; .draft == true)),
            merged: (any(.[]; .merged == true)),
            body_excerpt: ((first(.[] | select(.body != null and .body != "") | .body) // "")[0:600]),
            sources: ([.[] | .source] | unique),
            file_names: ([.[] | .file_names[]?] | unique),
            files_truncated: (any(.[]; .files_truncated == true)),
            evidence: [.[] | {source, detail, sha, message} | with_entries(select(.value != null))]
          })
        | sort_by(.number)
      ' "${CANDIDATES_JSONL}" > "${WORK_DIR}/deduped.json" 2>>"${ERRORS_FILE}" || record_error "dedupe: jq processing failed"
    else
      echo '[]' > "${WORK_DIR}/deduped.json"
    fi
    if [ ! -s "${WORK_DIR}/deduped.json" ]; then
      echo '[]' > "${WORK_DIR}/deduped.json"
    fi
    CANDIDATE_COUNT=$(jq 'length' "${WORK_DIR}/deduped.json" 2>/dev/null || echo 0)
    # Build a compact index for inventory screening, bounded so the agent never
    # has to print a large file to enumerate candidates.
    jq -n \
      --arg issue "${NUM}" \
      --arg repo "${REPO}" \
      --argjson complete "${COMPLETE}" \
      --argjson version "${INDEX_VERSION}" \
      --slurpfile issue_data "${ISSUE_RAW}" \
      --slurpfile candidates "${WORK_DIR}/deduped.json" \
      --rawfile errorlog "${ERRORS_FILE}" \
      '
        def tokens:
          ascii_downcase
          | gsub("[^a-z0-9_]+"; " ")
          | split(" ")
          # Keep snake_case compounds whole and also emit their parts, so prose
          # terms ("role assignment") can match identifiers ("role_assignments").
          | map(. as $raw | [$raw] + (if ($raw | test("_")) then ($raw | split("_")) else [] end))
          | flatten
          | map(select(length >= 4))
          | map(
              if test("^[a-z][a-z0-9_]*s$") and length > 4 and (endswith("ss") | not)
              then .[0:-1]
              else .
              end
            )
          | . as $tokens
          | [
              "about","above","across","after","again","against","already","also","although","always",
              "among","another","appear","applied","apply","available","because","before","being","below",
              "between","body","branch","change","changes","check","checked","clear","code","configuration",
              "continue","correlation","could","current","default","description","details","during","each",
              "error","example","existing","fails","from","github","have","having","include","issue","later",
              "main","make","module","more","need","needed","other","passes","please","provider","request",
              "resource","should","state","still","than","that","their","then","there","these","they","this",
              "through","type","update","using","value","version","when","where","which","while","with","would"
            ] as $stop
          | $tokens
          | map(. as $token | select(($stop | index($token)) == null))
          | unique;
        def overlap($left; $right):
          [$left[] as $token | select(($right | index($token)) != null) | $token] | unique | sort;
        # Filenames that appear in nearly every AVM PR carry no discovery signal.
        def ubiquitous_file_tokens:
          [
            "changelog","example","footer","header","input","integration","license",
            "locals","output","provider","readme","terraform","test","tftest","tfvars",
            "unit","variable"
          ];
        def has_source($names): any(.sources[]?; . as $source | ($names | index($source)) != null);
        def is_required:
          has_source([
            "timeline_cross_reference",
            "issue_number_search_title",
            "issue_number_search_body",
            "issue_number_search_comment",
            "commit_body_refs",
            "commit_message_reference"
          ]);
        (($issue_data[0].title // "") | tokens) as $issue_title_tokens
        | (($issue_data[0].body // "") | tokens) as $issue_body_tokens
        | def compact_candidate:
            . as $candidate
            | (($candidate.title // "") | tokens) as $pr_title_tokens
            | (($candidate.body_excerpt // "") | tokens) as $pr_body_tokens
            | ([($candidate.file_names[]? // "") | tokens[]] | unique) as $pr_file_tokens
            | overlap($issue_title_tokens; $pr_title_tokens) as $title_title
            | overlap($issue_title_tokens; $pr_body_tokens) as $title_body
            | overlap($issue_body_tokens; $pr_title_tokens) as $body_title
            | overlap($issue_body_tokens; $pr_body_tokens) as $body_body
            | overlap(($issue_title_tokens + $issue_body_tokens | unique); $pr_file_tokens) as $file_matches
            | overlap($issue_title_tokens; $pr_file_tokens) as $title_file
            | (
                $title_file
                | map(. as $token | select((ubiquitous_file_tokens | index($token)) == null))
              ) as $title_file_distinct
            | (
                (($title_title | length) * 5)
                + (($title_body | length) * 3)
                + (($body_title | length) * 2)
                + ([($body_body | length), 4] | min)
                + (($file_matches | length) * 2)
                + (($title_file_distinct | length) * 3)
              ) as $score
            | {
                number: $candidate.number,
                title: $candidate.title,
                sources: $candidate.sources,
                url: $candidate.url,
                state: $candidate.state,
                draft: $candidate.draft,
                merged: $candidate.merged,
                body_excerpt: (($candidate.body_excerpt // "")[0:280]),
                file_names: (($candidate.file_names // [])[0:12]),
                file_names_truncated: (
                  ($candidate.files_truncated == true)
                  or (($candidate.file_names // []) | length > 12)
                ),
                open_inventory: (($candidate.sources | index("open_pr_inventory")) != null),
                merged_inventory: (($candidate.sources | index("merged_pr_inventory")) != null),
                lexical_relevance: {
                  version: 1,
                  score: $score,
                  plausible: (
                    ($score >= 15)
                    or (($title_title | length) >= 3)
                    or (($title_file_distinct | length) >= 2)
                  ),
                  signals: {
                    issue_title_to_pr_title: $title_title[0:10],
                    issue_title_to_pr_body: $title_body[0:10],
                    issue_body_to_pr_title: $body_title[0:10],
                    issue_body_to_pr_body: $body_body[0:10],
                    issue_identifiers_to_file_names: $file_matches[0:10],
                    issue_title_to_file_names: $title_file_distinct[0:10]
                  }
                }
              };
        {
          version: $version,
          issue_number: ($issue | tonumber),
          repository: $repo,
          loaded: true,
          complete: $complete,
          success: $complete,
          errors: ($errorlog | split("\n") | map(select(length > 0) | .[0:240]) | .[0:20]),
          candidate_count: ($candidates[0] | length),
          open_inventory_count: ([$candidates[0][] | select(.sources | index("open_pr_inventory"))] | length),
          merged_inventory_count: ([$candidates[0][] | select(.sources | index("merged_pr_inventory"))] | length),
          required_inspection_count: ([$candidates[0][] | select(is_required)] | length),
          required_inspection_numbers: ([$candidates[0][] | select(is_required) | .number] | unique | sort),
          required_inspection: [
            $candidates[0][] | select(is_required) | compact_candidate
          ],
          open_inventory_screening: [
            $candidates[0][] | select(is_required | not) | compact_candidate
          ]
        }
      ' > "${INDEX_FILE}" 2>>"${ERRORS_FILE}" || {
        record_error "screening index: jq generation failed"
        write_failure_contracts "screening index generation failed"
        rm -rf "${WORK_DIR}"
        exit 0
      }
    if ! jq -e --argjson expected "${CANDIDATE_COUNT}" '
      (.version == 1)
      and (.candidate_count == $expected)
      and (.required_inspection_count == (.required_inspection | length))
      and (.required_inspection_numbers == ([.required_inspection[].number] | unique | sort))
      and (([.required_inspection[].number] + [.open_inventory_screening[].number]) | length == $expected)
      and (([.required_inspection[].number] + [.open_inventory_screening[].number]) | unique | length == $expected)
      and (([.required_inspection[], .open_inventory_screening[]] | map(select(.open_inventory)) | length) == .open_inventory_count)
      and (([.required_inspection[], .open_inventory_screening[]] | map(select(.merged_inventory)) | length) == .merged_inventory_count)
      and (all(.required_inspection[]; (.sources | any(. != "open_pr_inventory" and . != "merged_pr_inventory"))))
      and (all(.open_inventory_screening[]; (.sources | length > 0) and (.sources | all(. == "open_pr_inventory" or . == "merged_pr_inventory"))))
      and (all(.required_inspection[], .open_inventory_screening[];
        (.body_excerpt | length) <= 280 and (.file_names | length) <= 12
      ))
    ' "${INDEX_FILE}" >/dev/null 2>>"${ERRORS_FILE}"; then
      record_error "screening index: count, uniqueness, or partition invariant failed"
      write_failure_contracts "screening index invariant failed"
      rm -rf "${WORK_DIR}"
      exit 0
    fi
    jq -n \
      --arg issue "${NUM}" \
      --arg repo "${REPO}" \
      --arg index_path "${INDEX_FILE}" \
      --argjson index_version "${INDEX_VERSION}" \
      --argjson complete "${COMPLETE}" \
      --slurpfile candidates "${WORK_DIR}/deduped.json" \
      --rawfile errorlog "${ERRORS_FILE}" \
      '
        def numbers_with($sources):
          [
            $candidates[0][]
            | select(any(.sources[]?; . as $source | ($sources | index($source)) != null))
            | .number
          ] | unique | sort;
        (numbers_with([
          "issue_number_search_title",
          "issue_number_search_body",
          "issue_number_search_comment"
        ])) as $exact
        | (numbers_with(["timeline_cross_reference"])) as $timeline
        | (numbers_with(["commit_body_refs","commit_message_reference"])) as $commit
        | (($exact + $timeline + $commit) | unique | sort) as $required
        | (numbers_with(["open_pr_inventory"])) as $inventory
        | (numbers_with(["merged_pr_inventory"])) as $merged_inventory
        | {
            issue_number: ($issue | tonumber),
            repository: $repo,
            loaded: true,
            complete: $complete,
            success: $complete,
            errors: ($errorlog | split("\n") | map(select(length > 0) | .[0:240]) | .[0:20]),
            candidate_count: ($candidates[0] | length),
            open_inventory_count: ($inventory | length),
            merged_inventory_count: ($merged_inventory | length),
            required_inspection_count: ($required | length),
            required_inspection_numbers: $required,
            exact_required_inspection_count: ($exact | length),
            exact_required_inspection_numbers: $exact,
            timeline_required_inspection_count: ($timeline | length),
            timeline_required_inspection_numbers: $timeline,
            commit_required_inspection_count: ($commit | length),
            commit_required_inspection_numbers: $commit,
            screening_index_path: $index_path,
            index_version: $index_version
          }
      ' > "${STATUS_FILE}"
    echo "PR candidate prefetch: candidates=${CANDIDATE_COUNT}, status=${STATUS_FILE}, index=${INDEX_FILE}, complete=${COMPLETE}"
    rm -rf "${WORK_DIR}"
- name: Prefetch duplicate issue candidates for target issue
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    GH_AW_GITHUB_REPOSITORY: ${{ github.repository }}
    ISSUE_NUMBER: ${{ github.event.inputs.issue_number || github.event.issue.number }}
  run: |
    set -o pipefail
    mkdir -p /tmp/gh-aw/agent
    INDEX_FILE=/tmp/gh-aw/agent/issue-candidate-index.json
    INDEX_VERSION=1
    REPO="${GH_AW_GITHUB_REPOSITORY}"
    NUM="${ISSUE_NUMBER}"
    write_failure_index() {
      jq -n --arg issue "${NUM}" --arg repo "${REPO}" --arg error "$1" --argjson version "${INDEX_VERSION}" \
        '{
          version:$version,
          issue_number:($issue | tonumber? // $issue),
          repository:$repo,
          loaded:false,
          complete:false,
          success:false,
          errors:[$error],
          query_count:0,
          queries:[],
          candidate_count:0,
          open_candidate_count:0,
          must_compare:[],
          candidates:[]
        }' > "${INDEX_FILE}"
    }
    if ! printf '%s' "${REPO}" | grep -Eq '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' \
      || ! printf '%s' "${NUM}" | grep -Eq '^[1-9][0-9]*$'; then
      write_failure_index "invalid repository or issue number"
      exit 0
    fi
    WORK_DIR=$(mktemp -d)
    ERRORS_FILE="${WORK_DIR}/errors.txt"
    RESULTS_JSONL="${WORK_DIR}/results.jsonl"
    QUERIES_JSONL="${WORK_DIR}/queries.jsonl"
    QUERY_LIST="${WORK_DIR}/queries.txt"
    : > "${ERRORS_FILE}"
    : > "${RESULTS_JSONL}"
    : > "${QUERIES_JSONL}"
    : > "${QUERY_LIST}"
    COMPLETE=true
    # Conservative fallback written up front, matching the PR prefetch contract.
    write_failure_index "duplicate prefetch step did not finish"
    record_error() {
      echo "$1" >> "${ERRORS_FILE}"
      COMPLETE=false
    }
    ISSUE_RAW="${WORK_DIR}/issue.json"
    if ! gh api "repos/${REPO}/issues/${NUM}" > "${ISSUE_RAW}" 2>>"${ERRORS_FILE}"; then
      echo '{"title":"","body":""}' > "${ISSUE_RAW}"
      record_error "issue metadata: gh api fetch failed for issue #${NUM}"
    fi
    # Derive search terms from the issue title with the same tokenizer the PR
    # screening index uses: GitHub ANDs every term, so emit short broad pairs
    # rather than one long precise query. The remedy-worded variants exist
    # because the same gap is filed twice, once as a symptom and once as a
    # feature request, and those two share almost no vocabulary.
    jq -r '
      def tokens:
        ascii_downcase
        | gsub("[^a-z0-9_]+"; " ")
        | split(" ")
        | map(. as $raw | [$raw] + (if ($raw | test("_")) then ($raw | split("_")) else [] end))
        | flatten
        | map(select(length >= 4))
        | map(
            if test("^[a-z][a-z0-9_]*s$") and length > 4 and (endswith("ss") | not)
            then .[0:-1]
            else .
            end
          )
        | . as $tokens
        | [
            "about","above","across","after","again","against","already","also","although","always",
            "among","another","appear","applied","apply","available","because","before","being","below",
            "between","body","branch","change","changes","check","checked","clear","code","configuration",
            "continue","correlation","could","current","default","description","details","during","each",
            "error","example","existing","fails","from","github","have","having","include","issue","later",
            "main","make","module","more","need","needed","other","passes","please","provider","request",
            "resource","should","state","still","than","that","their","then","there","these","they","this",
            "through","type","update","using","value","version","when","where","which","while","with","would"
          ] as $stop
        | $tokens
        | map(. as $token | select(($stop | index($token)) == null))
        | unique;
      ((.title // "") | tokens | sort_by(- length) | .[0:4]) as $top
      | (
          if ($top | length) >= 2
          then [range(0; $top | length) as $i | range($i + 1; $top | length) as $j | ($top[$i] + " " + $top[$j])]
          else $top
          end
        ) as $pairs
      | (
          $pairs
          + (
              if ($top | length) > 0
              then [($top[0] + " allow"), ($top[0] + " support"), ($top[0] + " custom")]
              else []
              end
            )
        )
      | unique
      | .[]
    ' "${ISSUE_RAW}" 2>>"${ERRORS_FILE}" | tr -d '\r' > "${QUERY_LIST}" || record_error "query derivation: jq processing failed"
    QUERY_COUNT=0
    while IFS= read -r QUERY_TERMS; do
      if [ -z "${QUERY_TERMS}" ]; then
        continue
      fi
      QUERY_COUNT=$((QUERY_COUNT + 1))
      RESPONSE="${WORK_DIR}/search-${QUERY_COUNT}.json"
      if gh api -X GET search/issues \
        -f q="repo:${REPO} is:issue ${QUERY_TERMS}" \
        -f per_page=30 > "${RESPONSE}" 2>>"${ERRORS_FILE}"; then
        jq -c --arg query "${QUERY_TERMS}" --argjson target "${NUM}" '
          {
            query: $query,
            total_count: (.total_count // 0),
            numbers: [.items[]? | select(.pull_request == null) | select(.number != $target) | .number] | unique | sort
          }
        ' "${RESPONSE}" >> "${QUERIES_JSONL}" 2>>"${ERRORS_FILE}" \
          || record_error "search: jq summary failed for query [${QUERY_TERMS}]"
        jq -c --arg query "${QUERY_TERMS}" --argjson target "${NUM}" '
          .items[]?
          | select(.pull_request == null)
          | select(.number != $target)
          | {
              number: .number,
              title: (.title // ""),
              url: .html_url,
              state: (.state // "unknown"),
              created_at: (.created_at // ""),
              body_excerpt: ((.body // "")[0:280]),
              query: $query
            }
        ' "${RESPONSE}" >> "${RESULTS_JSONL}" 2>>"${ERRORS_FILE}" \
          || record_error "search: jq extraction failed for query [${QUERY_TERMS}]"
      else
        record_error "search: gh api failed for query [${QUERY_TERMS}]"
      fi
      sleep 2
    done < "${QUERY_LIST}"
    jq -s -c '.' "${RESULTS_JSONL}" > "${WORK_DIR}/results.json" 2>>"${ERRORS_FILE}" \
      || { echo '[]' > "${WORK_DIR}/results.json"; record_error "aggregation: results slurp failed"; }
    jq -s -c '.' "${QUERIES_JSONL}" > "${WORK_DIR}/queries.json" 2>>"${ERRORS_FILE}" \
      || { echo '[]' > "${WORK_DIR}/queries.json"; record_error "aggregation: queries slurp failed"; }
    jq -n \
      --arg issue "${NUM}" \
      --arg repo "${REPO}" \
      --argjson complete "${COMPLETE}" \
      --argjson version "${INDEX_VERSION}" \
      --argjson query_count "${QUERY_COUNT}" \
      --slurpfile issue_data "${ISSUE_RAW}" \
      --slurpfile results "${WORK_DIR}/results.json" \
      --slurpfile queries "${WORK_DIR}/queries.json" \
      --rawfile errorlog "${ERRORS_FILE}" \
      '
        def tokens:
          ascii_downcase
          | gsub("[^a-z0-9_]+"; " ")
          | split(" ")
          | map(. as $raw | [$raw] + (if ($raw | test("_")) then ($raw | split("_")) else [] end))
          | flatten
          | map(select(length >= 4))
          | map(
              if test("^[a-z][a-z0-9_]*s$") and length > 4 and (endswith("ss") | not)
              then .[0:-1]
              else .
              end
            )
          | . as $tokens
          | [
              "about","above","across","after","again","against","already","also","although","always",
              "among","another","appear","applied","apply","available","because","before","being","below",
              "between","body","branch","change","changes","check","checked","clear","code","configuration",
              "continue","correlation","could","current","default","description","details","during","each",
              "error","example","existing","fails","from","github","have","having","include","issue","later",
              "main","make","module","more","need","needed","other","passes","please","provider","request",
              "resource","should","state","still","than","that","their","then","there","these","they","this",
              "through","type","update","using","value","version","when","where","which","while","with","would"
            ] as $stop
          | $tokens
          | map(. as $token | select(($stop | index($token)) == null))
          | unique;
        def overlap($left; $right):
          [$left[] as $token | select(($right | index($token)) != null) | $token] | unique | sort;
        (($issue_data[0].title // "") | tokens) as $issue_title_tokens
        | (($issue_data[0].body // "") | tokens) as $issue_body_tokens
        | (
            $results[0]
            | group_by(.number)
            | map(
                .[0] as $first
                | ($first.title | tokens) as $cand_title_tokens
                | ($first.body_excerpt | tokens) as $cand_body_tokens
                | overlap($issue_title_tokens; $cand_title_tokens) as $title_title
                | overlap($issue_title_tokens; $cand_body_tokens) as $title_body
                | overlap($issue_body_tokens; $cand_title_tokens) as $body_title
                | (
                    (($title_title | length) * 5)
                    + (($title_body | length) * 3)
                    + (($body_title | length) * 2)
                  ) as $score
                | {
                    number: $first.number,
                    title: $first.title,
                    url: $first.url,
                    state: $first.state,
                    created_at: $first.created_at,
                    body_excerpt: $first.body_excerpt,
                    matched_queries: ([.[].query] | unique | sort),
                    lexical_relevance: {
                      version: 1,
                      score: $score,
                      signals: {
                        issue_title_to_candidate_title: $title_title[0:10],
                        issue_title_to_candidate_body: $title_body[0:10],
                        issue_body_to_candidate_title: $body_title[0:10]
                      }
                    }
                  }
              )
            | sort_by(.number)
          ) as $candidates
        | ([$candidates[] | select(.state == "open") | .number] | sort) as $open_numbers
        | ([$candidates[]
            | select(.lexical_relevance.score >= 12)]
           | sort_by(-.lexical_relevance.score, .number)
           | .[0:6]
           | map(.number)) as $must_compare
        | {
            version: $version,
            issue_number: ($issue | tonumber),
            repository: $repo,
            loaded: true,
            complete: $complete,
            success: $complete,
            errors: ($errorlog | split("\n") | map(select(length > 0) | .[0:240]) | .[0:20]),
            query_count: $query_count,
            queries: $queries[0],
            candidate_count: ($candidates | length),
            open_candidate_count: ($open_numbers | length),
            must_compare: $must_compare,
            candidates: $candidates
          }
      ' > "${INDEX_FILE}"
    echo "Duplicate candidate prefetch: queries=${QUERY_COUNT}, index=${INDEX_FILE}, complete=${COMPLETE}"
    rm -rf "${WORK_DIR}"
- name: Render triage evidence blocks
  run: |
    set -o pipefail
    AGENT_DIR=/tmp/gh-aw/agent
    mkdir -p "${AGENT_DIR}"
    DUP_INDEX="${AGENT_DIR}/issue-candidate-index.json"
    PR_STATUS="${AGENT_DIR}/pr-candidate-status.json"
    PR_INDEX="${AGENT_DIR}/pr-candidate-screening-index.json"
    AUDIT_FILE="${AGENT_DIR}/triage-audit-block.md"
    STATUS_LINE="${AGENT_DIR}/triage-screening-status.md"
    # The validation programs below are the deterministic contracts the prompt used
    # to ask the agent to run by hand. Evaluating them here keeps ~5KB of dense
    # filter syntax out of the model-facing prompt, and means a run cannot report
    # that the invariants passed unless they were actually evaluated.
    AUDIT_FALLBACK='- Prefetched duplicate searches: the deterministic duplicate index did not load, so no prefetched search record is available for this run. Do not close this issue as a duplicate in this run.'
    STATUS_FALLBACK='- **PR-evidence and screening status:** the deterministic PR evidence contracts did not pass, so screening counts and candidate numbers are unavailable for this run. Confirmed-fix closure and PR linking were skipped; duplicate-closure decisions are unaffected.'
    fallback() {
      printf '%s\n' "$2" > "$1"
      echo "render: $3; wrote fallback line to $1"
    }
    render_audit() {
      if [ ! -s "${DUP_INDEX}" ]; then
        fallback "${AUDIT_FILE}" "${AUDIT_FALLBACK}" "duplicate index missing or empty"
        return
      fi
      if ! jq -e '. as $index | type == "object" and .loaded == true and .complete == true and .success == true and (.errors == []) and (.version == 1) and (.query_count | type == "number") and (.queries | type == "array") and (.candidate_count | type == "number") and (.candidates | type == "array") and (.open_candidate_count | type == "number") and (.must_compare | type == "array") and ((.must_compare - [.candidates[].number]) == []) and (.query_count == (.queries | length)) and (.candidate_count == (.candidates | length)) and (.open_candidate_count == ([.candidates[] | select(.state == "open")] | length)) and ([.candidates[].number] | unique | length) == .candidate_count and (all(.queries[]; (.query | type == "string") and (.numbers | type == "array"))) and (all(.candidates[]; (.number | type == "number") and (.title | type == "string") and (.state | type == "string") and (.created_at | type == "string") and (.url | type == "string") and (.body_excerpt | type == "string") and (.body_excerpt | length) <= 280 and (.matched_queries | type == "array") and (.matched_queries | length > 0) and (.lexical_relevance.score | type == "number") and (.lexical_relevance.signals | type == "object")))' "${DUP_INDEX}" > /dev/null 2>&1; then
        fallback "${AUDIT_FILE}" "${AUDIT_FALLBACK}" "duplicate index failed its contract"
        return
      fi
      if ! jq -r '
          def numlist($nums):
            if (($nums // []) | length) == 0 then "none"
            else (($nums // []) | map("#" + (. | tostring)) | join(", "))
            end;
          ["- Prefetched duplicate searches (from `issue-candidate-index.json`):"]
          + (
              .queries
              | map(
                  "  - `" + (.query // "") + "` → "
                  + (
                      if (((.numbers // []) | length) == 0) then "no results"
                      else ((.numbers // []) | map("`#" + (. | tostring) + "`") | join(", "))
                      end
                    )
                )
            )
          + ["- Candidates requiring explicit comparison: " + numlist(.must_compare)]
          | .[]
        ' "${DUP_INDEX}" > "${AUDIT_FILE}"; then
        fallback "${AUDIT_FILE}" "${AUDIT_FALLBACK}" "audit render failed"
        return
      fi
      if [ ! -s "${AUDIT_FILE}" ]; then
        fallback "${AUDIT_FILE}" "${AUDIT_FALLBACK}" "audit render produced no output"
        return
      fi
      echo "Audit block rendered: $(wc -l < "${AUDIT_FILE}") line(s) -> ${AUDIT_FILE}"
    }
    render_status() {
      if [ ! -s "${PR_STATUS}" ] || [ ! -s "${PR_INDEX}" ]; then
        fallback "${STATUS_LINE}" "${STATUS_FALLBACK}" "PR status or screening index missing or empty"
        return
      fi
      if ! jq -e '. as $status | type == "object" and .loaded == true and .complete == true and .success == true and (.errors == []) and (.candidate_count | type == "number") and (.open_inventory_count | type == "number") and (.merged_inventory_count | type == "number") and (.required_inspection_count | type == "number") and (.required_inspection_numbers | type == "array") and (.exact_required_inspection_count | type == "number") and (.exact_required_inspection_numbers | type == "array") and (.timeline_required_inspection_count | type == "number") and (.timeline_required_inspection_numbers | type == "array") and (.commit_required_inspection_count | type == "number") and (.commit_required_inspection_numbers | type == "array") and (.required_inspection_count == (.required_inspection_numbers | length)) and (.exact_required_inspection_count == (.exact_required_inspection_numbers | length)) and (.timeline_required_inspection_count == (.timeline_required_inspection_numbers | length)) and (.commit_required_inspection_count == (.commit_required_inspection_numbers | length)) and (.required_inspection_numbers == ((.exact_required_inspection_numbers + .timeline_required_inspection_numbers + .commit_required_inspection_numbers) | unique | sort)) and (.required_inspection_count <= .candidate_count) and (.open_inventory_count <= .candidate_count) and (.merged_inventory_count <= .candidate_count) and (.screening_index_path | type == "string") and (.index_version == 1)' "${PR_STATUS}" > /dev/null 2>&1; then
        fallback "${STATUS_LINE}" "${STATUS_FALLBACK}" "PR status failed its contract"
        return
      fi
      if ! jq -e '. as $index | type == "object" and .loaded == true and .complete == true and .success == true and (.errors == []) and (.version == 1) and (.candidate_count | type == "number") and (.open_inventory_count | type == "number") and (.required_inspection_count | type == "number") and (.required_inspection_numbers | type == "array") and (.required_inspection | type == "array") and (.open_inventory_screening | type == "array") and (.required_inspection_count == (.required_inspection | length)) and (.required_inspection_numbers == ([.required_inspection[].number] | unique | sort)) and (([.required_inspection[].number] + [.open_inventory_screening[].number]) | length == $index.candidate_count) and (([.required_inspection[].number] + [.open_inventory_screening[].number]) | unique | length == $index.candidate_count) and (([.required_inspection[], .open_inventory_screening[]] | map(select(.open_inventory)) | length) == $index.open_inventory_count) and (([.required_inspection[], .open_inventory_screening[]] | map(select(.merged_inventory)) | length) == $index.merged_inventory_count) and (all(.required_inspection[]; (.sources | any(. != "open_pr_inventory" and . != "merged_pr_inventory")))) and (all(.open_inventory_screening[]; (.sources | length > 0) and (.sources | all(. == "open_pr_inventory" or . == "merged_pr_inventory")) and (.open_inventory or .merged_inventory))) and (all(.required_inspection[], .open_inventory_screening[]; (.number | type == "number") and (.title | type == "string") and (.sources | type == "array") and (.url | type == "string") and (.state | type == "string") and (.draft | type == "boolean") and (.merged | type == "boolean") and (.body_excerpt | type == "string") and (.body_excerpt | length) <= 280 and (.file_names | type == "array") and (.file_names | length) <= 12 and (.file_names_truncated | type == "boolean") and (.open_inventory | type == "boolean") and (.merged_inventory | type == "boolean") and (.lexical_relevance.score | type == "number") and (.lexical_relevance.plausible | type == "boolean") and (.lexical_relevance.signals | type == "object")))' "${PR_INDEX}" > /dev/null 2>&1; then
        fallback "${STATUS_LINE}" "${STATUS_FALLBACK}" "PR screening index failed its contract"
        return
      fi
      if ! jq -e -n --slurpfile s "${PR_STATUS}" --slurpfile i "${PR_INDEX}" '
          ($s[0].candidate_count == $i[0].candidate_count)
          and ($s[0].open_inventory_count == $i[0].open_inventory_count)
          and ($s[0].merged_inventory_count == $i[0].merged_inventory_count)
          and ($s[0].required_inspection_count == $i[0].required_inspection_count)
          and ($s[0].required_inspection_numbers == $i[0].required_inspection_numbers)
        ' > /dev/null 2>&1; then
        fallback "${STATUS_LINE}" "${STATUS_FALLBACK}" "PR status and screening index disagree on counts"
        return
      fi
      if ! jq -r '
          def numlist($nums):
            if (($nums // []) | length) == 0 then "none"
            else (($nums // []) | sort | map("`#" + (. | tostring) + "`") | join(", "))
            end;
          ([.open_inventory_screening[]
            | select(.lexical_relevance.plausible == true)
            | .number] | unique | sort) as $plausible
          | "- **PR-evidence and screening status:** `candidate_count`: \(.candidate_count), "
            + "`open_inventory_count`: \(.open_inventory_count), "
            + "`merged_inventory_count`: \(.merged_inventory_count), "
            + "`required_inspection_count`: \(.required_inspection_count). "
            + "Required inspection: \(numlist(.required_inspection_numbers)). "
            + "Lexically plausible (full inspection mandatory): \(numlist($plausible)). "
            + "Direct status/index parses succeeded and all count/inspection invariants passed."
        ' "${PR_INDEX}" > "${STATUS_LINE}"; then
        fallback "${STATUS_LINE}" "${STATUS_FALLBACK}" "status render failed"
        return
      fi
      if [ ! -s "${STATUS_LINE}" ]; then
        fallback "${STATUS_LINE}" "${STATUS_FALLBACK}" "status render produced no output"
        return
      fi
      echo "Screening status rendered -> ${STATUS_LINE}"
      cat "${STATUS_LINE}"
    }
    render_audit
    render_status
tools:
  cache-memory: true
  github:
    min-integrity: none
    toolsets:
    - default
  web-fetch: {}
mcp-servers:
  microsoftdocs:
    url: "https://learn.microsoft.com/api/mcp"
    allowed: ["*"]
---

# Azure Verified Modules Terraform Module Issue Triage

You are an AI agent that performs initial triage on newly created or reopened issues in the **${{ github.repository }}** repository.

This repository contains the Terraform code for a single Azure Verified Module (AVM) module. The issue, the labels, the releases, and the code to investigate are all in this repository.

> **Target issue for this run: #${{ github.event.inputs.issue_number || github.event.issue.number }}**
> Always use this number as `item_number` in issue safe output calls (`add-comment`, `add-labels`). Use it as `issue_number` for `close-issue` and `set-issue-type`. When updating a pull request, use its number as `pull_request_number`.

## Your Task

When a new issue is created or reopened, perform the following steps **in order**:

1. **Read the issue and its history** — Understand the title, body, labels, and timeline. Determine whether this workflow previously closed the issue and a person later reopened it; if so, permanently disable automated closure for this issue.
2. **Check for duplicates** — Search for existing open **and** closed issues in this repository that are similar or identical.
3. **Set the issue type and attach labels** — Choose the best matching GitHub issue type and attach appropriate labels that already exist on the repository.
4. **Discover related PRs and check for existing fixes** — Search broadly for linked and unlinked PRs, validate candidate PRs by reading their changes, link only clear fixes, and determine whether the issue is conclusively resolved.
5. **Investigate and suggest a fix** — Where possible, look at the relevant source code in this repository and suggest what the fix may be. If the issue is a question or a feature request rather than a bug, note that clearly.
6. **Post a triage summary comment** — Summarise what you did in a single comment on the issue. **Do not emit any safe outputs until all analysis steps are complete.**

---

## Step 1: Read the Issue

Read the full issue title and body for issue **#${{ github.event.inputs.issue_number || github.event.issue.number }}** (also available in `/tmp/gh-aw/agent/issue-number.txt`). Note:

- Key terms, error messages, file paths, resource names, variable names, output names, or module references.
- Whether the issue mentions a Terraform plan/apply error, a provider version, an example, a variable, or a specific Azure resource.
- Any `.tf`, `.tfvars`, `.tftest.hcl`, `.terraform.lock.hcl`, or Terraform CLI references that indicate the deployment path.
- If the issue lacks a minimal reproduction (config snippet, provider/module versions, exact error), prefer `needs-more-info` over guessing a root cause.
- Read `/tmp/gh-aw/agent/issue-state-history.json` and earlier comments from this workflow. The history file records close/reopen event timestamps and actor identities.

### Human Reopen Override

If the state history and earlier workflow comments show that this agentic triage workflow previously closed the issue, and a person subsequently reopened it, treat that reopen as an explicit request for human review. Confirm the workflow closure by correlating a prior triage comment that says the workflow is closing the issue with the subsequent close event by the workflow actor; do not attribute another automation's closure to this workflow.

- Set a **human-reopened-after-agent-closure** flag for the rest of the run.
- Never call `close-issue` for this issue again, with any `state_reason`. This veto applies to both duplicate and completed closures and to manual reruns because the reopen remains in the issue timeline.
- Continue the full analysis. You may add labels, refresh the triage comment, and append `Fixes #<issue-number>` to a confirmed-fix PR when appropriate.
- In the triage comment, state that automated closure was skipped because the issue was reopened after an earlier agent closure and should remain open for a human maintainer.

Do not activate this override merely because the issue is currently in the `reopened` event. Confirm from the ordered history that this workflow performed the earlier closure and that a later reopen event has an actor with `type: User`, not a bot or workflow. A reopen after a human closure does not by itself create this automated-closure veto.

If the history file is missing, unreadable, or has `loaded: false`, do not perform any automated closure in this run because you cannot safely rule out a prior human reopen. Continue the analysis and state in the triage comment that closure was skipped because issue state history could not be verified.

### Prior Triage Comments Are Not Evidence

Earlier triage comments on this issue — including ones you wrote in previous runs — record what was true **when they were written**, not what is true now. A fix may have merged since.

- Use them only for state history (above) and to avoid repeating identical advice verbatim.
- **Never restate a factual claim from an earlier comment about repository contents** — which files, tests, examples, variables, or fixes exist — without re-verifying it against the current default branch **in this run**. A claim that something is missing is the one most likely to have gone stale.
- **Never cite agreement between previous runs as support.** Repeated output is one observation, not several; a stale claim repeats perfectly. Phrases like "previous runs reached the same conclusion" are not evidence and must not appear in your comment.
- If you cannot re-verify an inherited claim this run, drop it rather than repeat it.

---

## Step 2: Check for Duplicates

### Deterministic Duplicate Candidate Contract (read this first)

A pre-agent step has already issued a fixed set of issue searches, validated the result against a strict schema and count contract, and written `/tmp/gh-aw/agent/issue-candidate-index.json`. Read it **before** searching yourself:

```bash
jq '{query_count,candidate_count,open_candidate_count,must_compare,queries:[.queries[] | {query,total_count,matched:(.numbers | length)}]}' /tmp/gh-aw/agent/issue-candidate-index.json
jq '.candidates[] | {number,title,state,created_at,url,body_excerpt,matched_queries,lexical_relevance}' /tmp/gh-aw/agent/issue-candidate-index.json
```

You do not have to validate the file. If its contract failed, the rendered audit block at `/tmp/gh-aw/agent/triage-audit-block.md` says so in place of the query list, and that is your signal that the deterministic duplicate search is unavailable: say so in your triage comment, run your own searches, and **do not close this issue as a duplicate in this run**.

The queries are derived from the issue title by a fixed tokenizer, not by the model: it takes the four most distinctive title terms, issues every pair of them, and adds remedy-worded variants of the strongest term (`allow`, `support`, `custom`) so a feature-request framing of the same gap is reachable. This is a **floor, not a ceiling** — it cannot know the issue's error text, and it cannot paraphrase.

**Screen every entry in `.candidates`** and open the promising ones. `lexical_relevance.score` orders your reading; it does not decide anything and does not prove a shared root cause.

**`.must_compare` is mandatory reading.** It holds the highest-scoring candidates, and every issue in it **must be opened and read this run** — not skimmed from its title or `body_excerpt`, which are truncated and routinely hide the sentence that decides the match. Account for **every** number in `.must_compare` in your Duplicate check bullet with a short verdict each: duplicate, possible duplicate, related, or not related, with a few words of reason. A number you never mention reads as a candidate you never opened.

This obligation is about **reading, not deciding**. A high score never justifies a closure on its own, and a candidate you were required to open is very often correctly dismissed — say so explicitly instead of omitting it. Conversely, a duplicate may be an issue that is *not* in `.must_compare`: the list is the mandatory floor, never the full set of things worth comparing.

### Additional Searching

The prefetched queries are mechanical. Add your own, using `search_issues` — `search_repositories` searches for repositories, not issues, and cannot answer this question. Anything you turn up this way is reported as a **finding** — the issue number and why it matches — never as a description of the query that found it; see *The search record is rendered for you* below.

Search **${{ github.repository }}** for existing issues (both open and closed) that report the **same underlying problem**, even if they are worded differently. Reworded or paraphrased reports are still duplicates — do not rely on title or keyword overlap alone.

**How to build queries.** GitHub ANDs every term, so each extra word can only shrink the result set. Keep each query to **two or three broad terms** and run **several separate queries** rather than one precise query. Prefer the words that would appear in *any* report of this problem — the affected input, resource, or behaviour — and leave out qualifiers, verbs, and framing words. For example, prefer `whitespace name` over `trim leading whitespace vnet name`.

Cover what the prefetch structurally cannot:

- A distinctive substring of any **error message**, on its own.
- The affected provider, resource, variable, output, or module name (e.g. `modtm`, `enable_telemetry`, `azapi`).
- **The vocabulary of the fix**, as its own query — never appended to a symptom query. The same gap is routinely filed twice: once as a bug describing the *symptom* ("the module overwrites my lock notes on every apply") and once as a feature request describing the *remedy* ("allow setting custom lock notes"). These share almost no wording, so only a separate remedy-worded search will find the pair. A bug-vs-feature framing difference is irrelevant to whether two issues are the same underlying problem.

Then **open the most promising candidate issues and compare them semantically** — decide whether they describe the same root cause, not just whether the text matches. Include very recently opened issues, since a duplicate may have been filed only minutes earlier.

**Choosing the canonical issue.** Collect every match you judge to be the same underlying problem, then list them as `#<number>` with state and creation date, sorted by number ascending. The canonical issue is the **lowest-numbered one that is still open**. Note that this is computed over the matches *you judged to be duplicates*, never over the raw prefetched candidate list — a search hit is not a duplicate. Only if every match is closed do you fall back to the lowest-numbered closed one. Do not link the match you happened to find first, and do not link a newer issue while an older open one tracks the same problem.

### Duplicate Handling Rules

Finding a candidate above does **not** by itself mean you close. Closing is a separate, deliberate decision with a **high bar**. Sort each candidate you found into one of these tiers:

- **Confirmed duplicate (close):** Close as a duplicate **only** when you are **highly confident** the two issues are the **same underlying problem / root cause** and the Human Reopen Override is not active — the wording or framing may differ, but the actual defect, request, or question is the same and re-reporting it adds no new information. First post your triage comment (see Step 6 — Duplicate Closure Flow) explaining the match, then use the `close-issue` safe output. This closes the issue with the `duplicate` state reason and links it to the canonical issue. This decision is governed only by these duplicate rules: it does not depend on, and is never weakened by, the Step 4 PR-evidence prefetch or the state of any related fix PR — close as a duplicate even if a topically related PR is still open, draft, or unmerged, or if that PR's own evidence load was incomplete.
- **Possible duplicate (do NOT close, but link):** You found a strong candidate that looks like the same problem, but you are **not** highly confident — e.g. it overlaps heavily yet also raises a distinct question, adds new context, or you cannot fully confirm the same root cause. **Leave the issue open.** In your triage comment, explicitly flag it as `Possible duplicate of #N` with a link so triagers can make the final call. Do **not** apply the `duplicate` label in this tier (that label is only for issues you actually close).
- **Related / similar (do NOT close):** Touches a related area but is a **different** root cause, request, or question. Mention it as a related issue in your triage comment. Leave the issue open.
- **No duplicates found:** Note this in your triage comment.

**Bias toward leaving open.** Wrongly closing a valid issue is much worse than leaving a duplicate open. Whenever you are not **highly confident** it is the same root cause, do not close — downgrade to *Possible duplicate* and link it instead. Never close based on surface or topic similarity alone.

**The search record is rendered for you; do not write it yourself.** A step that ran before you rendered the duplicate-search audit trail to `/tmp/gh-aw/agent/triage-audit-block.md`. In the collapsed **"What this triage looked at"** accordion at the bottom of your Step 6 comment:

1. Read that file (`cat /tmp/gh-aw/agent/triage-audit-block.md`) and paste its contents **verbatim** as the opening lines of the accordion. Do not reformat it, re-order it, collapse its lines together, shorten an issue list, or re-derive any part of it from `issue-candidate-index.json`. It is already correct; any difference between that file and your comment is a defect, and issue numbers in particular must appear exactly as rendered.
2. Below the pasted block, list the other sources you actually opened (issues, source files, releases), identified by issue number or file path.

**Never describe your own searching, anywhere in the comment.** Do not name a query you ran, and do not state that you ran, re-ran, repeated, or supplemented any search — not in the accordion, and not in the visible bullets. The pasted block is the entire published search record, because it is the only part backed by a file a maintainer can check. If your own searching surfaced a candidate the prefetch missed, report it as a finding in the visible bullets — the issue number and why it matches — never as a description of the search that found it. Report what you found, not what you did.

If the index failed to load and you were also unable to run any search, say exactly that in the visible comment ("No duplicate search was performed") rather than reporting that none were found; those are different statements and only one of them is true.

---

## Step 3: Set the Issue Type and Attach Labels

The repository label definitions are available at `/tmp/gh-aw/agent/repo-labels.json`. **Read this file before emitting any label, and copy each `name` value verbatim** — see Critical Label Rules below. If this file is missing or unreadable, skip label application and note in your triage comment that "Labels could not be applied due to a data loading error."

### Set the GitHub Issue Type

Classify every issue as exactly one of these GitHub issue types and use the `set-issue-type` safe output to apply it:

- **Bug** — Unexpected or incorrect behavior, regressions, errors, failed deployments, or behavior that does not match the documented contract.
- **Feature** — Feature requests for new user-facing capabilities, resources, variables, outputs, integrations, or enhancements to existing behavior.
- **Task** — Concrete maintenance, documentation, testing, CI, refactoring, investigation, or other actionable work that is neither a defect nor a feature request. **This is also where usage questions, feedback, and clarification requests go** — there is no `Question` issue type.

**These three are the only values `set-issue-type` accepts.** Emitting anything else — `Question`, `Documentation`, `Security`, `Enhancement` — is rejected with *"Issue type X is not in the allowed list"* and the run fails with no type applied.

The repository's **labels** are a richer taxonomy than the issue types, and they do not map one-to-one. A repo carries `Type: Question/Feedback :raising_hand:`, `Type: Documentation :page_facing_up:`, `Type: Security Bug :lock:` and more, but none of those is an issue type. Label such an issue with whichever `Type: …` label fits **and** give it the closest of the three issue types:

| The issue is | Label | Issue type |
|---|---|---|
| a usage question or feedback | `Type: Question/Feedback` | **Task** |
| a documentation gap | `Type: Documentation` | **Task** |
| a security defect | `Type: Security Bug` | **Bug** |
| a CI or workflow problem | `Type: CI` | **Task** |

Choose the single best fit from the issue's primary intent. Do not create or use any other issue type.

**Always emit `set-issue-type` with your chosen type.** There is no "already correct, skip it" case to judge: applying the type an issue already has is a harmless no-op, and re-applying it costs nothing. Emitting unconditionally is what makes this reliable.

Do not decide this from the `Type: …` **labels** or from the **`### Issue Type?`** field in the issue body. Neither is the native issue type — the labels are a separate system, and the body field is free text the reporter chose. An issue can carry `Type: Bug :bug:` and a body saying `Bug` while its native type is unset, which is the normal state of any issue triaged before issue types existed.

`/tmp/gh-aw/agent/issue-type.txt` holds the issue's current native type — one line, either `Bug`, `Feature`, `Task`, `NONE`, or `UNKNOWN`. It exists because your issue-reading tool does not return the type at all. It is context, not a gate: read it only if you intend to mention the previous value, and if you do, quote it exactly as the file reads. Never describe a type as already set unless that file literally says so.

Issue types are independent of labels, so continue with label analysis after setting the type.

Analyse the issue content and attach the most appropriate labels from the repository's existing label set. Apply **all** labels that are relevant.

### Suggested label mapping

Use the issue content to determine the most appropriate labels, but only apply labels that exist in the repository's label set.

The `name` values below are illustrative. Match on the *concept*, then emit the label name exactly as it appears in `repo-labels.json`.

| Clue in issue | Concept to match in the repo label set |
|---|---|
| Unexpected behavior, error, failed `terraform apply`, broken module output | the "Type: Bug" label |
| Request for a new capability, new variable, new resource support, or enhancement to the module | the "Type: Feature Request" label |
| Usage question, "how do I...", configuration clarification, or expected behavior question | the "Type: Question/Feedback" label |
| Missing docs, unclear examples, or incorrect README content | the "Type: Documentation" label |
| The issue is a duplicate of an existing open issue | the "Type: Duplicate" label |
| The issue seems to be an AVM-specific issue rather than a module bug | the "Type: AVM" label |
| The issue is about CI/workflow/test automation rather than module behavior | the "Type: CI" label |
| The issue needs more details before triage can proceed | the "Needs: More Evidence" label |
| The issue needs maintainer follow-up or review | the "Needs: Triage" label |

### Release-state labels

AVM tracks where a fix has got to with three labels. Apply the one that matches the evidence, and only that one:

| State you established | Label to match |
|---|---|
| A fix for this issue exists in an **open, unmerged** PR | the "Status: In PR" label |
| A fix is **merged to the default branch but not in any release** — its PR number or merge commit appears in `release-status.json` | the "Status: Awaiting Release To Be Cut" label |
| A fix is **merged and carried by a published release** | the "Status: Fixed" label, alongside closing the issue |

AVM defines "Status: Awaiting Release To Be Cut" as *"This is fixed in the main branch but not in the latest release, will be fixed with next release cut"*. It is the state that keeps an issue open and visible to whoever cuts the next release, which is why an unreleased fix is labelled rather than closed.

### Critical Label Rules

- **`repo-labels.json` is the only authoritative source of label names. Copy the `name` field byte-for-byte.** Label names in this repository embed literal emoji shortcodes such as `:heavy_plus_sign:`. Never render a shortcode into a Unicode emoji, never re-order or re-space a name, and never reconstruct a name from memory or from the table above. `Type: Feature Request ➕` is *not* the same label as `Type: Feature Request :heavy_plus_sign:` and will be rejected.
- **`add-labels` is atomic: if any one name in the batch does not exist, the entire batch is discarded** and the issue receives no labels at all. Verify every name against `repo-labels.json` before emitting.
- **`add-labels` requires at least one label. Never emit it with an empty list** — `{"type": "add_labels", "labels": []}` is rejected with "No labels provided" and fails the run. When the issue already carries every label it needs, the correct action is to not call `add-labels` at all and to say so in one line in the triage comment. This is the opposite of `set-issue-type`, which you emit on every run: re-applying a type is a harmless no-op, whereas an empty label batch is an error.
- Never remove labels that already exist on the issue.
- **In your triage comment, only list and justify the labels you are *adding* in this run. Do not mention, list, or re-justify labels that were already present on the issue** — the maintainer can already see those, so repeating them is noise.
- Only add labels that already exist in the repository's label set.
- Do not invent new labels.
- Use the `add-labels` safe output to attach labels to the issue. Listing label names in the comment body does NOT apply them.
- If the issue appears to be a duplicate, only apply `duplicate` if that label exists in the repository's label set.

---

## Step 4: Discover Related PRs and Check for Existing Fixes

Before investigating a new fix, determine whether a PR or release already addresses the issue. Do not assume that the absence of a GitHub development link means no PR exists: contributors often omit closing keywords.

### Deterministic PR Candidate Contracts (read this first)

A pre-agent step has already fetched PR candidate evidence, validated it against strict schema, count, and cross-file contracts, and written two files:

- `/tmp/gh-aw/agent/pr-candidate-status.json` — the small status and count contract.
- `/tmp/gh-aw/agent/pr-candidate-screening-index.json` — the compact inventory-screening index.

**Read them before doing anything else in Step 4** (additional candidate-specific `jq` selectors are allowed):

```bash
jq '{loaded,complete,success,errors,candidate_count,open_inventory_count,merged_inventory_count,required_inspection_count,required_inspection_numbers,exact_required_inspection_count,exact_required_inspection_numbers,timeline_required_inspection_count,timeline_required_inspection_numbers,commit_required_inspection_count,commit_required_inspection_numbers,screening_index_path,index_version}' /tmp/gh-aw/agent/pr-candidate-status.json
jq '{candidate_count,open_inventory_count,merged_inventory_count,required_inspection_count,required_inspection_numbers,inventory_only_count:(.open_inventory_screening | length),plausible_numbers:[(.required_inspection + .open_inventory_screening)[] | select((.open_inventory or .merged_inventory) and .lexical_relevance.plausible) | .number]}' /tmp/gh-aw/agent/pr-candidate-screening-index.json
jq '.required_inspection[] | {number,title,sources,url,state,draft,merged,body_excerpt,file_names,open_inventory,merged_inventory,lexical_relevance}' /tmp/gh-aw/agent/pr-candidate-screening-index.json
jq '.open_inventory_screening[] | {number,title,sources,url,state,draft,merged,body_excerpt,file_names,open_inventory,merged_inventory,lexical_relevance}' /tmp/gh-aw/agent/pr-candidate-screening-index.json
```

You do not have to validate these files or reconcile their counts — schema, count, and status-versus-index agreement were all checked before you started. If any of it failed, the rendered line at `/tmp/gh-aw/agent/triage-screening-status.md` says so in place of the counts, and that is your signal to apply the evidence veto described below. Never parse a copied terminal/UI capture or a displayed/truncated rendering. **Visible output ending early is not evidence of truncation or failure.** Report a parser or API error only when a direct-path `jq` parse actually fails or the rendered status line says the contracts did not pass.

The file is produced by fixed `gh api`/GraphQL calls (not the model), so it deterministically covers, across **all PR states with no date limit**:

- Timeline cross-references on the issue, **including non-closing mentions** (`source: timeline_cross_reference`).
- Exact `#<issue-number>` and repository-qualified (`owner/repo#<issue-number>`) matches in PR titles (`issue_number_search_title`), bodies (`issue_number_search_body`), and PR/issue comments (`issue_number_search_comment`).
- Commits whose message contains `#<issue-number>` or a qualified ref, mapped back to their associated PR — tagged `commit_body_refs` when the commit message uses a `Refs #<issue-number>` / `Fixes #<issue-number>` / `Closes #<issue-number>` / `Resolves #<issue-number>` style line, or `commit_message_reference` for any other mention. This is the only reliable way to catch a reference that lives in a commit body of an **open, unmerged** PR rather than in the PR's own title/body — those commits are not on the default branch and GitHub's commit search does not fully index commit bodies, so this cannot be found by ad-hoc searching alone.
- A paginated inventory of **every currently open PR** (`open_pr_inventory`). The screening index bounds each body excerpt to 280 characters and each filename list to 12 entries, with an explicit truncation flag.
- An inventory of the **25 most recently merged PRs from the last 180 days** (`merged_pr_inventory`), bounded the same way. This is what lets you recognise that an issue was already fixed on the default branch when nothing in the issue references the fixing PR. A merged PR only enters `required_inspection` when the issue references it; otherwise it is inventory you must still screen.

Every candidate appears exactly once in the screening index: candidates carrying any exact, timeline, or commit source are in `required_inspection`; inventory-only candidates are in `open_inventory_screening`. An open required candidate has `open_inventory: true` (and a merged one `merged_inventory: true`), so it counts toward both required inspection and inventory screening without being duplicated between arrays.

The index also supplies deterministic lexical discovery signals. It normalizes nontrivial issue/PR title, body, and filename identifiers, removes common/template words, singularizes simple plurals, and scores bounded overlaps with fixed weights. `lexical_relevance.plausible: true` makes full inspection mandatory, but neither that boolean nor its score proves relevance, a fix, or a shared root cause.

Complete **both phases**, never skipping or sampling:

1. **Required-inspection phase:** Fully inspect every PR in `required_inspection`, including its real diff, complete changed-file list, commits, tests/checks, status, base branch, and review discussion. Exact references, timeline links, and commit mentions are candidates, never proof.
2. **Inventory screening phase:** Screen every inventory candidate, open and merged. Required candidates with `open_inventory: true` or `merged_inventory: true` are screened by their mandatory full inspection; screen every entry in `open_inventory_screening` from its compact title/body/file signals. Fully inspect the real PR/diff for every entry marked lexically plausible and every additional candidate that your judgment finds plausible. Record inventory-only entries found irrelevant as screened without loading full diffs. When the reported behavior does not reproduce against current default-branch source, treat `merged_pr_inventory` as the primary place to look for the change that fixed it, and name that PR rather than concluding only that it was "possibly fixed earlier".

Track `open_inventory_count` and `merged_inventory_count` from status, the plausible candidate numbers, and the fully inspected candidate numbers. Your screened total must equal `open_inventory_count` plus `merged_inventory_count`; every `required_inspection_number` and every plausible number must be fully inspected. Use these figures to drive your own inspection work — you do not retype them into the comment, because Step 6 publishes the pre-rendered `/tmp/gh-aw/agent/triage-screening-status.md` line instead. Classify all fully inspected candidates using the **Fix Confidence Tiers** below and report related/partial PRs even when they have no development link. A candidate marked lexically plausible always appears in your write-up, either as a confirmed fix or under **Related or partial PRs** — never silently dropped because you judged it irrelevant.

If the rendered status line reports that the contracts did not pass, or if a required or plausible candidate ends up not fully inspected, see **Incomplete or Failed Evidence Load or Screening** below.

### Candidate Discovery

The file above is a deterministic floor, not a ceiling — it does not replace judgment-driven searching. Run these complementary searches too, and treat every hit (from the file or from these searches) the same way: a lead requiring real inspection, never proof by itself. Do not rely on one title query or an arbitrary six-month window.

1. **Inspect existing links and timeline references** — Review PRs, commits, and releases already referenced by the issue or its comments, including the timeline entries already captured in the prefetched file.
2. **Search for the exact issue number without a date limit** — Confirm and extend the prefetched title/body/comment/commit-message matches with your own search, in case the deterministic pass hit a pagination or rate-limit ceiling (see `errors` in the file).
3. **Run several semantic PR searches** — Search open, closed, and merged PRs using:
   - Distinctive error-message fragments and symptoms.
   - Terraform resource, data source, variable, output, module, and provider names.
   - Relevant file paths and Azure resource types.
   - Likely fix language combined with the affected component, such as `fix`, `resolve`, `correct`, `validation`, or `regression`.
4. **Search default-branch history** — Search commits after the issue was created, plus earlier commits when the report may concern a fix that existed before the issue was filed. Trace promising commits back to their PR when possible.
5. **Check releases** — Determine whether a validated fix is available in a release. Review release notes and tags, and identify the first release containing the merged fix when possible.

Open every promising candidate — from the prefetched file and from these searches — and inspect its title, body, changed files, diff, commits, tests, review discussion, merge target, and merge status. A shared keyword, file, module, or resource is only a lead; it is not proof that the PR fixes the issue.

### Fix Confidence Tiers

Classify each candidate before taking any write action:

- **Confirmed fix:** The issue and PR describe the same observed behavior and root cause; the diff changes the affected code path in a way that resolves that behavior; tests, release notes, review discussion, or equivalent evidence support that conclusion; and the issue does not contain evidence that the problem persists after the change. A merged PR must be merged into the repository's default branch to count as an existing fix.
- **Likely related fix:** The PR changes the right area and may address the issue, but the same root cause or complete resolution cannot be proven. Mention it for maintainer review, but do not modify the PR or close the issue.
- **Related only:** The PR concerns the same component but a different behavior or root cause. It may be listed as related, but do not modify the PR or close the issue.
- **No candidate found:** Continue to Step 5.

**False-positive protection:** Never link or close based only on title similarity, shared labels, a common file, broad component overlap, or an AI-generated claim in another comment. If the issue is broader than the PR, the fix requires multiple PRs, the issue reports a new variant, or evidence conflicts, downgrade the candidate and leave the issue open.

### Incomplete or Failed Evidence Load or Screening

The rendered status line at `/tmp/gh-aw/agent/triage-screening-status.md` is the authority on whether the deterministic evidence load succeeded. Do not infer failure or truncation from how much output a terminal or UI happens to display.

The load or screening is incomplete when that rendered line reports the contracts did not pass, or when your own screening work falls short: a required candidate was not fully inspected, or a plausible candidate was not fully inspected. In that case:

- **Continue the full read-only investigation.** Keep searching and reading issues, PRs, commits, and releases exactly as described above — an incomplete prefetch never excuses skipping analysis.
- **Conservatively block two specific write actions for this run:**
  1. Do not close the issue as `completed` under **Close an Issue That Is Already Fixed** below.
  2. Do not append `Fixes #<issue-number>` to any PR under **Link an Unlinked Fix PR** below.
- **Labels, the issue type, and the triage comment are unaffected** — continue to apply `add-labels`, `set-issue-type`, and post the Step 6 comment normally.
- **Explain the veto in the triage comment**: state that the deterministic evidence load or your screening was incomplete and that confirmed-fix closure and PR linking were skipped this run. Never claim that evidence was truncated merely because displayed output was shortened.

This veto applies only to the two write actions above. It does **not** apply to and must never weaken the **Duplicate Closure Flow** in Step 2: a duplicate closure (`close-issue` with the `duplicate` state reason) is decided solely by the duplicate-confidence rules in Step 2, is independent of this file, and remains fully allowed when the duplicate match is conclusive **even if this evidence load is missing, incomplete, or failed** — including when a separately discovered fix candidate is still open or unmerged. Missing or inconclusive fix-PR evidence must never downgrade or skip an otherwise-conclusive duplicate closure.

### Link an Unlinked Fix PR

If a PR is a **confirmed fix**, is clearly intended to resolve this issue, and its body does not already contain a closing keyword for the issue:

1. Use `update-pull-request` to append exactly this standalone line to that PR's body:

   ```
   Fixes #<issue-number>
   ```

2. Mention the PR-body update in the triage summary.

Do not add the marker to more than one PR per run. Do not add it when the PR only partially addresses the issue, when multiple PRs are jointly required, or when confidence is below the **confirmed fix** tier. An open confirmed-fix PR may be linked, but the issue must remain open until the PR is merged. Do not perform this action at all when the **Incomplete or Failed Evidence Load or Screening** veto above is active.

### Close an Issue That Is Already Fixed

**AVM closes a module issue only once the fix is published, not when it merges.** The AVM Terraform issue-triage guide is explicit: *"Only close the issue, once the next version of the module was fully developed, tested and published."* A user consuming the module from the registry still has the bug until a release carries the fix, so merging is not resolution.

Do not judge release state from a PR body, a changelog, an earlier comment, or the age of the fix. It is computed for you.

`/tmp/gh-aw/agent/release-status.json` holds the answer:

| field | meaning |
|---|---|
| `loaded` | `false` means the lookup failed — treat every fix as unreleased |
| `has_release` | `false` means the module has never been released |
| `latest_tag` / `latest_published_at` | the newest release |
| `unreleased_shas` | merge commits on the default branch that no release contains |
| `unreleased_pr_numbers` | the PR numbers those commits reference |

**A merged fix is released when its PR number is absent from `unreleased_pr_numbers` and its merge commit is absent from `unreleased_shas`.** Present in either list means merged but not yet released.

Close the issue as `completed` only when the fix is **confirmed**, the Human Reopen Override is not active, the **Incomplete or Failed Evidence Load or Screening** veto is not active, **and the fix is released** by the test above.

When the fix is confirmed but **not yet released**, do all of this and nothing more:

- **Leave the issue open.** Never use `close-issue` on an unreleased fix, however conclusive the evidence.
- Apply `Status: Awaiting Release To Be Cut :scissors:` with `add-labels` — AVM defines it as *"This is fixed in the main branch but not in the latest release, will be fixed with next release cut"*, which is exactly this state. Emit it only if that name is present in `repo-labels.json`.
- In the triage comment, name the fixing PR, state that the fix is on the default branch, and name `latest_tag` as the most recent release that does **not** contain it.
- Do not ask a maintainer to cut a release in the comment. The label is the signal AVM already uses for this; a second request in prose is noise.

Before closing a released fix, post the Step 6 triage comment identifying the PR, the commit, and the release that first carried it, and recommend that version. Then use `close-issue` with `state_reason: completed`, naming the fixing PR in the body. Do not set `duplicate_of` on a fix-confirmed closure — that reason is only for duplicates.

Do **not** close for an open or draft PR, an unmerged branch, a merely likely match, a partial fix, conflicting evidence, a fix whose default-branch inclusion cannot be verified, or a fix that is merged but unreleased. When uncertain, leave the issue open and explain what a maintainer should verify.

---

## Step 5: Investigate and Suggest a Fix

Once you have identified what the issue is about, attempt to investigate the root cause by reading relevant source code from this repository and, if needed, compare with the canonical hub-and-spoke module.

### Investigation Guidelines

- **This repository is checked out locally at `$GITHUB_WORKSPACE` on the default branch.** Reading it with shell tools (`ls`, `cat`, `rg`, `find`) is the fastest and most reliable way to establish what the current source actually contains, and it is the required way to check whether a file, test, example, variable, or output exists. Never state that something is absent from the repository without listing the relevant directory in this run — an inherited or assumed absence is the most common way this triage publishes a false claim.
- Use the GitHub MCP tools to read files, search code, and list commits in this repository.
- Look for the specific module, file, variable, output, example, or resource referenced in the issue.
- For Terraform module issues, inspect the module implementation, variables, outputs, examples, and tests.
- If the issue seems related to Azure behavior, use the **Microsoft Docs MCP** (`microsoftdocs`) to confirm the expected behavior from official documentation.
- Where useful, compare against the conventions in the canonical hub-and-spoke VNet module
  (`Azure/terraform-azurerm-avm-ptn-alz-connectivity-hub-and-spoke-vnet`) — **unless this
  repository *is* that module** — as an example of well-structured AVM Terraform code. Reading
  other public AVM repos for reference is fine; never write to them.
- If you can identify a likely root cause or a specific file/line that may need changing, include that in your triage comment.
- Keep suggestions brief and actionable.
- If the issue is a question, feature request, or consideration rather than a bug, that is perfectly fine. Note it as such in your triage comment.
- If you cannot identify a likely fix, simply state that further investigation is needed. Do not speculate.
- Never create PRs, issues, or comments in other repos. The only permitted PR write is appending the confirmed-fix marker described in Step 4 to a PR in this repository.

---

## Step 6: Post a Triage Summary Comment

**Do not emit any safe outputs until ALL analysis steps (Steps 1–5) are complete.**

ALWAYS post **exactly one new** comment on the issue using the `add-comment` safe output, even if no triage actions were taken. **This comment is mandatory and is the primary deliverable of this workflow — a run that emits `add-labels` or `set-issue-type` without also emitting `add-comment` is a failed run.** Emit `add-comment` even when the issue is spam, invalid, unintelligible, a duplicate, or when you took no other action. On a manual rerun, reassess the issue from scratch instead of trusting the previous triage result. Before posting the new result, the `add-comment` handler marks older comments from this same `issue-triage` workflow as outdated and minimizes them. It identifies workflow-owned comments using their hidden `gh-aw-workflow-id` metadata, so human comments and comments from other workflows are not affected. The comment must follow this exact format:

```
## 🤖 GitHub Agentic Workflow Automated Triage 🤖

> ⚠️ _This triage was generated automatically by an AI agent and may be incomplete or inaccurate._

<summary of actions as bullet points>

<details>
<summary><b>🔎 What this triage looked at</b></summary>

<paste the contents of /tmp/gh-aw/agent/triage-audit-block.md verbatim here, then the contents of /tmp/gh-aw/agent/triage-screening-status.md verbatim, then the not-related must_compare line, then the key sources you opened — issues, source files, releases>

</details>
```

The visible bullet points stay focused on conclusions; the collapsed **"What this triage looked at"** accordion is where the prefetched query list and the sources you opened go, so a maintainer can audit coverage without it cluttering the comment.

**Accordion rendering rules (important):**
- The `<details>` block is **collapsed by default** — do not add the `open` attribute.
- You **must** leave a blank line immediately after the `</summary>` line and immediately before the closing `</details>` line. Without these blank lines GitHub will not render the Markdown inside — bullet lists and code fences will come out broken.
- Paste the rendered audit block verbatim, then list the sources you actually opened, not a generic placeholder. If the index did not load and you opened no sources (e.g. a pure no-op triage), omit the accordion.

If the issue has already been triaged, do not skip analysis. Publish the current result after completing Steps 1-5. Only when there is genuinely nothing actionable to report, post:

```
## 🤖 GitHub Agentic Workflow Automated Triage 🤖

> ⚠️ _This triage was generated automatically by an AI agent and may be incomplete or inaccurate._

- Issue assessed, no input from GitHub agentic workflow agent.
```

The bullet points should include:

- **Duplicate check result:** Report only the candidates that carry a verdict a maintainer would act on — the confirmed duplicate, any possible duplicate, and anything genuinely related — with links and a few words of reason. If closing as duplicate, state this clearly with the link. Every remaining `.must_compare` number still has to be accounted for, but as a single "not related" line inside the collapsed accordion, not here. If nothing came back related, this bullet is one sentence.
- **Issue type:** Name the type you set, in one short line — you set one on every run, so this is never "no change needed". Mention a previous value only if `/tmp/gh-aw/agent/issue-type.txt` literally contains it; a run that reported "already set to `Bug`" while that file read `NONE` is the defect this wording exists to prevent.
- **Labels applied:** List only the labels you **added** in this run, with a brief justification for each (e.g., "Applied `bug` — issue reports a failed `terraform apply`"). **Do NOT list or re-justify labels that were already on the issue.** If you added no new labels, say so in a single short line (do not enumerate the existing labels).
- **No labels applied:** If no labels could be confidently determined, state this.
- **Labels skipped:** If label definitions could not be loaded, state "Labels could not be applied due to a data loading error."
- **Suggested fix:** If you identified a likely root cause or potential fix from investigating the source code, include it with specific file/line references. If the issue is a question or consideration rather than a bug, note that. If you could not determine a fix, state that further investigation is needed.

  Put any configuration, HCL, or command a reader might copy in a fenced code block with a language tag, never inline in the prose. Keep the surrounding explanation to a sentence before and, if needed, a sentence after:

  ````
  As a workaround, add the pattern to `managed_devops_pool_retry_on_error`:

  ```hcl
  managed_devops_pool_retry_on_error = [
    "Missing Resource Identity After Update"
  ]
  ```

  The longer-term fix is to add this pattern to the variable's default in `variables.tf`.
  ````
- **Already fixed:** If a recent release or merged PR already addresses this issue, tell the user which version or PR contains the fix and recommend they upgrade. If nothing does, this bullet is one short sentence saying so. Do not list, count, or characterise the PRs you inspected to reach that conclusion — the rendered screening line in the accordion already records exactly which ones were mandatory, so restating them here is duplicate evidence, not reassurance.
- **PR linked:** If you appended `Fixes #<issue-number>` to a confirmed-fix PR, identify the PR and state that it is now linked. Do not claim an ambiguous candidate was linked.
- **Related or partial PRs:** Always report any PR you classified as **likely related fix** or **related-only** in Step 4, with a link and a one-line reason, even though you deliberately did not link or close against it. Do not omit these just because no write action was taken on them — surfacing them is the point, so a maintainer can judge candidates you intentionally left out of the automated decision. Every candidate named as lexically plausible in the rendered screening-status line must appear here unless you reported it as a confirmed fix; if you judged one irrelevant, say so and why, rather than leaving it unmentioned.
- **PR-evidence and screening status:** This line is rendered for you, and it belongs **inside the collapsed accordion**, not in the visible bullets — it is machine evidence for auditing a run, not a finding a maintainer needs to read. Handling rules are under the accordion bullet below.
- **Closure:** Required on any run that emits `close-issue`, with no exception — a closure whose comment never mentions being closed reads to the reporter as an unexplained state change. State the evidence, name the release that carries the fix (or the canonical issue, for a duplicate), and end with a sentence inviting the reporter to reopen if the closure is wrong. That sentence is load-bearing: a human reopening is the only thing that triggers the Human Reopen Override, which is the one veto protecting a reporter from a wrong closure. Two of the first six real closures shipped without this bullet, so before emitting `close-issue`, confirm the comment carries it.
- **Awaiting release:** If a confirmed fix is merged but not yet released, say so here instead of under Closure — name the fixing PR, state that it is on the default branch, name `latest_tag` as the newest release that does not contain it, and note that the issue stays open until a release carries the fix.
- **Human reopen override:** If this workflow previously closed the issue and a person later reopened it, state that the issue will remain open for human review even if the agent found a duplicate or an existing fix.
- **What this triage looked at (collapsed accordion):** At the very bottom of the comment, include a collapsed `<details>` block containing, in order: the verbatim contents of `/tmp/gh-aw/agent/triage-audit-block.md`; the verbatim contents of `/tmp/gh-aw/agent/triage-screening-status.md`; one line accounting for any `.must_compare` candidates you judged not related; the deterministic PR-evidence sources that fired (e.g. timeline cross-reference, exact issue-number match in a title/body/comment, commit-message reference, commit-body `Refs #N`); and the key sources you inspected. This is the run's audit trail — keeping it here is what lets the visible summary stay short.

  Paste both rendered files **verbatim**, exactly as written, including every count and candidate number. Do not re-derive any figure, do not shorten or omit a candidate list, and do not replace a list with a summary such as "none this run" — the rendered lines are already correct, and any difference between those files and your comment is a defect. If, and only if, you fully inspected candidates beyond the ones the screening line names, append one sentence naming those extra numbers. If the screening line reports that the index did not load, that is a failed evidence load: say so in the **visible** bullets, stating that confirmed-fix closure and PR linking were skipped (see Step 4 — Incomplete or Failed Evidence Load or Screening) while noting duplicate-closure decisions were unaffected. Never report truncation based on display length.

Keep the comment concise and factual. Do not speculate or add unnecessary detail.

**Length.** The visible part of the comment — everything above the accordion — should read in well under a minute. Aim for roughly 1,500 characters and treat 2,500 as the ceiling; past that, the finding is being buried rather than explained. The accordion is exempt, which is exactly why the exhaustive lists live there. To stay inside it:

- One bullet per finding. Omit a bullet entirely when it has nothing to report, rather than writing a sentence to say so.
- Name a specific issue or PR when it changes what the reader should do. Do not enumerate what you ruled out — the accordion already proves the coverage.
- Never restate the same evidence in two bullets.
- Do not narrate your own process ("I checked all N candidates", "searches were run"). The accordion is the record of process.
- Write bare `#123` only when you intend GitHub to expand it into that item's title. For any list of more than two or three numbers, use `` `#123` `` so the list stays a list instead of rendering as a paragraph of titles.

### Duplicate Closure Flow

When you are **highly confident** an issue is a confirmed duplicate of another (the **same underlying problem / root cause** — see Step 2's *Confirmed duplicate* tier) and the Human Reopen Override is not active, follow this exact sequence:

1. **First**, post your triage comment using `add-comment`. The comment MUST include a note advising the issue creator to reopen if the closure was incorrect:

   ```
   > **Note:** If you believe this issue was incorrectly closed as a duplicate, please reopen it and explain how it differs from the linked issue.
   ```

2. **Then**, close the issue using `close-issue`. Its `body` must be exactly the following single-line GitHub marker, with no heading or additional text:

   ```
   Duplicate of #<canonical-issue-number>
   ```

   The `close-issue` handler accepts a per-closure `state_reason`. Always set `state_reason: duplicate` here, and set `duplicate_of` to the canonical issue number so GitHub records the native duplicate link. All explanation belongs in the separate `add-comment` triage summary.

   Always reference the canonical issue chosen by the Step 2 rule — the lowest-numbered match that is still open.

### Example Comment (not a duplicate)

```
## 🤖 GitHub Agentic Workflow Automated Triage 🤖

> ⚠️ _This triage was generated automatically by an AI agent and may be incomplete or inaccurate._

- **Duplicate check:** No exact duplicates found. Similar issue: #1234 (related to a similar Terraform module behavior).
- **Labels applied:**
  - `bug` — issue reports unexpected behavior or a failed `terraform apply`
  - `needs-more-info` — issue does not include enough information to reproduce or investigate
- **Suggested fix:** The issue appears to relate to the module implementation in this repository. Compare the resource and variable patterns with the hub-and-spoke VNet module (when applicable) (`Azure/terraform-azurerm-avm-ptn-alz-connectivity-hub-and-spoke-vnet`) to confirm whether the local implementation is missing validation or using a different pattern.

<details>
<summary><b>🔎 What this triage looked at</b></summary>

- Prefetched duplicate searches (from `issue-candidate-index.json`):
  - `apply failed` → #101, #145
  - `validation subnet` → #145
  - `address_space error` → no results
- Candidates requiring explicit comparison: #101, #145
- Reviewed source: `main.tf`, `variables.tf` in this repository
- Checked the latest release notes for a prior fix

</details>
```

### Example Comment (possible duplicate — left open)

```
## 🤖 GitHub Agentic Workflow Automated Triage 🤖

> ⚠️ _This triage was generated automatically by an AI agent and may be incomplete or inaccurate._

- **Possible duplicate of #4321** — this appears to describe the same underlying problem, but it also raises a separate question about the expected behavior, so I have left it open for a maintainer to confirm rather than closing it. Also compared #4102 — related, but it concerns the subnet delegation path rather than address-prefix validation, so it is a different root cause.
- **Labels applied:**
  - `bug` — issue reports a failed `terraform apply`
  - `question` — the issue also asks whether the current behavior is intended

<details>
<summary><b>🔎 What this triage looked at</b></summary>

- Prefetched duplicate searches (from `issue-candidate-index.json`):
  - `subnet validation` → #4321
  - `expected behavior` → #4321, #4102
  - `address prefix` → no results
- Candidates requiring explicit comparison: #4321, #4102
- Opened and compared #4321 to assess whether it is the same root cause

</details>
```

### Example Comment (closing as duplicate)

```
## 🤖 GitHub Agentic Workflow Automated Triage 🤖

> ⚠️ _This triage was generated automatically by an AI agent and may be incomplete or inaccurate._

- **Duplicate:** Closing as duplicate of #5678 — both issues report the same Terraform module failure with similar error messages and context. Also compared #5012 — same error text, but it was raised against the parent module rather than this one, so it is not related.
- **Labels applied:**
  - `bug` — issue reports a module error or failed `terraform apply`
  - `duplicate` — if this label exists in the repository label set and the issue is being closed as a duplicate

> **Note:** If you believe this issue was incorrectly closed as a duplicate, please reopen it and explain how it differs from the linked issue.

<details>
<summary><b>🔎 What this triage looked at</b></summary>

- Prefetched duplicate searches (from `issue-candidate-index.json`):
  - `module failure` → #5678, #5012
  - `apply error` → #5678
  - `provider timeout` → no results
- Candidates requiring explicit comparison: #5678, #5012
- Compared against #5678 (same error and context); confirmed #5678 is the oldest matching issue

</details>
```

---

## Safe Outputs

**Important:** Do not emit any safe outputs until ALL analysis steps (Steps 1–5) are complete.

**Every issue safe output in this run must carry the target issue number.** On a manual rerun there is no issue in the event context, so a call that omits the number is rejected with "No issue/PR number available" and that label or type is silently lost while the comment still posts and looks correct. The number for this run is **#${{ github.event.inputs.issue_number || github.event.issue.number }}**, and it is also on disk at `/tmp/gh-aw/agent/issue-number.txt`.

Every issue safe output carries it, in every combination — never only the first call, and never only the comment:

```json
{"type": "add_labels", "item_number": ${{ github.event.inputs.issue_number || github.event.issue.number }}, "labels": ["bug"]}
{"type": "set_issue_type", "issue_number": ${{ github.event.inputs.issue_number || github.event.issue.number }}, "issue_type": "Bug"}
{"type": "add_comment", "item_number": ${{ github.event.inputs.issue_number || github.event.issue.number }}, "body": "## 🤖 GitHub Agentic Workflow Automated Triage 🤖 …"}
{"type": "close_issue", "issue_number": ${{ github.event.inputs.issue_number || github.event.issue.number }}, "state_reason": "duplicate", "duplicate_of": 4321, "body": "Duplicate of #4321"}
```

`add-comment` and `add-labels` use `item_number`; `close-issue` and `set-issue-type` use `issue_number`. When updating a pull request, use that PR's number as `pull_request_number`. Before you emit anything, check each call you are about to make and confirm the number is present on all of them.

- If you **close the issue** as a duplicate: Use `add-comment` for the triage summary **first**, then use `close-issue` with `state_reason: duplicate`, `duplicate_of: <canonical-issue-number>`, and a body of exactly `Duplicate of #<canonical-issue-number>`. See the Duplicate Closure Flow.
- If you **close the issue** because it is conclusively fixed: Use `add-comment` for the triage summary **first**, then use `close-issue` with `state_reason: completed` and a body naming the fixing PR. Do not set `duplicate_of` on this path.
- If the **Human Reopen Override** is active: Never use `close-issue`, regardless of duplicate or fix confidence. Continue with any non-closing outputs and explain the veto in the triage comment.
- If you find an unlinked **confirmed-fix PR**: Use `update-pull-request` with `pull_request_number`, `operation: append`, and a body of exactly `Fixes #<issue-number>`. Do not update likely or merely related candidates.
- Use `set-issue-type` with `issue_number` and exactly one of `Bug`, `Feature`, or `Task` on **every** run. Emit it unconditionally — never skip it on the grounds that the type looks already correct. Those three strings are the entire allowed list; a usage question is `Task`, not `Question`.
- If you find a **possible duplicate** but are **not highly confident** it is the same root cause: do **NOT** use `close-issue`. Use `add-comment` to flag `Possible duplicate of #N` (with the link) and leave the issue open; apply labels with `add-labels` as usual (but not `duplicate`). Reserve `close-issue` for confirmed duplicates only.
- If you **add labels AND post a comment** (most common case): Call **both** `add-labels` (to apply labels to the issue) AND `add-comment` (for the triage summary), and put `item_number` on **both** — the observed failure mode is a run that attaches the number to the comment and omits it from the labels, which loses the labels while the comment still publishes. ⚠️ Listing label names inside the comment body does NOT apply them — you MUST call `add-labels` as a separate action.
- If you **only post a comment** (no labels to add, no close): Use `add-comment` alone. Do not also emit `add-labels` with an empty list to signal "nothing to add" — omit the call entirely. The unconditional rule above applies to `set-issue-type` only.
- On a manual rerun, perform a complete fresh assessment. Use `add-comment` for the current result; the handler will mark older comments carrying this same workflow's hidden `gh-aw-workflow-id` as outdated and minimize them.

---

## Important Context

- This repository contains the Terraform code for a single AVM module.
- Issues, labels, releases, and code investigation all happen in this repository.
- All repositories are public — you can read code, search for files, and list commits using the GitHub MCP tools.
- Use the Microsoft Docs MCP (`microsoftdocs`) when you need to ground your answers in authoritative Azure guidance, especially for architecture or behavior questions.
- Never create issues, PRs, or comments in other repos, and never update a PR outside this repository.
- Be conservative when **closing** duplicates: close only when you are highly confident two issues share the same root cause. False positives (wrongly closing a valid issue) are much worse than false negatives. When unsure, downgrade to a *Possible duplicate* and link it instead of closing. Detection, by contrast, should be thorough — always surface candidates you find, even ones you do not close.
- Apply the same conservative standard to existing fixes. Only append `Fixes #N` or close as completed when the PR-to-issue relationship is directly supported by the issue details and the actual code change.
- A person's reopen after this workflow closed an issue always takes precedence over the agent's duplicate and existing-fix conclusions. Once detected in the timeline, leave the issue open for human review on every later run.
- When composing your triage comment, never reproduce `@mentions` from the issue body or linked content.
- This workflow is in **early stages** and is **AI-generated**. Always include the disclaimer line shown in Step 6 at the top of every triage comment (immediately under the heading), so issue authors know the triage is automated and may be imperfect.
