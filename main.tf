terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.23.1"
    }
  }
}

provider "docker" {
  host = "npipe:////.//pipe//docker_engine"
  #host = "unix:///var/run/docker.sock" # Docker on ubuntu connection
}

# PostgreSQL Database
resource "docker_image" "postgres" {
  name = "postgres:15"
}

resource "docker_container" "database" {
  name  = "lingo-db"
  image = docker_image.postgres.image_id
  
  env = [
    "POSTGRES_USER=lingoapp",
    "POSTGRES_PASSWORD=password123",
    "POSTGRES_DB=lingodb"
  ]
  
  ports {
    internal = 5432
    external = 5432
  }
  
  volumes {
    container_path = "/var/lib/postgresql/data"
    volume_name    = docker_volume.db_data.name
  }
  
  networks_advanced {
    name = docker_network.lingo_network.name
  }
}

# Backend Node.js
resource "docker_image" "node" {
  name = "node:18-alpine"
}

resource "docker_container" "backend" {
  name  = "lingo-backend"
  image = docker_image.node.image_id
  
  ports {
    internal = 4000
    external = 4000
  }
  
  volumes {
    container_path = "/app"
    host_path      = "${path.cwd}/backend"
  }
  
  working_dir = "/app"
  
  command = [
    "npm",
    "run",
    "dev"
  ]
  
  networks_advanced {
    name = docker_network.lingo_network.name
  }
}

# Frontend React
resource "docker_container" "frontend" {
  name  = "lingo-frontend"
  image = docker_image.node.image_id
  
  ports {
    internal = 3000
    external = 3000
  }
  
  volumes {
    container_path = "/app"
    host_path      = "${path.cwd}/frontend"
  }
  
  working_dir = "/app"
  
  command = [
    "npm",
    "start"
  ]
  
  networks_advanced {
    name = docker_network.lingo_network.name
  }
}

# Persistent volume for database
resource "docker_volume" "db_data" {
  name = "lingo_db_data"
}

# Network for container communication
resource "docker_network" "lingo_network" {
  name = "lingo_network"
  driver = "bridge"
}

# Nginx
resource "docker_image" "nginx" {
  name = "nginx:latest"
}

resource "docker_container" "nginx" {
  name  = "lingo-nginx"
  image = docker_image.nginx.image_id
  
  ports {
    internal = 80
    external = 80
  }
  
  networks_advanced {
    name = docker_network.lingo_network.name
  }
}