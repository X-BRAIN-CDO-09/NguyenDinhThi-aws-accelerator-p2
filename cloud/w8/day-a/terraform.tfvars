env     = "staging"
project = "xbrain-aws-cohort2"

servers = {
  "web-01" = { role = "web", cpu = 2, ram = 4, active = true }
  "web-02" = { role = "web", cpu = 2, ram = 4, active = true }
  "db-01"  = { role = "db", cpu = 4, ram = 8, active = true }
  "db-02"  = { role = "db", cpu = 8, ram = 16, active = false } # Server db-02 inactive nên sẽ không bị tạo
  "cache"  = { role = "cache", cpu = 1, ram = 2, active = true }
}
