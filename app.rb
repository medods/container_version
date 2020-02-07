require 'sinatra'
require 'pg'

set :bind, '0.0.0.0'
set :port, 8080

@@connection = PG.connect :dbname => 'container_version_base',
                          :host => 'pgbouncer',
                          :user => 'postgres',
                          :password => '10241024'

get '/' do
  redirect to('/list/v39')
end

get '/list/:release' do
  params['release'] ||= "v39"
  services = @@connection.exec  %Q( SELECT * 
                                    FROM container_versions 
                                    WHERE 
                                      release_version = \'#{params['release']}\')  

  erb :containers, :locals => {:services => services}
end



post '/update' do
  
  if  params['service'].nil? || params['version'].nil? || params['description'].nil? || params['release'].nil?
    status 403
    body "Error" 
    return
  end
  
  service = @@connection.exec %Q( SELECT * 
                                  FROM container_versions
                                  WHERE 
                                    application_name = \'#{params['service']}\' 
                                  AND  
                                    release_version = \'#{params['release']}\'
                                  LIMIT 1) 
  

  unless service.values.empty?     
    @@connection.exec %Q( UPDATE container_versions 
                          SET
                            application_version = \'#{params['version']}\'
                          WHERE 
                            application_name = \'#{params['service']}\' 
                          AND 
                            release_version = \'#{params['release']}\')
    status 200
    body "Complete"
  else
    @@connection.exec %Q( INSERT INTO 
                            container_versions
                            (release_version, application_name, 
                             application_version, description) 
                          VALUES 
                            (\'#{params['release']}\', 
                             \'#{params['service']}\', 
                             \'#{params['version']}\', 
                             \'#{params['description']}\'))
    status 200
    body "Complete"
 end
end
