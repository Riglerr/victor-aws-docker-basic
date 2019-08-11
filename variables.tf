variable "instance_group_name" {
    type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = set(string)
}

variable "listen_port" {
  type = number
  default = 80
}

variable "listen_protocol" {
  type = string
  default = "HTTP"
}

variable "server_port" {
  type = number
  default = 8080
}

variable "server_protocol" {
  type = string
  default = "HTTP"
}

variable "instance_type" {
  type = string
  default = "t2.micro"
}

variable "key_name" {
  type = string
  default = "admin-keypair-euwest2"
}


variable "ami_id" {
  type = string
}

variable "min_size" {
  type = number
  default = 1
}

variable "max_size" {
  type = number
  default = 2
}