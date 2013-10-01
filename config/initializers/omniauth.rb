module OmniAuth
  module Strategies
   class Identity 
  
   	 # Override registration link 
   	 def registration_form
   	 	redirect '/signup'
   	 end

     # def request_phase
     #   redirect '/login'
     # end
   end
 end
end

# http://www.rubydoc.info/github/intridea/omniauth-identity/frames
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :identity, fields: [:email, :name], 
  	model: User, 
  	on_failed_registration: lambda { |env| UsersController.action(:new).call(env) },
  	form: lambda { |env| SessionsController.action(:new).call(env) } 
    # provider :twitter, 'CONSUMER_KEY', 'CONSUMER_SECRET'
    provider :facebook, ENV['KEY'], ENV['SECRET'],
             :scope => 'publish_actions,email'#, :display => 'popup' # Publish actions é para publicar em nome do user
             # :scope => 'email,read_stream'
    # provider :linked_in, 'CONSUMER_KEY', 'CONSUMER_SECRET'
    provider :google_oauth2, ENV['KEY'], ENV['SECRET']
end

OmniAuth.config.on_failure = Proc.new { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}