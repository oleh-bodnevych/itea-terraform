variable "name" {
  description = "Name to be used on all resources as prefix"
  type        = string
  default     = "test"
}
variable "ami_nat" {
  description = "AMI nat by region"
  type        = string
  default     = "ami-000d84e1c6fd278b9" # nat instance
}
variable "ami" {
  description = "AMI by region"
  type        = string
  default     = "ami-0da7ba92c3c072475" # Amazon linux 2
}
variable "instance_types" {
  description = "instance free triar"
  type        = string
  default     = "t2.micro"
}
variable "key_name" {
  description = "Name of the key pair"
  type        = string
  default     = "Paris"
}
variable "db_password" {
  description = "RDS root user password"
  type        = string
  sensitive   = true
}
variable "db_namedb" {
  description = "RDS Name DataBase"
  type        = string
  sensitive   = true
}
variable "db_adminnamedb" {
  description = "RDS root username"
  type        = string
  sensitive   = true
}
