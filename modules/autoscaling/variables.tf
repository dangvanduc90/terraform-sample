variable "project" {
  type = string
}

variable "vpc" {
  type = any
}

variable "sg" {
  type = any
}

variable "db_config" {
  type = object({
    username = string
    password = string
    database = string
    hostname = string
    port     = string
  })
}

variable "aws_availability_zones" {
  type = list(string)
}
