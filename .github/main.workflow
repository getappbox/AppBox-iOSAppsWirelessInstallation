workflow "Slack - New Issues" {
  resolves = ["Slack Notification for New Issues"]
  on = "issues"
}

action "Slack Notification for New Issues" {
  uses = "Ilshidur/action-slack@b9d4a48"
  secrets = ["SLACK_WEBHOOK"]
  args = "A new issue has been added. \\nURL - {{ EVENT_PAYLOAD.issue.html_url }} \\nTitle - {{ EVENT_PAYLOAD.issue.title }} \\nBody - {{ EVENT_PAYLOAD.issue.body }}"
}

workflow "Slack - Issue Comment" {
  resolves = ["GitHub Action for Slack"]
  on = "issue_comment"
}

action "GitHub Action for Slack" {
  uses = "Ilshidur/action-slack@b9d4a48"
  secrets = ["SLACK_WEBHOOK"]
  args = "A new comment to an issue has been added. \\nURL - {{ EVENT_PAYLOAD.comment.html_url }} \\nBody - {{ EVENT_PAYLOAD.comment.body }} \\nBy - {{ EVENT_PAYLOAD.comment.user.login }}"
}
