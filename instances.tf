# get amz linux AMI ID in master region
data "aws_ssm_parameter" "linuxAmiMaster" {
  provider = aws.region-master
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# get amz linux AMI ID in worker region
data "aws_ssm_parameter" "linuxAmiWorker" {
  provider = aws.region-worker
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# create kp for ec2 in master region
resource "aws_key_pair" "master-key" {
  provider   = aws.region-master
  key_name   = "jenkins"
  public_key = file("./ssh-keys/rsa-kp.pub")
}

# create kp for ec2 in worker region
resource "aws_key_pair" "worker-key" {
  provider   = aws.region-worker
  key_name   = "jenkins"
  public_key = file("./ssh-keys/rsa-kp.pub")
}

# create ec2 in master region
resource "aws_instance" "jenkins-master" {
  provider                    = aws.region-master
  ami                         = data.aws_ssm_parameter.linuxAmiMaster.value
  instance_type               = var.instance-type
  key_name                    = aws_key_pair.master-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins-sg.id]
  subnet_id                   = aws_subnet.subnet_1.id

  tags = {
    Name = "jenkins_master_tf"
  }

  depends_on = [aws_main_route_table_association.set-master-rt]

  provisioner "local-exec" {
    command = <<EOF
      aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.region-master} --instance-ids ${self.id}
      ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name}' ansible_templates/jenkins-master-sample.yml
      EOF
  }
}

# create ec2 in worker region
resource "aws_instance" "jenkins-worker" {
  provider                    = aws.region-worker
  count                       = var.workers-count
  ami                         = data.aws_ssm_parameter.linuxAmiWorker.value
  instance_type               = var.instance-type
  key_name                    = aws_key_pair.worker-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins-worker-sg.id]
  subnet_id                   = aws_subnet.subnet_1-worker.id

  tags = {
    Name = join("_", ["jenkins_worker_tf", count.index + 1])
  }

  depends_on = [
    aws_main_route_table_association.set-worker-rt,
    aws_instance.jenkins-master
  ]
}