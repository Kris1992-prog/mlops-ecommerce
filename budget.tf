# ------------------------------------------------------------------------------
# Controllo e Alert dei Costi AWS (FinOps)
# ------------------------------------------------------------------------------
resource "aws_budgets_budget" "monthly_budget" {
  name              = "monthly-spend-limit"
  budget_type       = "COST"
  limit_amount      = "15" # Soglia mensile in USD
  limit_unit        = "USD"
  time_period_start = "2026-01-01_00:00"
  time_unit         = "MONTHLY"

  # Alert 1: Spesa Reale >= 80% ($12)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["cristiano.ragusa10@outlook.it"] # <-- Metti la tua email qui
  }

  # Alert 2: Previsione a fine mese >= 100% ($15)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = ["cristiano.ragusa10@outlook.it"] # <-- Metti la tua email qui
  }
}