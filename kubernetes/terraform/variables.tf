variable project {
  description = "Project ID"
}

variable region {
  description = "Region"
  default     = "us-central1"
}

variable zone {
  description = "Zone"
  default     = "us-central1-a"
}

variable enable_legacy_abac {
  description = "Legacy rights"
  default     = "false"
}