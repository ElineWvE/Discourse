# frozen_string_literal: true

# barber patches to re-route raw compilation via ember compat handlebars

class Barber::Precompiler
  def sources
    [File.open("#{Rails.root}/vendor/assets/javascripts/handlebars.js"),
     precompiler]
  end

  def precompiler
    if !@precompiler

      source = File.read("#{Rails.root}/app/assets/javascripts/discourse-common/lib/raw-handlebars.js.es6")
      template = Tilt::ES6ModuleTranspilerTemplate.new {}
      transpiled = template.babel_transpile(source)

      # very hacky but lets us use ES6. I'm ashamed of this code -RW
      transpiled = transpiled[0...transpiled.index('export ')]

      @precompiler = StringIO.new <<~END
        var __RawHandlebars;
        (function() {
          #{transpiled};
          __RawHandlebars = RawHandlebars;
        })();

        Barber = {
          precompile: function(string) {
            return __RawHandlebars.precompile(string, false).toString();
          }
        };
      END
    end

    @precompiler
  end
end

module Discourse
  module Ember
    module Handlebars
      module Helper
        def precompile_handlebars(string)
          "requirejs('discourse-common/lib/raw-handlebars').template(#{Barber::Precompiler.compile(string)});"
        end

        def compile_handlebars(string)
          "requirejs('discourse-common/lib/raw-handlebars').compile(#{indent(string).inspect});"
        end
      end
    end
  end
end

class Ember::Handlebars::Template
  include Discourse::Ember::Handlebars::Helper
  def setup(env)
    env.register_mime_type 'text/x-handlebars', extensions: with_js_extension(%w(.raw.hbs .raw.hjs .raw.handlebars))
    env.register_transformer 'text/x-handlebars', 'application/javascript', self

    env.register_mime_type 'text/x-ember-mustache', extensions: with_js_extension(%w(.mustache.hbs .mustache.hjs .mustache.handlebars))
    env.register_transformer 'text/x-ember-mustache', 'application/javascript', self

    env.register_mime_type 'text/x-ember-handlebars', extensions: with_js_extension(%w(.hbs .hjs .handlebars))
    env.register_transformer 'text/x-ember-handlebars', 'application/javascript', self
  end

  def precompile_handlebars(string, input = nil)
    "requirejs('discourse-common/lib/raw-handlebars').template(#{Barber::Precompiler.compile(string)});"
  end

  def compile_handlebars(string, input = nil)
    "requirejs('discourse-common/lib/raw-handlebars').compile(#{indent(string).inspect});"
  end

  def global_template_target(namespace, module_name, config)
    "#{namespace}[#{template_path(module_name, config).inspect}]"
  end

  # FIXME: Previously, ember-handlebars-templates uses the logical path which incorrectly
  # returned paths with the `.raw` extension and our code is depending on the `.raw`
  # to find the right template to use.
  def actual_name(input)
    actual_name = input[:name]
    input[:filename].include?('.raw') ? "#{actual_name}.raw" : actual_name
  end

  private

  def handlebars?(filename)
    filename.to_s =~ /\.raw\.(handlebars|hjs|hbs)/ || filename.to_s.ends_with?(".hbr") || filename.to_s.ends_with?(".hbr.erb")
  end
end


