require "spec"
require "colorize"
require "webmock"

# Makes asserting on output much easier
Colorize.enabled = false

require "../src/shoo"
require "./support/run"
require "./support/github_cli_mock"
require "./support/memory_credential_store"
require "./support/api_stub/github"

Spec.before_each do
  WebMock.reset
end

def github_token(value : String = "ghp_test") : Shoo::GitHub::Token
  Shoo::GitHub::Token.parse?(value) || raise "invalid test token: #{value}"
end

def github_cli_credential : Shoo::Authentication::Credential
  Shoo::Authentication::Credential.github_cli
end

def token_credential(value : String = "ghp_test") : Shoo::Authentication::Credential
  Shoo::Authentication::Credential.stored(github_token(value))
end

def memory_store(content : String? = nil) : Shoo::Authentication::CredentialStore::InMemory
  Shoo::Authentication::CredentialStore::InMemory.new(content)
end
