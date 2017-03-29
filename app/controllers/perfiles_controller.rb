class PerfilesController < ApplicationController
    before_action :autentificar_usuario?, only: [:index, :aliniciar, :show, :editar]
    before_action :get_perfil_propio, only: [:index, :aliniciar, :show, :editar]

    def index
      buscar_intereses(session[:id])
      buscar_posts(session[:id])
      buscar_seguidos(session[:id])
      buscar_seguidores(session[:id])
    end
    
    def show
      buscar_perfil_amigo(params[:id])
      buscar_intereses(params[:id])
      buscar_posts(params[:id])
      buscar_seguidos(params[:id])
      buscar_seguidores(params[:id])
    end
    
    def editar
      @usuari = "#{BASE_URL}/api/usuarios?id=#{session[:id]}"
      response = RestClient.get("#{BASE_URL}/api/usuarios?id=#{session[:id]}")
      if (response.code == 200) 
        parsed = JSON.parse(response)
        parsed.each do |parse|
           @usuario = Usuario.new(parse['id'].to_i, parse['role_id'].to_i, parse['username'], parse['pass'], parse['email'], parse['estatus'].to_i, parse['cedula'], parse['nacionalidad'])
        end
      end
    end
    
    def validar_editar
        if params.has_key?(:clave_nueva) && params.has_key?(:re_clave)
          validar_cambio_de_clave(params[:clave_nueva], params[:re_clave])
        end
      # Guardamos la Imagen
        if params.has_key?(:foto)
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
                if (response.code == 200) 
                    parsed = JSON.parse(response)
                    parsed.each do |parse|
            
                      response = RestClient.get("#{BASE_URL}/api/perfils?id_usuario=#{session[:id]}")
                      if (response.code == 200) 
                        parsed = JSON.parse(response)
                        parsed.each do |perfile|
                      
                          # Guardamos los datos de perfil
                          response = RestClient.put("#{BASE_URL}/api/perfils/#{perfile['id']}", 
                             { perfil: { 
                                username: params[:username],
                                id_imagen: parse['id'].to_i
                             }})
                          if (response.code == 201)
                    
                          end
                          
                          response = RestClient.put("#{BASE_URL}/api/usuarios/#{session[:id]}", 
                          { usuario: { 
                            username: params[:username],
                            email: params[:email]
                          }})
                          if (response.code == 201)
                    
                          end
                          
                        end 
                      end
                  
                      break           
                    end
                end
            end
            
        else
          if params.has_key?(:clave_nueva) && params.has_key?(:re_clave)
            validar_cambio_de_clave(params[:clave_nueva], params[:re_clave])
          end
          response = RestClient.get("#{BASE_URL}/api/perfils?id_usuario=#{session[:id]}")
                      if (response.code == 200) 
                        parsed = JSON.parse(response)
                        parsed.each do |perfile|
                      
                          # Guardamos los datos de perfil
                          response = RestClient.put("#{BASE_URL}/api/perfils/#{perfile['id']}", 
                             { perfil: { 
                                username: params[:username]
                             }})
                          if (response.code == 201)
                    
                          end
                          
                          response = RestClient.put("#{BASE_URL}/api/usuarios/#{session[:id]}", 
                          { usuario: { 
                            username: params[:username],
                            email: params[:email]
                          }})
                          if (response.code == 201)
                    
                          end
                          
                        end 
                      end
          
        end
      redirect_to perfiles_path
      
    end
    
    def subir_imagen
      # Guardamos la Imagen
      nombre_imagen = "#{session[:username]} #{Time.now}".gsub(/\s+/, "")
      response = RestClient.post("#{BASE_URL}/api/imagenes", 
              { imagene: { 
                  nombre: nombre_imagen,
                  filename: params[:foto].original_filename,
                  tipo: params[:foto].content_type.chomp,
                  data: Base64.encode64( params[:foto].read )
              }})
              
      if (response.code == 201)
        # Buscamos la imagen acorde
        response = RestClient.get("#{BASE_URL}/api/imagenes?order=created_at:desc") 
        if (response.code == 200) 
            parsed = JSON.parse(response)
            parsed.each do |parse|
              
              response = RestClient.get("#{BASE_URL}/api/perfils?id_usuario=#{session[:id]}")
              if (response.code == 200) 
                parsed = JSON.parse(response)
                parsed.each do |perfile|
              
                  # Guardamos los datos de perfil
                  response = RestClient.put("#{BASE_URL}/api/perfils/#{perfile['id']}", 
                     { perfil: { 
                        id_imagen: parse['id'].to_i
                     }})
                  if (response.code == 201)
            
                  end
                  
                  # Guardamos en Galeria
                  response = RestClient.post("#{BASE_URL}/api/galerias", 
                    { galeria: { 
                        id_usuario: session[:id].to_i,
                        id_imagen: parse['id'].to_i
                    }})
                  if (response.code == 201)
            
                  end
                  
                end 
              end
              
              # romper el ciclo de las imagenes
              break
            end
        end
      end
      redirect_to :controller => 'perfiles', :action => 'index'
    end
    
    def aliniciar
        
    end
    
    private
    
    def validar_cambio_de_clave(nueva, re_clave)
      if nueva.eql? re_clave
        response = RestClient.put("#{BASE_URL}/api/usuarios/#{session[:id]}", 
        { usuario: { 
            pass: nueva
        }})
        if (response.code == 201)
                    
        end
      else
        redirect_to :controller => 'perfiles', :action => 'editar', :errr => 'claves no coinciden'
      end
    end
    
    def buscar_perfil_amigo(id)
      @perfil_amigo = Perfil.new
      @imagen_perfil_amigo = Imagene.new
      response = RestClient.get("#{BASE_URL}/api/perfils?id_usuario=#{id}") 
      if (response.code == 200)
        parsed = JSON.parse(response)
        parsed.each do |parse|
          @perfil_amigo = Perfil.new(parse['id'].to_i, parse['id_usuario'].to_i, parse['username'], parse['fecha_nacimiento'], parse['telefono'], parse['titulo'], parse['ocupacion'], parse['pais'], parse['ciudad'], parse['estado'], parse['sobre_mi'], parse['id_imagen'].to_i)
       
          # Buscamos el perfil del usuario
          response = RestClient.get("#{BASE_URL}/api/imagenes?id=#{@perfil_amigo.id_imagen}") 
          if (response.code == 200) 
            parsed = JSON.parse(response)
            parsed.each do |imagen|
              @imagen_perfil_amigo = Imagene.new(imagen['id'].to_i, imagen['nombre'], imagen['data'], imagen['filename'], imagen['tipo'])
            end
          end
        end
      else
        redirect_to :controller => 'wellcomes', :action => 'error404'
      end 
    end
    
    def buscar_intereses(id)
      @intereses = []
      interes = Intere.new    
      response = RestClient.get("#{BASE_URL}/api/usuariointeres?id_usuario=#{id}")
      if (response.code == 200) 
        parsed = JSON.parse(response)
        parsed.each do |intere|
            
          response = RestClient.get("#{BASE_URL}/api/interes?id=#{intere['id_interes']}") 
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
    
    def buscar_posts(id)
      @web_url = WEB_URL
      @web_uft8 = WEB_UFT8
      
      @postes = []
      response = RestClient.get("#{BASE_URL}/api/posts?id_usuario=#{id}&order=created_at:desc") 
      if (response.code == 200) 
        parsed = JSON.parse(response)
        parsed.each do |parse|
          posts = Post.new(parse['id'].to_i, parse['tipo'].to_i, parse['id_usuario'].to_i, parse['id_canal'].to_i, parse['titulo'], parse['contenido'], parse['fecha'], parse['id_imagen'].to_i)          
          
          unless parse['id_imagen'].to_i == 0
            response = RestClient.get("#{BASE_URL}/api/imagenes?id=#{parse['id_imagen']}") 
            if (response.code == 200) 
              parsed = JSON.parse(response)
              parsed.each do |imagen|
                posts.imagen = Imagene.new(imagen['id'].to_i, imagen['nombre'], imagen['data'], imagen['filename'], imagen['tipo'])
              end
            end
          end
          
          comentarios = []
          response = RestClient.get("#{BASE_URL}/api/comentarios?id_post=#{posts.id}") 
          if (response.code == 200) 
            parsed = JSON.parse(response)
            parsed.each do |commen|
              comentario = Comentario.new(commen['id'].to_i, commen['id_post'].to_i, commen['id_usuario'].to_i, commen['contenido'], commen['fecha'])  
            
              perfil = Perfil.new
              response = RestClient.get("#{BASE_URL}/api/perfils?id_usuario=#{commen['id_usuario']}") 
              if (response.code == 200) 
                parsed = JSON.parse(response)
                parsed.each do |pars|
                  perfil = Perfil.new(pars['id'].to_i, pars['id_usuario'].to_i, pars['username'], pars['fecha_nacimiento'], pars['telefono'], pars['titulo'], pars['ocupacion'], pars['pais'], pars['ciudad'], pars['estado'], pars['sobre_mi'], pars['id_imagen'].to_i)
                end
              end
              
              comentariocompleto = Comentariocompleto.new
              comentariocompleto.comentario = comentario
              comentariocompleto.perfil = perfil
              comentarios << comentariocompleto
            end
          end
          
          postcompleto = Postcompleto.new
          postcompleto.post = posts
          postcompleto.comentario = comentarios
          @postes << postcompleto
        end
      end
    end
    
end