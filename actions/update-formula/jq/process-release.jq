# Process GitHub API release response
# Input: GitHub API release JSON
# Output: Structured release info

if . == {} or . == null then
  empty
else
  {
    tag: .tag_name,
    tarball_url: .tarball_url,
    prerelease: .prerelease,
    created_at: .created_at,
    published_at: .published_at
  }
end
