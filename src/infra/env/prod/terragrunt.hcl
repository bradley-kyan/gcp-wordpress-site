remote_state {
  backend = "gcs"
  config = {
    location = "us"
    project  = "1035436763117"
    bucket   = "website-prod-tfstate"
    prefix   = "prod"
  }
}

terraform {
  source = "../../codebase"
}