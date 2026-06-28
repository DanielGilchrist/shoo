module Shoo
  module Commands
    struct Config
      @[Kebab::Command(summary: "Initialise a config file")]
      struct Init
        include Kebab::Parseable

        @[Kebab::Option(long: "force", description: "Overwrite an existing config file")]
        getter? force : Bool = false

        def run(context : Context) : Nil
          store = context.config_store

          if store.exists? && !force?
            return context.abort!("A config already exists at #{store.path}. Edit it, or pass --force to overwrite.")
          end

          store.write(::Shoo::Config::Template::CONTENT)

          io = context.stdout
          io.puts "#{"✓".colorize.green} Initialised config at #{store.path}"
          io.puts "  Edit it, then try: #{"shoo notification list --verdict".colorize.bold}"
        end
      end
    end
  end
end
