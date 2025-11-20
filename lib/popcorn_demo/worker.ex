defmodule PopcornDemo.Worker do
	use GenServer

	@process_name :main

	def start_link(args) do
		GenServer.start_link(__MODULE__, args, name: @process_name)
	end

	@impl true
	def init(_init_arg) do
		Popcorn.Wasm.register(@process_name)
		{:ok, %{}, {:continue, :after_init}}
	end

	@impl true
	def handle_continue(:after_init, state) do
		:ok = PopcornDemo.Hello.run()
		:ok = PopcornDemo.Parallel.run()
		:ok = PopcornDemo.PingPong.run()
		{:noreply, state}
	end

	@impl true
	def handle_info(_msg, state) do
		{:noreply, state}
	end
end


