require "rmx-firebase/version"

unless defined?(Motion::Project::Config)
  raise "This file must be required within a RubyMotion project Rakefile."
end

Motion::Project::App.setup do |app|

  index = app.files.rindex { |x| x.index("/RMX") }
  %w(
    Firebase+RMXFirebase
    FQuery+RMXFirebase
    FDataSnapshot+RMXFirebase
    RMXFirebase
    RMXFirebaseSignalHelpers
    RMXFirebaseModel
    RMXFirebaseCollection
    RMXFirebaseHandleModel
    RMXFirebaseTableViewCell
    RMXFirebaseTableHandlerViewCell
    RMXFirebaseView
    RMXFirebaseViewController
  ).each_with_index do |x, i|
    app.files.insert(index + 1 + i, File.expand_path("../motion/#{x}.rb", __FILE__))
  end
end
