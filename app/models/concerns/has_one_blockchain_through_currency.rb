# encoding: UTF-8
# frozen_string_literal: true

module HasOneBlockchainThroughCurrency
  extend ActiveSupport::Concern

  included do
    has_one :blockchain, through: :currency
  end

  def transaction_url
    if txid? && blockchain.explorer_transaction.present?
      blockchain.explorer_transaction.gsub('#{txid}', txid)
    end
  end

  def wallet_url
    if blockchain.explorer_address.present?
      blockchain.explorer_address.gsub('#{address}', rid)
    end
  end

  def latest_block_number
    blockchain.blockchain_api.fetch_current_height
  end

  def confirmations(height: blockchain.processed_height)
    if block_number.blank?
      0
    elsif height - block_number >= 0
      height - block_number
    else
      'N/A'
    end
  rescue StandardError => e
    report_exception(e)
    'N/A'
  end
end
