output "efs_dns_name" {
    value = aws_efs_file_system.efs_for_wp_db.dns_name
}
 
output "sql_hostname" {
    value = aws_db_instance.wp_db.address
}

