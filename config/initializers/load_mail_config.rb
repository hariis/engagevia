# Load mail configuration if not in test environment
if RAILS_ENV == 'production' 
  email_settings = YAML::load(File.open("#{RAILS_ROOT}/config/email.yml"))
  ActionMailer::Base.smtp_settings = email_settings[RAILS_ENV] unless email_settings[RAILS_ENV].nil?
else
  ActionMailer::Base.smtp_settings = {
  :address => "smtp.gmail.com",
  :port => 587,
  :authentication => :plain,
  :enable_starttls_auto => true,
  :user_name => "engagevia@gmail.com",
  :password => "jayam4rama"
}

end

