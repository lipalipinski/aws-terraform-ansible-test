output "Jenkins-Master-Public-IP" {
  value = aws_instance.jenkins-master.public_ip
}

output "Jenkins-Workers-Public-IP" {
  value = {
    for instance in aws_instance.jenkins-worker :
    instance.tags.Name => instance.public_ip
  }
}

output "Jenkins-Master-Private-IP" {
  value = aws_instance.jenkins-master.private_ip
}

output "Jenkins-Workers-Private-IP" {
  value = {
    for instance in aws_instance.jenkins-worker :
    instance.tags.Name => instance.private_ip
  }
}