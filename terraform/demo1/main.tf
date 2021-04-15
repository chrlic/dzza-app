data "external" "secrets" {
  program  = [ "cat", "secrets.json"]
}

