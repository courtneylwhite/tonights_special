class ReceiptsMailbox < ApplicationMailbox
  def process
    Rails.logger.info "Received receipt email from: #{mail.from}"
  end
end
