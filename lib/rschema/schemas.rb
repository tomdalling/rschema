Dir.glob(File.join(__dir__, 'schemas/**/*.rb')).each do |path|
  require path
end
