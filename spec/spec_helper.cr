require "spec"
require "colorize"
require "webmock"

# Makes asserting on output much easier
Colorize.enabled = false

require "../src/shoo"
require "./support/run"
require "./support/api_stub/github"

Spec.before_each do
  WebMock.reset
end
