output "elb_fqdn" {
    value = aws_elb.wp_lb.dns_name
}

 output "wp_inst-01_ip" {
     value = aws_instance.wp_inst-01.public_dns
 }

 output "wp_inst-02_ip" {
     value = aws_instance.wp_inst-02.public_dns
 }