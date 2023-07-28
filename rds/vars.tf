variable "subnet_ids" {
    type = list(string)

}
variable "vpc_id" {}
variable "sg_id" {}
variable "db_password" {
    default = "test1234"
}
