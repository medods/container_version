require 'sinatra'
require 'pg'
require 'json'

set :bind, '0.0.0.0'
set :port, 8080

def check_aprooved(val)
  val == "t" ? true : false
end

TOKEN = "87be19c4-80b1-480a-abda-baecab33b247"
CURRENT_RELEASE = 'v40'

DB_PARAMS = {:dbname => 'container_version_base',
             :host => 'ya-haproxy',
             :user => 'pguser',
             :password => 'S0lo1024'
             }

get '/' do
  redirect to('/list/v39')
end

post '/lock_cloud_versions' do

  if request.env["HTTP_TOKEN"] != TOKEN
    halt 401
  end

  connection = PG.connect DB_PARAMS  
  services = connection.exec  %Q( SELECT application_name, application_version 
                                    FROM container_versions 
                                  WHERE 
                                    release_version = \'#{CURRENT_RELEASE}\')  
  

  versions = {}                                  
  services.each  do |service|
    versions[service['application_name']] = 'gainanov/' + service['application_name'] + ':' + service['application_version']
  end

  result = {
    "0":{name: "medods-ru", image: versions['medods']},
    "1":{name: "medods-api", image: versions['medods_api']},
    "2":{name: "client-widget", image: versions['client_widget']},
    "3":{name: "fiscal-service", image: versions['fiscal_service']},
    "4":{name: "analytics-service", image: versions['analytics_service']},
    "5":{name: "analysis-service", image: versions['analysis_service']},
    "6":{name: "api-gateway", image: versions['apigw']},
    "7":{name: "auth-service", image: versions['auth_service']},
    "8":{name: "mdlp-service", image: versions['mdlp_service']},
    "9":{name: "work-time-service", image: versions['work_time_service']},
    "10":{name: "data-export-service", image: versions['data_export_service']}
  }.to_json
  connection.exec %Q( INSERT INTO 
                        cloud_updates
                        (data, test_date, stage_date, prod_date) 
                      VALUES 
                        (\'#{result}\', 
                        \'#{Date.today}\', 
                        \'#{Date.today + 1}\', 
                        \'#{Date.today + 2}\')
                   )
  connection.close
  status 200                 
end

get '/cloud_versions/*/:date' do
  content_type :json
  type = params['splat'].first
  date = params['date']
  

  unless type == 'stage' || type == 'test' || type == 'prod'
    status 403
    return
  end
  
  update = nil
  connection = PG.connect DB_PARAMS  

  case type
  when 'test'
    update = connection.exec  %Q( SELECT data 
                                    FROM cloud_updates 
                                  WHERE 
                                    test_date = \'#{date}\'
                                  LIMIT 1  )
  when 'stage'
    update = connection.exec  %Q( SELECT data 
                                    FROM cloud_updates 
                                  WHERE 
                                    stage_date = \'#{date}\'
                                  LIMIT 1  )
  when 'prod'
    update = connection.exec  %Q( SELECT data 
                                    FROM cloud_updates 
                                  WHERE 
                                    prod_date = \'#{date}\'
                                  LIMIT 1  )
  else
    status 404
  end 

  connection.close

  if update.nil?
    status 404 
    return
  end

  update.getvalue(0,0)

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
  connection.close    
  result = services.map do |row|
    row
  end    
  result.to_json                           
end

post '/vpn_connections' do
  
  if request.env["HTTP_TOKEN"] != TOKEN
    halt 401
  end

  request.body.rewind
  rp = JSON.parse request.body.read

  if  rp['data'].nil?
    status 403
    body "Empty params" 
    return
  end
 
  connection = PG.connect DB_PARAMS  

  rp['data'].each do |key, value|

    connect = connection.exec %Q( SELECT * 
                                  FROM vpn_connections
                                  WHERE 
                                    uuid = \'#{key}\' 
                                  LIMIT 1)                          
    unless connect.values.empty?   

      if value['unixdate'].to_s == "0"                             
        value['last_connect'] = connect[0]['last_connect']                             
        value['unixdate'] = connect[0]['unixdate']                             
      end
      value['version'] = connect[0]['version'] if value['version'].to_s == "0"
      
      connection.exec %Q( UPDATE vpn_connections 
                          SET
                            last_connect = \'#{value['last_connect']}\',
                            vpn_ip_address = \'#{value['vpn_ip_address']}\',
                            unixdate = \'#{value['unixdate']}\',
                            clinic_name = \'#{value['clinic_name']}\',
                            version = \'#{value['version']}\'
                          WHERE 
                            uuid = \'#{key}\')
      status 200
      body "Complete"
    else
      connection.exec %Q( INSERT INTO 
                            vpn_connections
                            (last_connect, uuid, clinic_name, vpn_ip_address, version, unixdate) 
                          VALUES 
                            (\'#{value['last_connect']}\', 
                            \'#{key}\', 
                            \'#{value['clinic_name']}\', 
                            \'#{value['vpn_ip_address']}\', 
                            \'#{value['version']}\', 
                            \'#{value['unixdate']}\')
                       )
      status 200
      body "Complete"
    end
  end
  connection.close
end

get '/vpn_connections' do
  connection = PG.connect DB_PARAMS  
  vpn_connections = connection.exec  %Q( SELECT * 
                              FROM vpn_connections
                              ORDER BY clinic_name ASC)  
  connection.close
  erb :vpn_connections, :locals => {:connections => vpn_connections}
end  


post '/cert_expire' do
  connection = PG.connect DB_PARAMS  
    connection.exec %Q( INSERT INTO 
                            expired_certs
                            (msg, created_at) 
                          VALUES 
                            (\'#{params['msg']}\', 
                             \'#{Date.today}\'))
    connection.close
    status 200
    body "Complete"
end

get '/expired_certs' do
  connection = PG.connect DB_PARAMS  
  msgs = connection.exec  %Q( SELECT * 
                              FROM expired_certs
                              ORDER BY id DESC)  
  connection.close
  erb :expired_certs, :locals => {:msgs => msgs}
end  

post '/change_aproove_status' do
  connection = PG.connect DB_PARAMS  
  event = connection.exec %Q( SELECT * 
                                FROM expired_certs
                                WHERE 
                                  id = \'#{params['id']}\' 
                                LIMIT 1)     
  connection.exec %Q( UPDATE expired_certs 
                      SET
                        aprooved = \'#{!check_aprooved(event.first['aprooved'])}\'
                      WHERE 
                        id = \'#{params['id']}\')
  connection.close
  status 200
end

post '/delete_msg' do
  connection = PG.connect DB_PARAMS  
  connection.exec %Q( DELETE 
                      FROM expired_certs
                      WHERE 
                        id = \'#{params['id']}\')     
  connection.close
  status 200
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
