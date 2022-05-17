

resource "null_resource" "update_cdn" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["sh", "-c"]
    command     = "./update_cdn.sh ${var.cdn_id} ${var.lb_url} ${var.cdn_path}"
  }
}

