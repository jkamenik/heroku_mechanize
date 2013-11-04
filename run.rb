require 'rubygems'
require 'mechanize'

class HerokuConfig
  attr_reader :agent, :apps_page, :username, :password
  
  def initialize(username, password)
    @agent    = Mechanize.new
    @username = username
    @password = password
  end
  
  def start
    heroku_login
    heroku_get_app_list
    update_all
  end
  
  def heroku_login
    page = agent.get heroku_url
    
    login = page.link_with(:text => 'Log in').click
    form  = login.forms.first
    form.email    = username
    form.password = password
    
    @dashboard = agent.submit(form,form.button)
  end
  
  def heroku_get_app_list
    @apps = @dashboard.search('span.title > a').collect {|link| link.text}
  end
  
  def update_all
    Array(@apps).each do |app|
      page = agent.get heroku_dashboard_url
      
      page.link_with(:text => app).click

      agent.transact do
        update_logentries app
      end
      
      agent.transact do
        update_newrelic app
      end
    end
  end
  
  def update_logentries(app)
    # Cannot be done as it is a JS only site
    
    # oauth = agent.page.link_with(:text => %r(Logentries)).click
    # oauth.forms.first.click_button
    # agent.page.link_with(:text => app).click
    # agent.page.links_with(:text => %r(edit)).each do |link|
    #   agent.transact do
    #     link.click
    #     p agent.page.forms
    #     # editAccountForm
    #   end
    # end
  end
  
  def update_newrelic(app)
    puts "updating new relic for #{app}"
    oauth = agent.page.link_with(:text => %r(New Relic)).click
    oauth.forms.first.click_button
    agent.page.link_with(:text => 'My preferences').click
    
    agent.page.forms_with(:action => '/email_preferences/save').each do |form|
      agent.transact do
        v = form.checkbox_with.name
        form[v] = true

        form.submit
      end
    end
  rescue
    puts "No New Relic gem for #{app}"
  end
  
  private
  
  def heroku_url
    'http://heroku.com'
  end
  
  def heroku_dashboard_url
    'http://dashboard.heroku.com'
  end
end
HerokuConfig.new('<user>', '<password>').start