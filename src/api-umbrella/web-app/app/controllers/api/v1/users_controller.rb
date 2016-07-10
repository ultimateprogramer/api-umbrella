class Api::V1::UsersController < Api::V1::BaseController
  respond_to :json

  skip_before_filter :authenticate_admin!, :only => [:create]
  before_filter :authenicate_creator_api_key_role, :only => [:create]
  skip_after_filter :verify_authorized, :only => [:index, :create]
  before_filter :parse_post_for_pseudo_ie_cors, :only => [:create]

  def index
    @api_users = policy_scope(ApiUser).order_by(datatables_sort_array)

    if(params[:start].present?)
      @api_users = @api_users.skip(params["start"].to_i)
    end

    if(params[:length].present?)
      @api_users = @api_users.limit(params["length"].to_i)
    end

    if(params["search"] && params["search"]["value"].present?)
      @api_users = @api_users.or([
        { :first_name => /#{Regexp.escape(params["search"]["value"])}/i },
        { :last_name => /#{Regexp.escape(params["search"]["value"])}/i },
        { :email => /#{Regexp.escape(params["search"]["value"])}/i },
        { :api_key => /#{Regexp.escape(params["search"]["value"])}/i },
        { :registration_source => /#{Regexp.escape(params["search"]["value"])}/i },
        { :roles => /#{Regexp.escape(params["search"]["value"])}/i },
        { :_id => /#{Regexp.escape(params["search"]["value"])}/i },
      ])
    end
  end

  def show
    @api_user = ApiUser.find(params[:id])
    authorize(@api_user)
  end

  def create
    # Wildcard CORS header to allow the signup form to be embedded anywhere.
    headers["Access-Control-Allow-Origin"] = "*"

    @api_user = ApiUser.new
    assign_attributes!

    @api_user.registration_ip = request.ip
    @api_user.registration_user_agent = request.user_agent
    @api_user.registration_referer = request.referer
    @api_user.registration_origin = request.env["HTTP_ORIGIN"]

    respond_to do |format|
      if(@api_user.save)
        send_welcome_email = (params[:options] && params[:options][:send_welcome_email].to_s == "true")
        send_notify_email = (params[:options] && params[:options][:send_notify_email].to_s == "true")

        # For the admin tool, it's easier to have this attribute on the user
        # model, rather than options, so check there for whether we should send
        # e-mail. Also note that for backwards compatibility, we only check for
        # the presence of this attribute, and not it's actual value.
        if(!send_welcome_email && params[:user] && params[:user][:send_welcome_email])
          send_welcome_email = true
        end

        if(!send_notify_email && ApiUmbrellaConfig[:web][:send_notify_email].to_s == "true")
          send_notify_email = true
        end

        if(send_welcome_email)
          ApiUserMailer.delay(:queue => "mailers").signup_email(@api_user, params[:options] || {})
        end
        if(send_notify_email)
          ApiUserMailer.delay(:queue => "mailers").notify_api_admin(@api_user)
        end

        format.json { render("show", :status => :created, :location => api_v1_user_url(@api_user)) }
      else
        format.json { render(:json => errors_response(@api_user), :status => :unprocessable_entity) }
      end
    end
  end

  def update
    @api_user = ApiUser.find(params[:id])
    assign_attributes!

    respond_to do |format|
      if(@api_user.save)
        format.json { render("show", :status => :ok, :location => api_v1_user_url(@api_user)) }
      else
        format.json { render(:json => errors_response(@api_user), :status => :unprocessable_entity) }
      end
    end
  end

  private

  def assign_attributes!
    authorize(@api_user) unless(@api_user.new_record?)

    assign_options = {}
    if(admin_signed_in?)
      assign_options[:as] = :admin
    end

    @api_user.assign_nested_attributes(params[:user], assign_options)

    @verify_email = (params[:options] && params[:options][:verify_email].to_s == "true")
    if(@verify_email || admin_signed_in?)
      @api_user.email_verified = true
    else
      @api_user.email_verified = false
    end

    if(@api_user.new_record? && @api_user.registration_source.blank?)
      @api_user.registration_source = "api"
    end

    authorize(@api_user)
  end

  # To create users, don't require an admin user, so the signup form can be
  # embedded on other sites. Instead, allow API keys with a
  # "api-umbrella-key-creator" role to also create users.
  #
  # This assumes API Umbrella is sitting in front and controlling access to
  # this API with roles and other mechanisms (such as referer checking) to
  # control signup access.
  def authenicate_creator_api_key_role
    unless(admin_signed_in?)
      api_key_roles = request.headers['X-Api-Roles'].to_s.split(",")
      unless(api_key_roles.include?("api-umbrella-key-creator"))
        render(:json => { :error => "You need to sign in or sign up before continuing." }, :status => :unauthorized)
        return false
      end
    end
  end
end
