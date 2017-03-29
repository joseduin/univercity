class WellcomesController < ApplicationController
   before_action :autentificar_log?, only: [:index] #, :registrarse]
   layout "wellcome"
   
   require 'rest-client'
   require 'json'

   # Pagina de inicio -> www.uclabook.com
   def index
      # login.html 
   end
   
   def validar_login
      usuario = Usuario.new
      response = RestClient.get("#{BASE_URL}/api/usuarios?email=#{params[:email]}") 
      if (response.code == 200) 
         parsed = JSON.parse(response)
         parsed.each do |parse|
           usuario = Usuario.new(parse['id'].to_i, parse['role_id'].to_i, parse['username'], parse['pass'], parse['email'], parse['estatus'].to_i, parse['cedula'], parse['nacionalidad'])
         end
         if params[:clave].eql? usuario.pass
           sesion(usuario)
           
           if usuario.estatus == 0
             redirect_to :controller => 'wellcomes', :action => 'un_paso_mas'
           else
             # validar cuando sea admin 
             redirect_to :controller => 'timelines', :action => 'index' 
           end
         else
           redirect_to :controller => 'wellcomes', :action => 'index', :error => 'Incorrect password'
         end
      else
         redirect_to :controller => 'wellcomes', :action => 'index', :error => 'Not Found User'
      end
   end
   
   def egresado
      
   end
   
   def validar_egresado
      # Buscalo en la bd de UCLABOOK
      response = RestClient.get("#{BASE_URL}/api/usuarios?cedula=#{params[:cedula]}&nacionalidad=#{params[:nacionalidad]}") 
      if (response.code == 204)
         # no lo encontro en la bd de UCLABOOK, ahora veamos si es egresado
         response = RestClient.get("#{BASE_URL}/ucla/egresados?cedula=#{params[:cedula]}&nacionalidad=#{params[:nacionalidad]}")  
         if (response.code == 200) 
            parsed = JSON.parse(response)
            parsed.each do |parse|
               
               set_egresado(parse)
               
               redirect_to :controller => 'wellcomes', :action => 'registrarse'
            end
         else 
            redirect_to :controller => 'wellcomes', :action => 'egresado', :error => 'No found'
         end
      else 
          redirect_to :controller => 'wellcomes', :action => 'egresado', :error => 'Usuario registrado'
      end
   end
   
   def registrarse
      get_egresado()
      refrest_egresado()
   end
   
   def validar_registrarse

            # Insertalo en la API    
            get_egresado()
            response = RestClient.post("#{BASE_URL}/api/usuarios", 
              { usuario: { 
                           role_id: 2,
                           username: params[:username],
                           pass: params[:clave],
                           email: params[:email], 
                           nacionalidad: @nacionalidad,
                           cedula: @cedula, 
                           estatus: 1
              }})
              # Insertó?
            if (response.code == 201)
             
              usuario = Usuario.new
              response = RestClient.get("#{BASE_URL}/api/usuarios?cedula=#{@cedula}&nacionalidad=#{@nacionalidad}") 
              if (response.code == 200) 
                parsed = JSON.parse(response)
                parsed.each do |parse|
                  usuario = Usuario.new(parse['id'].to_i, 1, params[:username], params[:clave], params[:email], 0, @cedula, @nacionalidad)
                end
              end
              
              # Guardamos la Imagen
               response = RestClient.post("#{BASE_URL}/api/imagenes", 
                       { imagene: { 
                           nombre: params[:foto].original_filename,
                           filename: params[:foto].original_filename,
                           tipo: params[:foto].content_type.chomp,
                           data: Base64.encode64( params[:foto].read )
                       }})
                       
               if (response.code == 201)
                  # Buscamos la imagen acorde
                  response = RestClient.get("#{BASE_URL}/api/imagenes?order=created_at:desc")
                  #?nombre=#{nombre_imagen}") 
                  if (response.code == 200) 
                     parsed = JSON.parse(response)
                     parsed.each do |parse|
                        
                        # Guardamos los datos de perfil
                        response = RestClient.post("#{BASE_URL}/api/perfils", 
                          { perfil: { 
                             id_usuario: usuario.id.to_i,
                             username: params[:username],
                             fecha_nacimiento: "#{params[:day]}-#{params[:month]}-#{params[:year]} 00:00:00 +0000" ,
                             telefono: params[:telefono],
                             titulo: params[:titulo],
                             ocupacion: params[:ocupacion],
                             pais: params[:pais],
                             ciudad: params[:ciudad],
                             estado: params[:estado],
                             sobre_mi: params[:sobre_mi],
                             id_imagen: parse['id'].to_i
                          }})
                        
                        # Rompemos el ciclo de las imagenes
                        break
                     end
                  end
               end
               sesion(usuario)
               redirect_to :controller => 'perfiles', :action => 'index'
            else
              refrest_egresado()
              redirect_to :controller => 'wellcomes', :action => 'registrarse', :error => "Bad request"  
            end
         
     
   end
   
   def un_paso_mas
      #session[:estatus] = 1
      decanato = ""
      response = RestClient.get("#{BASE_URL}/ucla/egresados?cedula=#{session[:cedula]}&nacionalidad=#{session[:nacionalidad]}") 
      if (response.code == 200) 
         parsed = JSON.parse(response)
         parsed.each do |parse|
            @carrera = parse['carrera'] 
            decanato = parse['decanato']
         end
      end
      
      # Buscamos INTERESES por DECANATO
      response = RestClient.get("#{BASE_URL}/api/decanatos?iniciales=#{decanato}") 
      if (response.code == 200) 
         parsed = JSON.parse(response)
         parsed.each do |deca|
            
            @intereses = []
            interes = Intere.new
            response = RestClient.get("#{BASE_URL}/api/interes?id_decanato=#{deca['id']}") 
            if (response.code == 200) 
               parsed = JSON.parse(response)
               parsed.each do |parse|
                  interes = Intere.new(parse['id'].to_i, parse['nombre'], parse['descripcion'], parse['estatus'].to_i)          
                  @intereses << interes
               end
            end
         end
      end
      
   end
   
   def validar_un_paso_mas
      
      # Guardamos los intereses
      params[:intereses].each do |interes|
      RestClient.post("#{BASE_URL}/api/usuariointeres", 
            { usuariointere: { 
                  id_usuario: session[:id].to_i,
                  id_interes: interes.to_i
            }})
      end
      
      redirect_to :controller => 'perfiles', :action => 'index'
   end
   
   def error404
       
   end
   
   def error500
       
   end
   
   def log_out
    # Limpiamos la variable session 
    reset_session
    redirect_to :controller => 'wellcomes', :action => 'index'
    
   end
   
   private
   
   def sesion(usuario)
      session[:id] = usuario.id
      session[:role_id] = usuario.role_id
      session[:username] = usuario.username
      session[:pass] = usuario.pass
      session[:email] = usuario.email 
      session[:estatus] = usuario.estatus
      
      session[:cedula] = usuario.cedula
      session[:nacionalidad] = usuario.nacionalidad
   end
   
   def set_egresado(parse)
      flash[:id] = parse['id']
      flash[:nacionalidad] = parse['nacionalidad']
      flash[:cedula] = parse['cedula']
      flash[:nombre] = parse['nombre']
      flash[:apellido] = parse['apellido']
      flash[:email] = parse['email']
      flash[:fecha_egreso] = parse['fecha_egreso']
      flash[:carrera] = parse['carrera']
      flash[:decanato] = parse['decanato']
   end
   
   def get_egresado
      unless flash.blank?
         @id = flash[:id]
         @nacionalidad = flash[:nacionalidad]
         @cedula = flash[:cedula]
         @nombre = flash[:nombre]
         @apellido = flash[:apellido]
         @email = flash[:email]
         @fecha_egreso = flash[:fecha_egreso]
         @carrera = flash[:carrera]
         @decanato = flash[:decanato]
      else
         redirect_to :controller => 'wellcomes', :action => 'egresado', :error => "refrest page"
      end
   end
   
   def refrest_egresado
      flash[:id] = @id
      flash[:nacionalidad] = @nacionalidad
      flash[:cedula] = @cedula
      flash[:nombre] = @nombre
      flash[:apellido] = @apellido
      flash[:email] = @email
      flash[:fecha_egreso] = @fecha_egreso
      flash[:carrera] = @carrera
      flash[:decanato] = @decanato
   end
    
end