resource "aws_vpc" "recipe" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"
}

resource "aws_subnet" "public-sub-1" {
  vpc_id                  = aws_vpc.recipe.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-southeast-2a"
  map_public_ip_on_launch = var.map_public_ip_on_launch
}

resource "aws_subnet" "public-sub-2" {
  vpc_id                  = aws_vpc.recipe.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "ap-southeast-2b"
  map_public_ip_on_launch = var.map_public_ip_on_launch
}

resource "aws_subnet" "private-sub-1" {
  vpc_id            = aws_vpc.recipe.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-southeast-2a"
}

resource "aws_subnet" "private-sub-2" {
  vpc_id            = aws_vpc.recipe.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-southeast-2b"
}


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.recipe.id

  tags = {
    Name = "main"
  }
}

resource "aws_eip" "elas_ip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.elas_ip.id
  subnet_id     = aws_subnet.public-sub-1.id

  tags = {
    Name = "gw NAT"
  }
  depends_on = [aws_eip.elas_ip]
}


resource "aws_route_table" "pub_rte_tbl" {
  vpc_id = aws_vpc.recipe.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "route_table_1"
  }
}

resource "aws_route_table" "prv_rte_tbl" {
  vpc_id = aws_vpc.recipe.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "route_table_2"
  }
}

resource "aws_route_table_association" "route_table_associations" {
  for_each = {
    private_subnet_1 = {
      subnet_id      = aws_subnet.private-sub-1.id
      route_table_id = aws_route_table.prv_rte_tbl.id
    }
    private_subnet_2 = {
      subnet_id      = aws_subnet.private-sub-2.id
      route_table_id = aws_route_table.prv_rte_tbl.id
    }
    public_subnet_1 = {
      subnet_id      = aws_subnet.public-sub-1.id
      route_table_id = aws_route_table.pub_rte_tbl.id
    }
    public_subnet_2 = {
      subnet_id      = aws_subnet.public-sub-2.id
      route_table_id = aws_route_table.pub_rte_tbl.id
    }
  }

  subnet_id      = each.value.subnet_id
  route_table_id = each.value.route_table_id
} 

