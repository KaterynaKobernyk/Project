
resource "aws_launch_configuration" "launch_configuration" {
  name            = "App_Launch_config"
  image_id        = "${lookup(var.amis, var.aws_region)}"
  instance_type   = "t2.micro"
  key_name        = "${var.aws_key_name}"
  security_groups = [aws_security_group.web.id]
  user_data       = <<-EOF
            #!/bin/bash

            
            sudo apt-get -y update
            sudo apt-get -y upgrade
            sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
            sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

            sudo echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable">

            sudo apt-get update -y
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io
            sudo apt-cache madison docker-ce
            sudo apt-get install docker-ce=5:20.10.8~3-0~ubuntu-focal docker-ce-cli=5:20.10.8~3-0~ubuntu-focal containerd.io
            sudo docker run hello-world
            sudo apt-get update
            sudo cat << EOF > /etc/docker/daemon.json
            {
                "exec-opts": ["native.cgroupdriver=systemd"]
            }
              EOF
              
}
resource "aws_autoscaling_group" "autoscalling_group" {
  name                      = "App_autoscaling-group"
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 50
  health_check_type         = "EC2"
  desired_capacity          = 2
  force_delete              = true
  vpc_zone_identifier       = [aws_subnet.us-west-1a-public.id]
  launch_configuration      = aws_launch_configuration.launch_configuration.name
  lifecycle {
    create_before_destroy = true
  }


   tag {
    key                 = "Name"
    value               = "App docker"
    propagate_at_launch = true
  }



}
resource "aws_autoscaling_policy" "autoscalling_policy" {
  name                   = "App_autoscaling-policy"
  autoscaling_group_name = aws_autoscaling_group.autoscalling_group.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 40.0
  }
}