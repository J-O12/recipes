# resource "aws_dynamodb_table" "RecipesTable" {
#   name         = var.RecipesTableName
#   billing_mode = "PAY_PER_REQUEST"

#   attribute {
#     name = "id"
#     type = "S"
#   }

#   hash_key = "id"
# }

# output "RecipesTableName" {
#   value = aws_dynamodb_table.RecipesTable.name
# }
