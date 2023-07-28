resource "aws_ecr_repository" "ecr_repo" {

  name = "ecr_repo"
  tags = {
    Name = "my_ecr"
  }
}

resource "aws_ecr_repository_policy" "my_ecr_policy" {
  repository = aws_ecr_repository.ecr_repo.name
  policy     = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "AllowPull",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ]
    }
  ]
}
EOF
}

output "ecr_url" {
  value = aws_ecr_repository.ecr_repo.repository_url
}

output "ecr_name" {
  value = aws_ecr_repository.ecr_repo.name
}