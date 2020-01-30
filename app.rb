require 'sinatra'
require 'pg'

set :bind, '0.0.0.0'
set :port, 8080

@@connection = PG.connect :dbname => 'container_version_base',
                         :host => 'db',
                         :user => 'postgres',
                         :password => '10241024'

 

get '/' do
  services = @@connection.exec 'SELECT * FROM container_versions'
  erb :containers, :locals => {:services => services}
end

post '/update' do
  service = @@connection.exec "SELECT * FROM container_versions \
                              WHERE application_name = \'#{params['service']}\' \
                              LIMIT 1" 
  
  if  params['service'].nil? || params['version'].nil? || params['description'].nil? || params['release'].nil?
    status 403
    body "Error" 
    return
  end

  unless service.values.empty?     
    @@connection.exec "UPDATE container_versions \
                     SET application_version = \'#{params['version']}\' \
                     WHERE application_name = \'#{params['service']}\'"
    status 200
    body "Complete"
  else
    @@connection.exec "INSERT INTO container_versions \
                     (release_version, application_name, \
                     application_version, description) \
                     VALUES (\'#{params['release']}\', \
                     \'#{params['service']}\', \
                     \'#{params['version']}\', \
                     \'#{params['description']}\')"
    status 200
    body "Complete"
 end
end
