require "test_helper"
require "support/policy_helpers"

class Account::PasswordsPolicyTest < ActiveSupport::TestCase
  include PolicyHelpers

  should "allow logged in users to see edit irrespective of their role" do
    assert permit?(build(:user), nil, :edit)
  end

  should "not allow anonymous visitors to see edit" do
    assert forbid?(nil, nil, :edit)
  end
end
