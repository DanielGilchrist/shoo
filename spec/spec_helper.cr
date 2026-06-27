require "spec"
require "colorize"
require "webmock"

# Makes asserting on output much easier
Colorize.enabled = false

require "../src/shoo"
require "./support/run"
require "./support/gh_cli_fake"
require "./support/memory_credential_store"
require "./support/api_stub/github"

Spec.before_each do
  WebMock.reset
end

def github_token(value : String = "ghp_test") : Shoo::GitHub::Token
  Shoo::GitHub::Token.parse?(value) || raise "invalid test token: #{value}"
end

def gh_credential : Shoo::Credential
  Shoo::Credential.gh
end

def memory_store(content : String? = nil) : Shoo::CredentialStore::InMemory
  Shoo::CredentialStore::InMemory.new(content)
end
