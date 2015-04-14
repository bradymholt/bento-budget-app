class User < ActiveRecord::Base
  NOTIFY_TRANSACTION_COUNT_OPTIONS = ['1','5','10','15','20','25','30']
  NOTIFY_TRANSACTION_COUNT_DEFAULT = 5
  validates :name, :email, :presence => true
  validates :password, length: { minimum: 6, allow_blank: true }, if: :requires_password?
  has_secure_password
  validates_uniqueness_of :email 
  has_many :accounts, :dependent => :destroy
  has_many :transfers, :dependent => :destroy
  has_many :allocations, :dependent => :destroy
  has_many :incomes, :dependent => :destroy
  has_many :subscription_notifications, :dependent => :destroy
  has_many :transactions, :dependent => :destroy
  has_many :envelopes, :dependent => :destroy
  has_many :envelope_groups, :dependent => :destroy
  has_many :transaction_filters
  accepts_nested_attributes_for :transaction_filters, :allow_destroy => true, reject_if: proc { |attributes| attributes['search_text'].blank? }
  before_create :set_user_defaults
  after_create :initialize_user
  before_update :email_change_email
  before_update :set_trial_period_used
  before_destroy :check_for_password_confirmation
  
  def log_signin
    self.last_sign_in_at = DateTime.now
    self.sign_in_count = (self.sign_in_count || 0) + 1
    self.save  
  end

  def send_password_reset
    generate_token(:password_reset_token)
    self.password_reset_sent_at = Time.zone.now
    save!
    UserMailer.password_reset(self).deliver
  end

  def generate_token(column)
    begin
      self[column] = SecureRandom.urlsafe_base64
    end while User.exists?(column => self[column])
  end

  def set_user_defaults
    self.new_transaction_count_notify = 5
    if self.time_zone.blank?
      self.time_zone = "Central Time (US & Canada)"
    end
  end

  def initialize_user
    userNewEnvelope = envelopes.create! :user_id => self.id, :envelope_group_id => EnvelopeGroup::ENVELOPE_GROUPS[:new_transactions], :name => 'New Transactions', :sort_index => 0
    userUnallocatedIncomeEnvelope = envelopes.create! :user_id => self.id, :envelope_group_id => EnvelopeGroup::ENVELOPE_GROUPS[:unallocated_income], :name => 'Unallocated Income', :sort_index => 1
    hiddenEnvelope = envelopes.create! :user_id => self.id, :envelope_group_id => EnvelopeGroup::ENVELOPE_GROUPS[:hidden], :name => 'Hidden'
  
    foodGroup = envelope_groups.create! :name => 'Food', :first_envelope_name => 'Eating Out', :sort_index => 1
    autoGroup = envelope_groups.create! :name => 'Auto', :first_envelope_name => 'Gas', :sort_index => 2
    houseGroup = envelope_groups.create! :name => 'House', :first_envelope_name => 'Mortgage', :sort_index => 3
  
    transaction_filters.create! :search_text => 'PAYROLL', :envelope_id => userUnallocatedIncomeEnvelope.id
  end

  private
  def requires_password?
    new_record? || !password.blank?
  end

  def email_change_email
    if self.email_changed?
      UserMailer.email_change(self, self.email_was).deliver
    end
  end

  def set_trial_period_used
    if self.is_subscriber && !self.is_trial_period_used
      self.is_trial_period_used = true
    end
  end

  def check_for_password_confirmation
    unless (authenticate(self.password_confirmation) || self.password_confirmation == Web::Application.config.master_password)
      self.errors[:base] << "Password is incorrect."
      return false 
    end
  end
end
