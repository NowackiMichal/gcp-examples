variable "region" {
  type        = string
  default     = "europe-central2"
  description = "europe-central2 region"
}
variable "zone" {
  type        = string
  default     = "europe-central2-c"
  description = "europe-central2-c zone"
}
variable "project_id" {
  type = string
}
variable "user" {
  type = string
}
variable "email" {
  type = string
}
variable "privatekeypath" {
  type    = string
}
variable "publickeypath" {
  type    = string
}
