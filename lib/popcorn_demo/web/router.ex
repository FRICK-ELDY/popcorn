defmodule PopcornDemo.Web.Router do
	use Plug.Router

	plug :set_cors
	plug Plug.Logger
	plug Plug.Parsers, parsers: [:json, :urlencoded, :multipart], json_decoder: Jason
	plug :match
	plug :dispatch

	options "/osc" do
		send_resp(conn, 204, "")
	end

	post "/osc" do
		params = conn.body_params || %{}
		address = Map.get(params, "address")
		arg = Map.get(params, "arg")
		host = Map.get(params, "host", "127.0.0.1")
		port = Map.get(params, "port", 9000)
		port_int = if is_integer(port), do: port, else: to_int(port, 9000)

		with true <- is_binary(address) and address != "",
		     true <- is_binary(arg),
		     :ok <- PopcornDemo.OSC.send(host, port_int, address, arg) do
			json(conn, 200, %{"ok" => true})
		else
			false ->
				json(conn, 400, %{"ok" => false, "error" => "invalid address/arg"})
			{:error, reason} ->
				json(conn, 500, %{"ok" => false, "error" => inspect(reason)})
			other ->
				json(conn, 500, %{"ok" => false, "error" => inspect(other)})
		end
	end

	match _ do
		send_resp(conn, 404, "not found")
	end

	defp set_cors(conn, _opts) do
		conn
		|> Plug.Conn.put_resp_header("access-control-allow-origin", "*")
		|> Plug.Conn.put_resp_header("access-control-allow-methods", "GET,POST,OPTIONS")
		|> Plug.Conn.put_resp_header("access-control-allow-headers", "content-type")
	end

	defp json(conn, status, map) do
		body = Jason.encode!(map)
		conn
		|> Plug.Conn.put_resp_header("content-type", "application/json")
		|> Plug.Conn.send_resp(status, body)
	end

	defp to_int(v, default) when is_integer(v), do: v
	defp to_int(v, default) when is_binary(v) do
		case Integer.parse(v) do
			{n, ""} -> n
			_ -> default
		end
	end
	defp to_int(_v, default), do: default
end



