Dir.glob(File.join(__dir__, 'coercers/**/*.rb')).each do |path|
  require path
end
