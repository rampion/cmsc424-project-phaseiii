# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_dvd_club_session',
  :secret      => 'e85d9b804fefe4149ed85fb84145af57498b3ebd42bcf59d4e853fa11238b84ee526c40bfd2b4ea65be7bc633728ec6e7835a9189c7aa2e18c0223b4f60f5ce0'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
