    #!/bin/bash
    yum install -y httpd httpd-tools php php-cli php-json php-gd php-mbstring php-pdo php-xml php-mysqlnd php-pecl-zip wget nfs-utils firewalld policycoreutils-python-utils
    systemctl enable httpd
    systemctl enable firewalld
    mkdir -p /var/www/html
    echo "${aws_efs_file_system.efs_for_wp.dns_name}:/ /var/www/html      nfs     nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0" >> /etc/fstab
    mount -a
    echo "test_${aws_instance.wp_inst-01.name}" >> /var/www/html/test.html
    chown -Rf apache:apache /var/www/html/
    chmod -Rf 775 /var/www/html/
    sudo systemctl start httpd
    sudo systemctl start firewalld
    sudo firewall-cmd --zone=public --permanent --add-service=http && sudo firewall-cmd --reload
    cd /tmp
    wget https://www.wordpress.org/latest.tar.gz
    tar xzvf /tmp/latest.tar.gz --strip 1 -C /var/www/html
    rm -rf /tmp/latest.tar.gz
    sed -i "s/#ServerName www.example.com:80/ServerName ${aws_elb.wp_lb.dns_name}:80/" /etc/httpd/conf/httpd.conf
    sed -i "s/ServerAdmin root@localhost/ServerAdmin admin@${aws_elb.wp_lb.dns_name}/" /etc/httpd/conf/httpd.conf
    sed -i "s/SELINUX=disabled/SELINUX=enforcing/" /etc/selinux/config
    sudo setsebool -P httpd_can_network_connect 1
    sudo setsebool -P httpd_can_network_connect_db 1
    sudo setsebool -P httpd_use_nfs=1
    sudo semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/html(/.*)?"
    sudo restorecon -Rv /var/www/html/