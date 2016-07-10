# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :admin_group do
    sequence(:name) { |n| "Example#{n}" }
    api_scopes { [ApiScope.find_or_create_by_instance!(FactoryGirl.build(:api_scope))] }
    permission_ids [
      "analytics",
      "user_view",
      "user_manage",
      "admin_manage",
      "backend_manage",
      "backend_publish",
    ]

    trait :analytics_permission do
      permission_ids ["analytics"]
    end

    trait :user_view_permission do
      permission_ids ["user_view"]
    end

    trait :user_manage_permission do
      permission_ids ["user_manage"]
    end

    trait :admin_manage_permission do
      permission_ids ["admin_manage"]
    end

    trait :backend_manage_permission do
      permission_ids ["backend_manage"]
    end

    trait :backend_publish_permission do
      permission_ids ["backend_publish"]
    end

    factory :localhost_root_admin_group do
      api_scopes { [ApiScope.find_or_create_by_instance!(FactoryGirl.build(:localhost_root_api_scope))] }
    end

    factory :google_admin_group do
      api_scopes { [ApiScope.find_or_create_by_instance!(FactoryGirl.build(:google_api_scope))] }
    end

    factory :yahoo_admin_group do
      api_scopes { [ApiScope.find_or_create_by_instance!(FactoryGirl.build(:yahoo_api_scope))] }
    end

    factory :google_and_yahoo_multi_scope_admin_group do
      api_scopes do
        [
          ApiScope.find_or_create_by_instance!(FactoryGirl.build(:google_api_scope)),
          ApiScope.find_or_create_by_instance!(FactoryGirl.build(:yahoo_api_scope)),
        ]
      end
    end

    factory :bing_admin_group_single_all_scope do
      api_scopes { [ApiScope.find_or_create_by_instance!(FactoryGirl.build(:bing_all_api_scope))] }
    end

    factory :bing_admin_group_single_restricted_scope do
      api_scopes { [ApiScope.find_or_create_by_instance!(FactoryGirl.build(:bing_search_api_scope))] }
    end

    factory :bing_admin_group_multi_scope do
      api_scopes do
        [
          ApiScope.find_or_create_by_instance!(FactoryGirl.build(:bing_search_api_scope)),
          ApiScope.find_or_create_by_instance!(FactoryGirl.build(:bing_images_api_scope)),
          ApiScope.find_or_create_by_instance!(FactoryGirl.build(:bing_maps_api_scope)),
        ]
      end
    end
  end
end
