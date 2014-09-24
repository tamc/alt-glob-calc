require_relative 'server'

# When in production mode, we precompile the templates and javascripts
class CompileTemplates
  include Helper

  def manifest_file
    # We need to figure out the filename of the latest javascript and css
    File.join(File.dirname(__FILE__), '../public/assets/manifest.json')
  end

  def erb_files
    h = {}
    %w{index macc slider}.each do |name|
      h[File.join(File.dirname(__FILE__), "#{name}.html.erb")] = File.join(File.dirname(__FILE__), "../public/#{name}.html")
    end
    h
  end

  def html_files
    erb_files.values
  end

  def javascript_dir
    File.join(File.dirname(__FILE__), 'javascripts')
  end

  def stylesheet_dir
    File.join(File.dirname(__FILE__), 'stylesheets')
  end

  def contrib_dir
    File.join(File.dirname(__FILE__), '../contrib')
  end

  def manifest_dir
    File.join(File.dirname(__FILE__), '../public/assets/manifest.json')
  end

  def compile!
    compile_assets
    compile_html
  end

  # This compiles the javascripts and stylesheets into single files
  # and then puts them in public/assets
  def compile_assets
    require 'sprockets'
    environment = Sprockets::Environment.new
    environment.append_path javascript_dir
    environment.append_path stylesheet_dir
    environment.append_path contrib_dir
    environment.context_class.class_eval { include Helper }
    manifest = Sprockets::Manifest.new(environment, manifest_dir)
    manifest.compile %w( application.js application.css )
  end

  def compile_html
    assets = JSON.parse(IO.readlines(manifest_file).join)['assets']

    erb_files.each do |erb, html|
      input = IO.readlines(erb).join
      File.open(html, 'w') do |f|
        f.puts ERB.new(input).result(binding)
      end
    end
  end

  def remove!
    # Need to remove the compiled html in public/ because otherwise it will 
    # be loaded in preference to the erb file in src/
    #
    # Can leave the compiled stylesheets and javascripts because the ones in
    # src/javascripts and src/stylesheets will be loaded in preference to the
    # ones in public/assets
    html_files.each do |html_file|
      next unless File.exists?(html_file)
      File.delete(html_file)
    end
  end

end

if __FILE__ == $0
  CompileTemplate.new.compile!
end
