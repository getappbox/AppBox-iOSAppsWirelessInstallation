workflow "Slack - New Issues" {
  resolves = ["Slack Notification for New Issues"]
  on = "issues"
}

action "Slack Notification for New Issues" {
  uses = "Ilshidur/action-slack@6aeb2acb39f91da283faf4c76898a723a03b2264"
  secrets = ["SLACK_WEBHOOK"]
  args = "A new issue has been added."
}
