# Process GitHub API tags response
# Input: GitHub API tags array
# Output: Latest tag info

if . == [] or . == null then
  empty
else
  .[0] | {
    tag: .name,
    sha: .commit.sha,
    tarball_url: ("https://github.com/" + ($owner // "") + "/" + ($repo // "") + "/archive/refs/tags/" + .name + ".tar.gz")
  }
end
