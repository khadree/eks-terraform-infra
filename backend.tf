terraform {
  cloud {
    organization = "Teleios"
    workspaces {
      tags = ["teleios-kadiri"]
    }
  }
}