resource "aws_wafv2_web_acl" "main" {
  name = "${var.name_prefix}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name = "AWSCommonRules"
    priority = 1

    override_action {
      none{}
    }

    statement {
      managed_rule_group_statement {
        name = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name = "${var.name_prefix}-common-rules"
      sampled_requests_enabled = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name = "${var.name_prefix}-waf"
    sampled_requests_enabled = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-waf"
  })
}