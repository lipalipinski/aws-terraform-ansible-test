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