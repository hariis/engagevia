# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_engagevia_session',
  :secret      => 'c6503c413c79fe59abbb90c552c48968aa6d27fa85ffd97f3f4143a41b8a5c16aadafe9cb9c1b8b59fd20a137642bec1260037869fd2c444d662b00146567e03'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
