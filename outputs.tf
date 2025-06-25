output "rds_endpoint" {
  value = aws_db_instance.kaushal2118v3.endpoint
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.cart_kaushal2118v3.name
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}
