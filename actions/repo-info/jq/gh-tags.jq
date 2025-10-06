[
  .[]
  | "{
    tag: \(.tag_name),
    commit: \(.commit.sha),
    owner: $o,
    repo: $r
  }"
]
