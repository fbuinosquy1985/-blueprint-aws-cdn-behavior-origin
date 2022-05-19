

resource "null_resource" "update_cdn" {
  
  triggers {
    cdn_id = var.cdn_id
	lb_url = var.lb_url
	cdn_path = var.cdn_path
  }  

  provisioner "local-exec" {
    interpreter = ["sh", "-c"]
    command     = "./update_cdn.sh ${var.cdn_id} ${var.lb_url} ${var.cdn_path}"
  }

  provisioner "local-exec" {
    when        = "destroy"
    interpreter = ["sh", "-c"]
    command     = "./remove_cdn.sh ${self.triggers.cdn_id} ${self.triggers.cdn_path}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

