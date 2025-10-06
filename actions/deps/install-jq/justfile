# if GitHub -> gh cli
# - try to find tests
# - ID default depends_on

# - ID probable depends_on
template-formula url:
    #!/usr/bin/env bash
    require("gh") repo view "{{ url }}"
      --json
          description,
          url,
          owner,
          name,
          languages,
          licenseInfo,
          homepageUrl,
          latestRelease,
          isArchived
    | jq -f .github/jq/format-formula.jq
    | require("mustache") .github/templates/formulas/formula.mustache

_get_tags url:
    require("gh") api \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "/repo/{{ url }}/tags"
