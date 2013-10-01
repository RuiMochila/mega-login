# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  name                   :string(255)
#  email                  :string(255)
#  password_digest        :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  password_reset_token   :string(255)
#  password_reset_sent_at :datetime
#  remember_token         :string(255)
#  has_identity           :boolean
#

 
class User < OmniAuth::Identity::Models::ActiveRecord
  attr_accessible :email, :name, :password, :password_confirmation, :has_identity
 
  has_many :authentications, dependent: :destroy
  
  email_regex = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
 
  validates :email, :presence   => true,
            :format     => { :with => email_regex },
            :uniqueness => { :case_sensitive => false }

  before_save { email.downcase! }
  before_save :create_remember_token
  
  def self.create_with_omniauth(auth)
    # you should handle here different providers data
    # eg. case auth['provider'] ..
    case auth['provider']
    when 'facebook'
    	puts "ESTA AQUI O QUE DEVOLVE #{auth['info']['name']}"
    	pass = rand(36**10).to_s(36)
    	create(name: auth['info']['name'], email: auth['info']['email'], password: pass, password_confirmation: pass)
    when 'google_oauth2'
      puts "ESTA AQUI O QUE DEVOLVE #{auth['info']}"
      pass = rand(36**10).to_s(36)
      create(name: auth['info']['name'], email: auth['info']['email'], password: pass, password_confirmation: pass)  
    when 'identity'
    	puts "CHEGOU AO IDENTITY"
    	#N é por aqui que ele cria quando é identity, n chega aqui nunca.
    else
      uts "CHEGOU AO default"
    	'default'
    end
    # IMPORTANT: when you're creating a user from a strategy that
    # is not identity, you need to set a password, otherwise it will fail
    # I use: user.password = rand(36**10).to_s(36)
  end

  def link(provider)
    link = nil
    self.authentications.each do |authentication|
      if authentication.provider == provider
        link = authentication
      end
    end
    link
  end


  def send_password_reset
    generate_token(:password_reset_token)
    self.password_reset_sent_at = Time.zone.now
    save!
    UserMailer.password_reset(self).deliver
  end

  def generate_token
    begin
      self[column] = SecureRandom.urlsafe_base64
    end while User.exists?(column => self[column])
  end

  def generate_token_inner(column)
    begin
      self[column] = SecureRandom.urlsafe_base64
      self.password_reset_sent_at = Time.zone.now
      save!
      return self[column]
    end while User.exists?(column => self[column])
  end

  private

    def create_remember_token
      self.remember_token = SecureRandom.urlsafe_base64
    end

end
