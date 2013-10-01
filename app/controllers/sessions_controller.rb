class SessionsController < ApplicationController  
  skip_before_filter :verify_authenticity_token, only: :create
  before_filter :dont_relogin, only: :new
 
  def new
    # Stuff to display on the login-page.
  end
  
  respond_to :json, :html, :js
  # respond_to :json
  def create
    puts "PARAMS #{params}"
    auth = request.env['omniauth.auth']
    puts "AUTH RECEIVED #{auth}"
    # Find an authentication or create an authentication
    # find_by provider e uid.
    already_exists = false
    @authentication = Authentication.find_with_omniauth(auth)
    if @authentication.nil?
      puts "AUTHENTICATION NIL"
      # If no authentication was found, create a brand new one here
      @authentication = Authentication.create_with_omniauth(auth)
    else
      puts "AUTHENTICATION ALREADY EXISTS"
      already_exists = true
    end
 
    if signed_in?
      puts "SIGNED IN"
      if @authentication.user == current_user
        puts "AUTHENTICATION USER == CURRENT USER"
        # User is signed in so they are trying to link an authentication with their
        # account. But we found the authentication and the user associated with it 
        # is the current user. So the authentication is already associated with 
        # this user. So let's display an error message.
        flash[:notive] = "You have already linked this account"

        # redirect_to root_path #alterei
        respond_to do |format|
          format.html { redirect_to root_path }
          format.json { render json: current_user }
        end
      else
        puts "AUTHENTICATION USER NOT == CURRENT USER"
        #SE REGISTAR COM IDENTITY E ESTOU LOGADO JUNTA AQUI... 
        # The authentication is not associated with the current_user so lets 
        # associate the authentication
        # Neste momento uma segunda identity registration acaba aqui... n sei é onde criou o user.
        # Está a ser criado dentro do omniauth
        # Este cenário, ainda pode ser melhorado aqui, 
        # mas é para quando está logado com outro provider e realiza registo com identity
        # confirma depois de o login ser bem efectuado aquando login fb

        if !already_exists
          @authentication.user = current_user
          if auth['provider']=='identity'
            current_user.has_identity = true
            puts "METI O HAS IDENTITY A TRUE"
          end
          @authentication.save
          flash[:notive] = "Account successfully authenticated"
        else
          flash[:notive] = "Account already associated with another user"
        end
        respond_to do |format|
          #redirect back ás vezes é um problema, para protected post actions, depois tenta get
          #tou na ideia k já tinha tratado disto algures para paypal, vê o simplestarter
          format.html { redirect_to root_path } 

          format.json { render json: @authentication.user }
        end
      end
    else # no user is signed_in
      puts "NO USER IS SIGNED IN"
      if @authentication.user.present?
        puts "THE AUTHENTICATION WE FOUND HAD A USER ASSOCIATED WITH IT"
        # The authentication we found had a user associated with it so let's 
        # just log them in here
        sign_in(@authentication.user)
        puts "ITS signed in?: #{signed_in?}"
        flash[:notive] = "Signed in!"
        # redirect_to root_path #alterei

        # response.headers['CONTENT_TYPE'] = 'application/json'
        
        respond_to do |format|
          # puts "FORMAT #{format.inspect}"
          format.js { render js: "<script> JSON.stringify(#{@authentication.user}) </script>" }
          format.html { redirect_to root_path }
          format.json { 
            user = @authentication.user
            token = user.generate_auth_token
            render :json => {
              :success => true, 
              :user=> user,
              :auth_token => token 
            }
          }#'{"user":"#{@authentication.user.name}"}' }#@authentication.user }
          # format.json { render json: @authentication.user }
        end
      else
        puts "THE AUTHENTICATION HAS NO USER ASSOCIATED WITH IT"
        # O login facebook n resulta no login efectivo porque esta associação ainda n existe.

        # The authentication has no user assigned and there is no user signed in
        # Our decision here is to create a new account for the user
        # But your app may do something different (eg. ask the user
        # if he already signed up with some other service)
        if @authentication.provider == 'identity'
          puts "O PROVIDER E IDENTITY"
          u = User.find(@authentication.uid)
          puts "USER FOUND: #{u.inspect}"
          # If the provider is identity, then it means we already created a user
          # So we just load it up
          # Isto acontece pk se é provider o omniauth cria um user automaticamente
          # é aqui que devo alterar o boolean assim.
          # Este é o cenário em que n existe nimguém logado.
          u.has_identity = true
          u.save!
          puts "METI O HAS IDENTITY A TRUE"
        else
          puts "PROVIDER N E IDENTITY. CRIAR USER COM AUTH HASH\n #{auth}"
          # otherwise we have to create a user with the auth hash
          u = User.create_with_omniauth(auth)
          # Eu conseguiria levar os dados daqui para outra janela onde conclui a inscrição?
          # NOTE: we will handle the different types of data we get back
          # from providers at the model level in create_with_omniauth
        end
        # We can now link the authentication with the user and log him in
        puts "VAI JUNTAR A AUTHENTICATION AO USER"
        u.authentications << @authentication
        sign_in(u)
        if signed_in?
          puts "SIGNED IN"
        else
          puts "NOT SIGNED IN"
        end
        flash[:notive] = "Welcome to The app!"
        # case auth['provider']
        # when 'facebook'
        #   token = u.generate_token_inner(:password_reset_token)
        #   puts "TOKEN #{token}"
        #   redirect_to edit_password_reset_url(token)
        # when 'google_oauth2'
        #   token = u.generate_token_inner(:password_reset_token)
        #   puts "TOKEN #{token}"
        #   redirect_to edit_password_reset_url(token)
        # else
        #   redirect_to root_path
        # end
        # redirect_to root_path #alterei
        respond_to do |format|
          format.html { redirect_to root_path }
          format.json { render json: true }
        end
        # Se for outro provider que n identity tenho de gerar password e redirect
      end
    end
  end
  

  def destroy
    sign_out
    flash[:notive] = "Signed out!"
    respond_to do |format|
          format.html { redirect_to root_path }
          format.json { render json: true }
    end
  end
  
  def failure
    flash[:alert] = "Authentication failed, please try again."   
    puts "IDENTITY LOGIN FAILURE"
    # redirect_to root_path
    respond_to do |format|
      format.html { redirect_to root_path }
      format.json { render json: false }
    end
  end


  def dont_relogin
   redirect_to root_path unless !signed_in?
  end


end