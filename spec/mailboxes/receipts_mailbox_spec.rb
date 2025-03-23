require 'rails_helper'

RSpec.describe ReceiptsMailbox, type: :mailbox do
  describe '#process' do
    it 'logs receipt of email' do
      # Create a test mail object
      mail = Mail.new(
        from: 'sender@example.com',
        to: 'receipts@example.com',
        subject: 'Test Receipt',
        body: 'Test receipt content'
      )

      # Create a mock inbound email
      mock_inbound_email = double('inbound_email')
      allow(mock_inbound_email).to receive(:mail).and_return(mail)

      # Create the mailbox instance with the mock inbound email
      mailbox = ReceiptsMailbox.new(mock_inbound_email)

      # Expect logger to be called with the correct message
      expect(Rails.logger).to receive(:info).with("Received receipt email from: [\"sender@example.com\"]")

      # Run the process method
      mailbox.process
    end
  end
end
