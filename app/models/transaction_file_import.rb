require 'csv'

class TransactionFileImport
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :account_id, :user_id, :transaction_file, :transactions, :date_start

  validates_presence_of :account_id, :transaction_file
  validate :validate_transaction_file
  
  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end
  
  def persisted?
    false
  end

  def import
    acct = Account.find(account_id)
    accepted_transaction_count = acct.import_transactions(self.transactions, self.date_start)
  end

  private 
  def validate_transaction_file
    if !transaction_file.nil? 
      self.transactions = []

      begin
        if ['.qif'].include?(File.extname(transaction_file.original_filename.downcase))
          qif = Qif::Reader.new(transaction_file.read)
          self.date_start = DateTime.now - 6.months #qif has no date so we'll look back 6 months
          qif.each do |t|
            self.transactions << {:id => SecureRandom.uuid, :date => t.date, :name => t.payee, :amount => t.amount}
          end
        elsif ['.ofx', '.qfx'].include?(File.extname(transaction_file.original_filename.downcase))
          ofx = OfxParser::OfxParser.parse(transaction_file.read)
          source = ofx.bank_account
          if source.nil?
            source = ofx.credit_card
          end
           
          if !source.nil? && !source.statement.nil?
             self.date_start = source.statement.start_date
             source.statement.transactions.each do |t|
                self.transactions << {:id => t.fit_id, :date => t.date, :name => t.payee, :amount => t.amount}
              end
           end
        elsif ['.csv'].include?(File.extname(transaction_file.original_filename.downcase))
          begin
            rowNumber = 0
            CSV.parse(transaction_file.read) do |row|
              rowNumber = rowNumber + 1
              date = Date.strptime(row[0], "%m/%d/%Y") rescue nil
              
              if (date.nil?)
                 if rowNumber==1
                    #probably a header row, go to next row
                    next
                 else
                    raise Exception, "Date could not be parsed! (Row: #{rowNumber}, Column: 1, Value: #{row[0]})"
                 end
              end

              description = row[1]
              
              amountText = row[2].gsub(/[^0-9.-]/,"")
              if amountText == ""
                raise Exception, "Amount could not be parsed! (Row: #{rowNumber}, Column: 3, Value: #{row[2]})"
              end

              amount = amountText.to_f
                           
              if (amount != 0)
                self.transactions << {:id => SecureRandom.uuid, :date => date, :name => description, :amount => amount}
              end
            end
          rescue Exception => e
            Rails.logger.info e.message
            errors.add(:transaction_file, "is invalid.  CSV files must have 3 columns in this order: [Date, Description, Amount].  The Date should be in the format mm/dd/yyyy and a header row is optional.")
          end    
        else  
          errors.add(:transaction_file, "type is not supported.")
        end
      rescue Exception => e
        Rails.logger.info e.message
        errors.add(:transaction_file, "is invalid.")
      end
    end
  end
end