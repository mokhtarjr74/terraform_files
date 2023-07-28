resource "aws_vpc" "my_vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    tags = {
        Name = "my_vpc"
    }
}
resource "aws_subnet" "public_subnet1" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "eu-central-1a"
    map_public_ip_on_launch = true
    tags = {
        Name = "public_subnet1"
    }
}
resource "aws_subnet" "public_subnet2" {
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "eu-central-1b"
    map_public_ip_on_launch = true
    tags = {
        Name = "public_subnet2"
    }
}
resource "aws_internet_gateway" "my_igw" {
    vpc_id = aws_vpc.my_vpc.id
    tags = {
        Name = "my_igw"
    }
}

resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.my_vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my_igw.id
    }
    tags = {
        Name = "public_route_table"
    }
}
resource "aws_route_table_association" "public_subnet1_association" {
    subnet_id = aws_subnet.public_subnet1.id
    route_table_id = aws_route_table.public_route_table.id
}
  
resource "aws_route_table_association" "public_subnet2_association" {
    subnet_id = aws_subnet.public_subnet2.id
    route_table_id = aws_route_table.public_route_table.id
}

resource "aws_iam_role" "eks_role" {
    name = "eks_role"
    assume_role_policy = <<POLICY
    {
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Principal": {
                "Service": "eks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
            }
        ]
    }
    POLICY
}
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
    role = aws_iam_role.eks_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
    role = aws_iam_role.eks_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_eks_cluster" "my_cluster" {
    name = "my_cluster"
    role_arn = aws_iam_role.eks_role.arn
    vpc_config {
        endpoint_private_access = true
        subnet_ids = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]
    }
    tags = {
        Name = "my_cluster"
    }
    depends_on = [
        aws_iam_role_policy_attachment.eks_cluster_policy,
     aws_iam_role_policy_attachment.eks_service_policy,
     aws_subnet.public_subnet1,
     aws_subnet.public_subnet2 ]
}

resource "aws_iam_role""node_role" {
    name = "node_role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Principal = {
                    Service = "ec2.amazonaws.com"
                }
                Action = "sts:AssumeRole"
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "node_policy" {
    role = aws_iam_role.node_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
    role = aws_iam_role.node_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ec2_policy" {
    role = aws_iam_role.node_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "tls_private_key" "key" {
    algorithm = "RSA"
}

resource "local_file" "private_key" {
    depends_on = [ tls_private_key.key ]
    content = tls_private_key.key.private_key_pem
    filename = "eks-key.pem"
}

resource "aws_key_pair" "key1" {
    depends_on = [ local_file.private_key ]
    key_name = "eks-key"
    public_key = tls_private_key.key.public_key_openssh
}

resource "aws_eks_node_group" "my_cluster_node_group" {
    cluster_name = aws_eks_cluster.my_cluster.name
    node_group_name = "my_cluster_node_group"
    node_role_arn = aws_iam_role.node_role.arn
    subnet_ids = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]
    instance_types = ["t2.micro"]
    scaling_config {
        desired_size = 2
        max_size = 2
        min_size = 1
    }
    depends_on = [ 
        aws_eks_cluster.my_cluster,
        aws_iam_role_policy_attachment.node_policy,
        aws_iam_role_policy_attachment.cni_policy,
        aws_iam_role_policy_attachment.ec2_policy,
        aws_key_pair.key1,
         ]
}

resource "null_resource" "local_exec" {
    depends_on = [ aws_eks_node_group.my_cluster_node_group, ]
    provisioner "local-exec" {
        command = "aws eks update-kubeconfig --name ${aws_eks_cluster.my_cluster.name} --region eu-central-1"
    }
}

output "cluster_name" {
    value = aws_eks_cluster.my_cluster.name
}

output "id_vpc" {
    value = aws_vpc.my_vpc.id
}

output "node_group_name" {
    value = aws_eks_node_group.my_cluster_node_group.node_group_name
}
output "id_sg" {
  value = aws_eks_cluster.my_cluster.vpc_config[0].cluster_security_group_id
}

# get subnets id from aws_subnet
output "subnets_id" {
  value = aws_subnet.public_subnet1.id
}

output "subnets_id2" {
  value = aws_subnet.public_subnet2.id
}