# Configure the AWS Provider

provider "aws" {         # provide the desired cloud platform
  region = "us-east-1"   # provide the desired region which you want to launch the infrastructure.
}

# Configure the AWS resources

resource "aws_vpc" "my_vpc" {             # Provide the name of the virtual private cloud
cidr_block =  "10.0.0.0/16"               # Provide the cidr_block of virtual private cloud
}
resource "aws_subnet" "public" {       # provide the name of your subnet
vpc_id = aws_vpc.my_vpc.id                 
cidr_block = "10.0.0.0/24"                     # Provide the desired cidr_block of the subnet
}
resource "aws_subnet" "private" {         # Configure the subnet 
vpc_id = aws_vpc.my_vpc.id             # Configure vpc with subnet
cidr_block = "10.0.1.0/24"
}
resource "aws_route_table" "public_route" {       # Configure the route table with default VPC" 
vpc_id = aws_vpc.my_vpc.id      
}
resource "aws_route_table_association" "public" {   # Associate the route table with the public subnet
route_table_id = aws_route_table.public_route.id
subnet_id = aws_subnet.public.id
}
resource "aws_route_table" "private_route" {       # Configure the route table with default VPC" 
vpc_id = aws_vpc.my_vpc.id     
}
resource "aws_route_table_association" "private" {  # Associate the route table with private subnet"
route_table_id = aws_route_table.private_route.id
subnet_id = aws_subnet.private.id
}
resource "aws_internet_gateway" "my_igw" {       # Configure the Internet Gateway with the VPC
vpc_id = aws_vpc.my_vpc.id
}
resource "aws_internet_gateway_attachment" "igw_vpc" {   # Attach the Internet Gateway with the VPC
internet_gateway_id = aws_internet_gateway.my_igw.id
vpc_id = aws_vpc.my_vpc.id
}
resource "aws_eip" "lb" {
  instance = aws_instance.private_instance.id
  domain   = "vpc"
}
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.private_instance.id
  allocation_id = aws_eip.lb.id
}
resource "aws_nat_gateway" "my_nat" {
  allocation_id = aws_eip.lb.id
  subnet_id     = aws_subnet.public.id
}  
resource "aws_key_pair" "ubuntu" {          # Create the key_pair for the instance
public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCuD6kRS1yot31C26Szji/pOzvIrBAHSlgfaOzH6MLb/7vaE/DelljYCJbhoKd5g6oDXztlS1a8TD0I61MlYXtl98M3pfSOyIcpo0bqDeAwNIIE/O0MFRX0giv7T93Iz233nQbrrG1itU2z2041sPqeCXXCuAez7w5ablsUOCKGueeUKCNkNPFASWqxB9E/7EIKXMAGrutxlNjthmctYarwM0+U/dOEb6HYfdM5eAQkbBCxHqizlZoUys3kgjRS/ASyES/V76w9m2kEkGhlTCyRvKFiHVZWmkAW6Q4DyElaNTfENNi3uSmIeBLbHljf4n3UzvpWL6iTtPNjNU0H+F01 vamshi krishna@LAPTOP-OAF5T10Q"
key_name = "ubuntu_key"
}
resource "aws_instance" "web" {     
ami = "ami-0c7217cdde317cfec"           # AMI of the instance
instance_type = "t2.micro"              # Provide the instance type for the instance
key_name = "ubuntu_key"                 # Provide the name of the keypair for the instance
subnet_id = aws_subnet.public.id      # Associate the subnet for the instance
availability_zone = "us-east-1a"
vpc_security_group_ids = [aws_security_group.my_sg.id]
}
resource "aws_instance" "private_instance" {     
ami = "ami-0c7217cdde317cfec"           # AMI of the instance
instance_type = "t2.medium"              # Provide the instance type for the instance
key_name = "ubuntu_key"                 # Provide the name of the keypair for the instance
subnet_id = aws_subnet.private.id      # Associate the subnet for the instance
availability_zone = "us-east-1a"
vpc_security_group_ids = [aws_security_group.my_sg.id]
}
resource "aws_security_group" "my_sg" {
name        = "my_sg"
description = "Allow TLS inbound traffic and all outbound traffic"
vpc_id = aws_vpc.my_vpc.id

 ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "ssh"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH from any IP address
  }
   ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "http"
    cidr_blocks = ["0.0.0.0/0"]  # Allow http from any IP address
  }
   ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow tcp from any IP address
  }
   egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_ebs_volume" "my_volume" {
  availability_zone = "us-east-1a"
  size              = 20  # Size of the volume in gigabytes
  type              = "gp2"  # EBS volume type
}  
resource "aws_volume_attachment" "attach" {
  volume_id          = aws_volume.my_volume.id
  instance_id        = aws_instance.web.id
  device_name        = "/dev/sdf"  # Change this to the desired device name on the instance
}
