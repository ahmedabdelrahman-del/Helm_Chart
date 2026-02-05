variable "project_name"{
    type = string
}
variable "instance_class"{
    type = string
    default = "db.t3.micro"
    validation {
      condition = contains(["db.t3.micro"], var.instance_class)
      error_message = "instance_class must be db.t3.micro"
    }
}
variable "storage_size"{
    type = number
    default = 10
    validation {
      condition = var.storage_size >= 5 && var.storage_size <= 10
      error_message = "storage_size must be between 5 and 10"
    }
}
variable "db_engine"{
    type = string
    default = "postgres"
    validation {
      condition = contains(["mysql", "postgres"], var.db_engine)
      error_message = "db_engine must be either mysql or postgres"
    }
}
variable "credentail"{
    type = object({
      username = string
      password = string 
    })
    sensitive = true
    validation {
      condition = can(regex("^(?=.*[a-zA-Z])(?=.*\\d).{6,}$", var.credentail.password))
      error_message = <<-EOT
      password must comly the following format
      1- contain at least one charachter
      2- contain at least one number
      3- be at least 6 characters long
EOT
    }
}