# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :lockable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [:fitbit]

  has_many :identities, dependent: :destroy

  def self.from_omniauth(auth)
    identity = get_identity(auth)

    identity.access_token = auth['credentials']['token']
    identity.refresh_token = auth['credentials']['refresh_token']
    identity.expires_at = auth['credentials']['expires_at']
    identity.save
    identity.user
  end

  def identity_for(provider)
    identities.where(provider: provider).first
  end

  def fitbit_client
    fitbit_identity = identity_for('fitbit')
    FitbitAPI::Client.new(
      refresh_token: fitbit_identity.refresh_token,
      client_id: Rails.application.secrets.fitbit_api_client_id,
      client_secret: Rails.application.secrets.fitbit_api_client_secret
    )
  end

  def self.get_identity(auth)
    i = Identity.where(provider: auth.provider, uid: auth.uid).first_or_create do |identity|
      if identity.user.nil?
        user = User.new
        user.email = auth.info.email || "#{auth.uid}@example.org"
        user.password = Devise.friendly_token[0, 20]
        identity.user = user
      end
    end
    i
  end
end
