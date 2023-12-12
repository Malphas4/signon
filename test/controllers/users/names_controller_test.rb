require "test_helper"

class Users::NamesControllerTest < ActionController::TestCase
  context "GET edit" do
    context "signed in as Admin user" do
      setup do
        @superadmin = create(:superadmin_user)
        sign_in(@superadmin)
      end

      should "display breadcrumb links back to edit user page & users page for non-API user" do
        user = create(:user)

        get :edit, params: { user_id: user }

        assert_select ".govuk-breadcrumbs" do
          assert_select "a[href='#{users_path}']"
          assert_select "a[href='#{edit_user_path(user)}']"
        end
      end

      should "display breadcrumb links back to edit API user page & API users page for API user" do
        user = create(:api_user)

        get :edit, params: { user_id: user }

        assert_select ".govuk-breadcrumbs" do
          assert_select "a[href='#{api_users_path}']"
          assert_select "a[href='#{edit_api_user_path(user)}']"
        end
      end

      should "display form with name field" do
        user = create(:user, name: "user-name")

        get :edit, params: { user_id: user }

        assert_template :edit
        assert_select "form[action='#{user_name_path(user)}']" do
          assert_select "input[name='user[name]']", value: "user-name"
          assert_select "button[type='submit']", text: "Change name"
        end
      end

      should "display cancel link to edit user page for non-API user" do
        user = create(:user, name: "user-name")

        get :edit, params: { user_id: user }

        assert_select "form[action='#{user_name_path(user)}']" do
          assert_select "a[href='#{edit_user_path(user)}']", text: "Cancel"
        end
      end

      should "display cancel link to edit API user page for API user" do
        user = create(:api_user, name: "user-name")

        get :edit, params: { user_id: user }

        assert_select "form[action='#{user_name_path(user)}']" do
          assert_select "a[href='#{edit_api_user_path(user)}']", text: "Cancel"
        end
      end

      should "authorize access if UserPolicy#edit? returns true" do
        user = create(:user)

        user_policy = stub_everything("user-policy", edit?: true)
        UserPolicy.stubs(:new).returns(user_policy)

        get :edit, params: { user_id: user }

        assert_template :edit
      end

      should "not authorize access if UserPolicy#edit? returns false" do
        user = create(:user)

        user_policy = stub_everything("user-policy", edit?: false)
        UserPolicy.stubs(:new).returns(user_policy)

        get :edit, params: { user_id: user }

        assert_not_authorised
      end

      should "authorize access if ApiUserPolicy#edit? returns true when user is an API user" do
        user = create(:api_user)

        api_user_policy = stub_everything("api-user-policy", edit?: true)
        ApiUserPolicy.stubs(:new).returns(api_user_policy)

        get :edit, params: { user_id: user }

        assert_template :edit
      end

      should "not authorize access if ApiUserPolicy#edit? returns false when user is an API user" do
        user = create(:api_user)

        api_user_policy = stub_everything("api-user-policy", edit?: false)
        ApiUserPolicy.stubs(:new).returns(api_user_policy)

        get :edit, params: { user_id: user }

        assert_not_authorised
      end

      should "redirect to account page if admin is acting on their own user" do
        get :edit, params: { user_id: @superadmin }

        assert_redirected_to account_path
      end
    end

    context "signed in as Normal user" do
      setup do
        sign_in(create(:user))
      end

      should "not be authorized" do
        user = create(:user)

        get :edit, params: { user_id: user }

        assert_not_authorised
      end
    end

    context "not signed in" do
      should "not be allowed access" do
        user = create(:user)

        get :edit, params: { user_id: user }

        assert_not_authenticated
      end
    end
  end

  context "PUT update" do
    context "signed in as Admin user" do
      setup do
        @superadmin = create(:superadmin_user)
        sign_in(@superadmin)
      end

      should "update user name" do
        user = create(:user, name: "user-name")

        put :update, params: { user_id: user, user: { name: "new-user-name" } }

        assert_equal "new-user-name", user.reload.name
      end

      should "record account updated event" do
        user = create(:user)

        @controller.stubs(:user_ip_address).returns("1.1.1.1")

        EventLog.expects(:record_event).with(
          user,
          EventLog::ACCOUNT_UPDATED,
          initiator: @superadmin,
          ip_address: "1.1.1.1",
        )

        put :update, params: { user_id: user, user: { name: "new-user-name" } }
      end

      should "push changes out to apps" do
        user = create(:user)
        PermissionUpdater.expects(:perform_on).with(user).once

        put :update, params: { user_id: user, user: { name: "new-user-name" } }
      end

      should "redirect to user page and display success notice for non-API user" do
        user = create(:user, email: "user@gov.uk")

        put :update, params: { user_id: user, user: { name: "new-user-name" } }

        assert_redirected_to edit_user_path(user)
        assert_equal "Updated user user@gov.uk successfully", flash[:notice]
      end

      should "redirect to API user page and display success notice for API user" do
        user = create(:api_user, email: "user@gov.uk")

        put :update, params: { user_id: user, user: { name: "new-user-name" } }

        assert_redirected_to edit_api_user_path(user)
        assert_equal "Updated user user@gov.uk successfully", flash[:notice]
      end

      should "update user name if UserPolicy#update? returns true" do
        user = create(:user, name: "user-name")

        user_policy = stub_everything("user-policy", update?: true)
        UserPolicy.stubs(:new).returns(user_policy)

        put :update, params: { user_id: user, user: { name: "new-user-name" } }

        assert_equal "new-user-name", user.reload.name
      end

      should "not update user name if UserPolicy#update? returns false" do
        user = create(:user, name: "user-name")

        user_policy = stub_everything("user-policy", update?: false)
        UserPolicy.stubs(:new).returns(user_policy)

        put :update, params: { user_id: user, user: { name: "new-user-name" } }

        assert_equal "user-name", user.reload.name
        assert_not_authorised
      end

      should "update user name if ApiUserPolicy#update? returns true when user is an API user" do
        user = create(:api_user, name: "user-name")

        api_user_policy = stub_everything("api_user-policy", update?: true)
        ApiUserPolicy.stubs(:new).returns(api_user_policy)

        put :update, params: { user_id: user, user: { name: "new-user-name" } }

        assert_equal "new-user-name", user.reload.name
      end

      should "not update user name if ApiUserPolicy#update? returns false when user is an API user" do
        user = create(:api_user, name: "user-name")

        api_user_policy = stub_everything("api_user-policy", update?: false)
        ApiUserPolicy.stubs(:new).returns(api_user_policy)

        put :update, params: { user_id: user, user: { name: "new-user-name" } }

        assert_equal "user-name", user.reload.name
        assert_not_authorised
      end

      should "redisplay form if name is not valid" do
        user = create(:user, name: "user-name")

        put :update, params: { user_id: user, user: { name: "" } }

        assert_template :edit
        assert_select "form[action='#{user_name_path(user)}']" do
          assert_select "input[name='user[name]']", value: ""
        end
      end

      should "use original name in page title, heading & breadcrumbs if new name was not valid" do
        user = create(:user, name: "user-name")

        put :update, params: { user_id: user, user: { name: "" } }

        assert_select "head title", text: /^Change name for user-name/
        assert_select "h1", text: "Change name for user-name"
        assert_select ".govuk-breadcrumbs li", text: "user-name"
      end

      should "display errors if name is not valid" do
        user = create(:user)

        put :update, params: { user_id: user, user: { name: "" } }

        assert_select ".govuk-error-summary" do
          assert_select "a", href: "#user_name", text: "Name can't be blank"
        end
        assert_select ".govuk-form-group" do
          assert_select ".govuk-error-message", text: "Error: Name can't be blank"
          assert_select "input[name='user[name]'].govuk-input--error"
        end
      end
    end

    context "signed in as Normal user" do
      setup do
        sign_in(create(:user))
      end

      should "not be authorized" do
        user = create(:user, name: "user-name")

        put :update, params: { user_id: user, user: { name: "new-user-name" } }

        assert_not_authorised
      end
    end

    context "not signed in" do
      should "not be allowed access" do
        user = create(:user)

        put :update, params: { user_id: user }

        assert_not_authenticated
      end
    end
  end
end
