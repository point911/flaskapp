provider "google" {
  project     = "${var.gce_project}"
}


resource "google_compute_disk" "disk-app-1" {
  name  = "app-disk-1"
  type  = "pd-ssd"
  zone  = "${var.gce_region_1}-${var.gce_region_1_zone}"
  size  = 10
  labels {
    environment = "prod"
  }
}


resource "google_compute_disk" "disk-app-2" {
  name  = "app-disk-2"
  type  = "pd-ssd"
  zone  = "${var.gce_region_2}-${var.gce_region_2_zone}"
  size  = 10
  labels {
    environment = "prod"
  }
}


resource "google_compute_network" "vpc" {
 name                    = "${var.vpc_network_name}"
 auto_create_subnetworks = "false"
}


resource "google_compute_subnetwork" "appsubnet1" {
 name          = "${var.app1_subnet_name}-subnet"
 ip_cidr_range = "${var.app1_subnet_cidr}"
 network       = "${var.vpc_name}-vpc"
 depends_on    = ["google_compute_network.vpc"]
 region      = "${var.gce_region_1}"
}


resource "google_compute_subnetwork" "appsubnet2" {
 name          = "${var.app2_subnet_name}-subnet"
 ip_cidr_range = "${var.app2_subnet_cidr}"
 network       = "${var.vpc_name}-vpc"
 depends_on    = ["google_compute_network.vpc"]
 region      = "${var.gce_region_2}"
}


resource "google_compute_firewall" "firewall" {
  name    = "${var.vpc_name}-public-firewall"
  network = "${google_compute_network.vpc.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}


resource "google_compute_firewall" "internal" {
  name    = "${var.vpc_name}-internal-firewall"
  network = "${google_compute_network.vpc.name}"

  allow {
        protocol = "tcp"
        ports = ["1-65535"]
    }

  allow {
        protocol = "udp"
        ports = ["1-65535"]
  }

  source_tags = ["internal"]
  source_ranges = ["${var.internal_net}"]
}



resource "google_compute_instance_template" "template-1" {
  name        = "${var.instance_template_name}-1"
  description = "This template is used to create app server instances."
  region       = "${google_compute_subnetwork.appsubnet1.region}"

  tags = ["internal", "webapp"]

  labels = {
    environment = "prod"
  }

  instance_description = "description assigned to instances"
  machine_type         = "n1-standard-1"
  can_ip_forward       = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
  }

  // Create a new boot disk from an image
  disk {
    source_image = "${var.web_app_image}"
    auto_delete  = true
    boot         = true
  }

//   Use an existing disk resource
  disk {
    source      = "${google_compute_disk.disk-app-1.name}"
    auto_delete = false
    boot        = false
    mode = "READ_ONLY"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.appsubnet1.name}"
    access_config {
    }
  }
}


resource "google_compute_instance_template" "template-2" {
  name        = "${var.instance_template_name}-2"
  description = "This template is used to create app server instances."
  region       = "${google_compute_subnetwork.appsubnet2.region}"

  tags = ["internal", "webapp"]

  labels = {
    environment = "prod"
  }

  instance_description = "description assigned to instances"
  machine_type         = "n1-standard-1"
  can_ip_forward       = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
  }

  // Create a new boot disk from an image
  disk {
    source_image = "${var.web_app_image}"
    auto_delete  = true
    boot         = true
  }

//   Use an existing disk resource
  disk {
    source      = "${google_compute_disk.disk-app-2.name}"
    auto_delete = false
    boot        = false
    mode = "READ_ONLY"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.appsubnet2.name}"
    access_config {
    }
  }
}


resource "google_compute_instance_group_manager" "appserver-1" {
  name = "flask-app-igm-1"

  base_instance_name = "flask-app-1"
  instance_template  = "${google_compute_instance_template.template-1.self_link}"
  update_strategy    = "NONE"
  zone               = "${var.gce_region_1}-${var.gce_region_1_zone}"

  target_size  = 2
  wait_for_instances = true

  named_port {
    name = "customhttp"
    port = 8000
  }
}


resource "google_compute_instance_group_manager" "appserver-2" {
  name = "flask-app-igm-2"

  base_instance_name = "flask-app-2"
  instance_template  = "${google_compute_instance_template.template-2.self_link}"
  update_strategy    = "NONE"
  zone               = "${var.gce_region_2}-${var.gce_region_2_zone}"

  target_size  = 2
  wait_for_instances = true

  named_port {
    name = "customhttp"
    port = 8000
  }
}


resource "google_compute_autoscaler" "autoscaler-1" {
    name = "flask-app-autoscaler-1"
    zone = "${var.gce_region_1}-${var.gce_region_1_zone}"
    target = "${google_compute_instance_group_manager.appserver-1.self_link}"

    autoscaling_policy = {
        max_replicas = 3
        min_replicas = 2
        cooldown_period = 15
        cpu_utilization = {
            target = 0.7
        }
    }
}


resource "google_compute_autoscaler" "autoscaler-2" {
    name = "flask-app-autoscaler-2"
    zone = "${var.gce_region_2}-${var.gce_region_2_zone}"
    target = "${google_compute_instance_group_manager.appserver-2.self_link}"

    autoscaling_policy = {
        max_replicas = 3
        min_replicas = 2
        cooldown_period = 15
        cpu_utilization = {
            target = 0.7
        }
    }
}


module "gce-lb-http" "http_lb" {
  firewall_networks="${var.firewall_networks}"

  source      = "github.com/GoogleCloudPlatform/terraform-google-lb-http"
  name        = "group-http-lb"
  target_tags = ["webapp"]

  backends = {
    "0" = [
      {
        group = "${google_compute_instance_group_manager.appserver-1.instance_group}"
      },
      {
        group = "${google_compute_instance_group_manager.appserver-2.instance_group}"
      },
    ]
  }

  backend_params = [
    // health check path, port name, port number, timeout seconds.
    "/,customhttp,8000,10",
  ]
}