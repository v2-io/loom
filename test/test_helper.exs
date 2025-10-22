ExUnit.start()

test_support_glob = Path.join(__DIR__, "support/**/*.exs")

for file <- Path.wildcard(test_support_glob) do
  Code.require_file(file)
end
