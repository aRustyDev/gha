def capital_case: (
  "\(.[0] | ascii_upcase)\(.[1:])"
);

def fmt_homebrew_formula_name(s): (
  s | sub("[-_]+"; " ") | split(" +";"") | map(capital_case) | join("")
);

"{
    'name': \(.name | fmt_homebrew_formula_name),
    'description': \(.description),
    'repo': \(.name | fmt_homebrew_formula_name),
    'user': \(.name | fmt_homebrew_formula_name),
    'tag': \(.name | fmt_homebrew_formula_name),
    'sha256': \(.name | fmt_homebrew_formula_name),
    'license': \(.name | fmt_homebrew_formula_name),
}
"
