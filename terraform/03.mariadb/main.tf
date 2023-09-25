provider "google" {
  #credentials = file("<path-to-your-service-account-key.json>")
  project     = "solutionsarchitect-01"
  region      = "europe-west2"
}

resource "google_compute_instance" "mariadb_instance" {
  name         = "dfederico-mariadb-instance"
  machine_type = "n1-standard-2"
  zone         = "europe-west2-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = 200
    }
  }

  network_interface {
    network = "dfederico-vpc"
    subnetwork = "primary-subnet"
    access_config {}
  }

  tags = ["dfederico-mariadb"]

  metadata = {
    ssh-keys = "dfederico:${file("id_rsa.pub")}"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install -y mariadb-server

    # Enable Binary Logging
    sudo tee -a /etc/mysql/mariadb.conf.d/50-server.cnf <<EOF_MYSQL_CONFIG
    [mysqld]
    server-id=1
    log-bin=/var/log/mysql/mariadb-bin.log
    binlog_format=ROW
    skip-networking=0
    skip-bind-address
    EOF_MYSQL_CONFIG

    sudo service mysql restart
    EOF
}

resource "google_compute_firewall" "mariadb_firewall" {
  name          = "dfederico-mariadb-public"
  description   = "Allow traffic to MariaDB instance"
  network       = "dfederico-vpc"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["dfederico-mariadb"]

  allow {
    protocol = "all"
  }
}