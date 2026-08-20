class SymbolImportJob < ApplicationJob
  queue_as :default

  def perform
    result = SymbolImporter.run
    Rails.logger.info("SymbolImportJob: #{result.inspect}")
  end
end
