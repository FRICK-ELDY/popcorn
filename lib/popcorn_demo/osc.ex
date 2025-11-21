defmodule PopcornDemo.OSC do
	@moduledoc false

	@doc """
	OSCメッセージを送信します（現在はString引数のみ対応）。
	"""
	@spec send(String.t(), non_neg_integer(), String.t(), String.t()) :: :ok | {:error, term()}
	def send(host, port, address, arg_str) when is_binary(host) and is_integer(port) and is_binary(address) and is_binary(arg_str) do
		payload = encode_message(address, [arg_str])
		with {:ok, sock} <- :gen_udp.open(0, [:binary]),
		     :ok <- :gen_udp.send(sock, String.to_charlist(host), port, payload) do
			:gen_udp.close(sock)
			:ok
		else
			err ->
				err
		end
	end

	@doc """
	OSCメッセージのエンコード（String引数のみ）。
	"""
	@spec encode_message(String.t(), [String.t()]) :: binary()
	def encode_message(address, args) when is_binary(address) and is_list(args) do
		addr = osc_string(address)
		type_tags = "," <> String.duplicate("s", length(args))
		types = osc_string(type_tags)
		args_bin =
			args
			|> Enum.map(&osc_string/1)
			|> IO.iodata_to_binary()

		IO.iodata_to_binary([addr, types, args_bin])
	end

	defp osc_string(s) when is_binary(s) do
		# 末尾NUL + 4バイト境界にパディング
		with_nul = s <> <<0>>
		pad_len = rem(4 - rem(byte_size(with_nul), 4), 4)
		with_nul <> :binary.copy(<<0>>, pad_len)
	end
end



