terraform {
  cloud {

    organization = "Teleios"

    workspaces {
      name = "teleios-kadiri-dev"
    }
  }
}