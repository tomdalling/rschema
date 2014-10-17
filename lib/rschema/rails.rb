module RSchema
  module Rails
    ParamSchemaValidationError = Class.new(StandardError)

    def self.render_422(controller, exception)
      c = controller
      c.logger.info "Rendering 422 with exception: #{exception}" if exception

      #TODO: could respond with more detail error message (from data in exception)
      controller.respond_to do |format|
        format.html { c.render :file => "#{::Rails.root}/public/422.html",
                               :status => :unprocessable_entity,
                               :layout => false }
        format.any  { c.header :unprocessable_entity }
      end
    end


    module ControllerMethods

      def params_for_schema!(schema)
        RSchema.coerce!(schema, params)
      rescue RSchema::ValidationError => e
        raise ParamSchemaValidationError, e    
      end

      def self.included(base)
        base.rescue_from ParamSchemaValidationError do |e|
          if ::Rails.env.development?
            raise e
          else
            RSchema::Rails.render_422(self, e)
          end
        end
      end

    end
  end
end
