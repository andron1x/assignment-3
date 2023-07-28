variable "ingress_ports" {
    description = "ports 22, 80, 443"
    default = [22, 80, 443] 
}

variable "ami" {
    description = "AMAZON Linux 2"
    default = "ami-0f9ce67dcf718d332"
  
}