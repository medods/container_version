require 'sinatra'
require 'pg'
require 'json'

set :bind, '0.0.0.0'
set :port, 8080

DB_PARAMS = {:dbname => 'container_version_base',
             :host => 'ya-haproxy',
             :user => 'pguser',
             :password => 'S0lo1024'
             }
 
get '/' do
  redirect to('/list/v39')
end

get '/list/:release' do
  params['release'] ||= "v39"
  connection = PG.connect DB_PARAMS  
  services = connection.exec  %Q( SELECT * 
                                    FROM container_versions 
                                  WHERE 
                                    release_version = \'#{params['release']}\')  
  connection.close
  erb :containers, :locals => {:services => services}
end

get '/last_version/:release' do
  content_type :json
  params['release'] ||= "v39"
  connection = PG.connect DB_PARAMS
  services = connection.exec  %Q( SELECT application_name, application_version 
                                    FROM container_versions 
                                  WHERE 
                                    release_version = \'#{params['release']}\')
  services.to_json                                  
end

post '/update' do
  
  if  params['service'].nil? || params['version'].nil? || params['description'].nil? || params['release'].nil?
    status 403
    body "Error" 
    return
  end
  
  connection = PG.connect DB_PARAMS  
  service = connection.exec %Q( SELECT * 
                                  FROM container_versions
                                  WHERE 
                                    application_name = \'#{params['service']}\' 
                                  AND  
                                    release_version = \'#{params['release']}\'
                                  LIMIT 1) 
  
  connection.close

  unless service.values.empty?     
    connection = PG.connect DB_PARAMS  
    connection.exec %Q( UPDATE container_versions 
                          SET
                            application_version = \'#{params['version']}\'
                          WHERE 
                            application_name = \'#{params['service']}\' 
                          AND 
                            release_version = \'#{params['release']}\')
    connection.close
    status 200
    body "Complete"
  else
    connection = PG.connect DB_PARAMS  
    connection.exec %Q( INSERT INTO 
                            container_versions
                            (release_version, application_name, 
                             application_version, description) 
                          VALUES 
                            (\'#{params['release']}\', 
                             \'#{params['service']}\', 
                             \'#{params['version']}\', 
                             \'#{params['description']}\'))
    connection.close
    status 200
    body "Complete"
 end
end
