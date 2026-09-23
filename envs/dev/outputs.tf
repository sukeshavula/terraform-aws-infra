output "website_url" {
  value = "http://${module.web.alb_dns_name}"
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
