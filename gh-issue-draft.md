# Move deployment notifications from Google Chat to MS Teams

## What

Deployment notifications (build status, deploy success/failure) currently post to Google Chat. Now that the team has moved to MS Teams as the primary chat surface, these notifications should go to MS Teams instead.

- [ ] Update CI/CD pipeline (Buildkite) to send deployment notifications to the Gumroad MS Teams General channel instead of Google Chat
- [ ] Remove the Google Chat webhook/integration once Teams notifications are confirmed working
- [ ] Verify notifications work for both successful and failed deployments

## Why

Google Chat has been deprecated as the team's chat platform in favor of MS Teams (as of March 2026). Deployment notifications going to a channel nobody monitors means failed deploys could go unnoticed.
