require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get home_index_url
    assert_response :success
  end

  test "should get upload_csv" do
    get home_upload_csv_url
    assert_response :success
  end
end
