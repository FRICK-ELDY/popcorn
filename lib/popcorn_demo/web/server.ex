defmodule PopcornDemo.Web.Server do
	@moduledoc false

	def child_spec(_opts) do
		port = http_port()
		Bandit.child_spec(plug: PopcornDemo.Web.Router, scheme: :http, options: [port: port])
	end

	defp http_port do
		case System.get_env("OSC_BRIDGE_HTTP_PORT") do
			nil -> 8787
			s when is_binary(s) ->
				case Integer.parse(s) do
					{n, ""} -> n
					_ -> 8787
				end
		end
	end
end

