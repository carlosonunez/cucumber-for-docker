#!bats

setup() {
  if ! docker images 2>/dev/null | grep -q cucumber
  then
    >&2 echo "ERROR: Please run 'make build' before running your tests."
    return 1
  fi
}

@test "Cucumber is installed" {
  run docker run --rm cucumber --version
  >&2 echo "MORE: Expected a version number but got: $output"
  [ "$status" -eq 0 ]
}
