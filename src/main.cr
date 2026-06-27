require "./shoo"

{% if flag?(:debug) %}
  Shoo::Debug.setup
{% end %}

begin
  Shoo.main(ARGV)
rescue ex : Shoo::ExitProgram
  exit(ex.code)
end
