locals {
  common_tags = merge(
    { Project = var.name },
    var.tags
  )
}
# DB Subnet Group (isolated subnets)
# RDS needs a subnet group.
# We use isolated subnets so DB has no internet route.
resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnet-group"
  subnet_ids = var.isolated_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.name}-db-subnet-group"
    Tier = "db"
  })
}
# RDS Instance
# publicly_accessible = false keeps it private.
# vpc_security_group_ids ensures only your App SG can connect (via sg rules).
resource "aws_db_instance" "this" {
  identifier = "${var.name}-db"

  engine         = var.engine
  engine_version = var.engine_version != "" ? var.engine_version : null

  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage

  db_name  = var.db_name
  username = var.username
  password = var.db_password
  port     = var.port

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.db_security_group_id]

  multi_az            = var.multi_az
  publicly_accessible = var.publicly_accessible

  storage_encrypted        = var.storage_encrypted
  backup_retention_period  = var.backup_retention_period
  deletion_protection      = var.deletion_protection
  skip_final_snapshot      = var.skip_final_snapshot

  # minor upgrades can be enabled
  auto_minor_version_upgrade = true
  apply_immediately          = true

  tags = merge(local.common_tags, {
    Name = "${var.name}-db"
    Tier = "db"
  })
}



