# Extract formula data into structured output
# Input: formula.json array
# Output: Individual formula objects with fields

.[] |
select(.owner != "" and .repo != "") |
{
  owner: .owner,
  repo: .repo,
  formula: .formula,
  current_tag: .tag,
  current_sha256: .sha256
}
