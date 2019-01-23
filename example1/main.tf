provider "aws" {
  region = "us-west-2"
}

resource "aws_iam_role" "cloud-watch" {
name = "cloud-watch"
assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "cloud-watch-attach" {
    name = "cloud-watch-attach"
    roles = ["${aws_iam_role.cloud-watch.name}"]
    policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  
}

resource "aws_iam_instance_profile" "test" {
name = "test"
roles = ["${aws_iam_role.cloud-watch.name}"]  
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    
  }
}

resource "aws_key_pair" "sysop-keypair" {
  key_name   = "mykey"
  public_key = "${file("mykey.pub")}"
}


resource "aws_instance" "udemy" {
  ami           = "ami-03c652d3a09856345"
  instance_type = "t2.micro"
  count = 2
  security_groups = ["${aws_security_group.allow_all.name}"]
  key_name = "${aws_key_pair.sysop-keypair.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.test.name}"
  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  sudo yum install -y perl-Switch perl-DateTime perl-Sys-Syslog perl-LWP-Protocol-https perl-Digest-SHA.x86_64
  cd /home/ec2-user/
  curl https://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.2.zip -O
  unzip CloudWatchMonitoringScripts-1.2.2.zip
  rm -rf CloudWatchMonitoringScripts-1.2.2.zip
  EOF

  tags {
    Name = "Udemy-Sysop-Cloudwatch"
  }
}

output "ip" {
  value = "${aws_instance.udemy.*.public_ip}" //Splat will output all
}


