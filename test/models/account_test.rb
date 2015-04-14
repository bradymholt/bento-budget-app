require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  test "should save" do
  	account = Account.new
  	account.user_id = 1
    assert account.save
  end
end
