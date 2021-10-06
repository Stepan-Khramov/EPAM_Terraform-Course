output "efs_dns_name" {
    value = aws_efs_file_system.efs_for_wp.dns_name
}
 
output "sql_hostname" {
    value = aws_db_instance.wp_db.address
}

# output "elb_public_ip" {
#     value = aws_eip.lb_public_ip.address
# }

output "elb_fqdn" {
    value = aws_elb.wp_lb.dns_name
}
 output "wp_inst-01_ip" {
     value = aws_instance.wp_inst-01.public_ip
 }

 output "wp_inst-02_ip" {
     value = aws_instance.wp_inst-02.public_ip
 }