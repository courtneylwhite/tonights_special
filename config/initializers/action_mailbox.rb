Rails.application.configure do
  if Rails.env.test?
    config.action_mailbox.ingress_password = "test_password"
  else
    config.action_mailbox.ingress_password = ENV.fetch("RAILS_INBOUND_EMAIL_PASSWORD")
  end
end
