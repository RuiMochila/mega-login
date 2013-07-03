class UsersController < ApplicationController
  before_filter :cant_identity, only: :new

  def new
    @user = env['omniauth.identity'] ||= User.new
  end

  def index
  	@users = User.all
  end

  def cant_identity
    if signed_in?
      puts "CANT IDENTITY"
      redirect_to root_url 
    end
  end

end