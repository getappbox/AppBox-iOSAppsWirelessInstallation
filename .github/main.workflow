workflow "Slack - New Issues" {
  resolves = ["Slack Notification for New Issues"]
  on = "issues"
}

action "Slack Notification for New Issues" {
  uses = "Ilshidur/action-slack@9273a03"
  secrets = ["SLACK_WEBHOOK"]
  args = "A new issue has been added. \\n\\nURL - {{ EVENT_PAYLOAD.issue.html_url }} \\n\\nTitle - {{ EVENT_PAYLOAD.issue.title }} \\n\\nBody - {{ EVENT_PAYLOAD.issue.body }}"
}

workflow "Slack - Issue Comment" {
  resolves = ["GitHub Action for Slack"]
  on = "issue_comment"
}

action "GitHub Action for Slack" {
  uses = "Ilshidur/action-slack@9273a03"
  secrets = ["SLACK_WEBHOOK"]
  args = "A new comment to an issue has been added. \\n\\nURL - {{ EVENT_PAYLOAD.comment.html_url }} \\n\\nBody - {{ EVENT_PAYLOAD.comment.body }} \\n\\nBy - {{ EVENT_PAYLOAD.comment.user.login }}"
}
