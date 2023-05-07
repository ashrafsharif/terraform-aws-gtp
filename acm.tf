######################
# Certificate Manager
######################

# Generate a private key
resource "tls_private_key" "gtp-prod-app" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Generate a self-signed cert
resource "tls_self_signed_cert" "gtp-prod-app" {
  private_key_pem = tls_private_key.gtp-prod-app.private_key_pem

  subject {
    common_name  = "GTP"
    organization = "ACE Group"
    country      = "MY"
  }

  dns_names = ["gtp-prod.dataspeed.my", "gtp2.dataspeed.my"]

  validity_period_hours = 48

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# import into ACM
resource "aws_acm_certificate" "gtp_prod_app_cert" {
  private_key      = tls_private_key.gtp-prod-app.private_key_pem
  certificate_body = tls_self_signed_cert.gtp-prod-app.cert_pem
}
