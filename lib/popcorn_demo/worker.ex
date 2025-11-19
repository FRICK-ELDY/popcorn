defmodule PopcornDemo.Worker do
  use GenServer

  @process_name :main
	@demo Application.compile_env(:popcorn_demo, :demo, :home)

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: @process_name)
  end

  @impl true
  def init(_init_arg) do
    Popcorn.Wasm.register(@process_name)
		IO.puts("mode=#{@demo}")
		state = %{count: 0, ticker: :stopped}

		case @demo do
			:home ->
				{:ok, state}

			:ticker ->
				IO.puts("ticker started")
				{:ok, %{state | ticker: :running}, 1_000}

			:parallel ->
				:ok = PopcornDemo.Parallel.run()
				{:ok, state}

			_ ->
				{:ok, state}
		end
  end

  @impl true
	def handle_info(:timeout, %{count: count, ticker: :running} = state) do
    new_count = count + 1
    IO.puts("ticker tick #{new_count}")

    if new_count >= 10 do
      IO.puts("ticker done")
			{:noreply, %{state | count: new_count, ticker: :stopped}}
    else
			{:noreply, %{state | count: new_count}, 1_000}
    end
  end

	# JS 側からの開始リクエストをさまざまな形で受け付ける
	@impl true
	def handle_info("start_ticker", state), do: start_ticker(state)
	def handle_info("ticker", state), do: start_ticker(state)
	def handle_info({:start, :ticker}, state), do: start_ticker(state)
	def handle_info({:cmd, :start_ticker}, state), do: start_ticker(state)
	def handle_info(%{"cmd" => "start_ticker"}, state), do: start_ticker(state)

	def handle_info("start_parallel", state), do: run_parallel(state)
	def handle_info("parallel", state), do: run_parallel(state)
	def handle_info({:start, :parallel}, state), do: run_parallel(state)
	def handle_info({:cmd, :start_parallel}, state), do: run_parallel(state)
	def handle_info(%{"cmd" => "start_parallel"}, state), do: run_parallel(state)

	defp start_ticker(%{ticker: :running} = state), do: {:noreply, state}
	defp start_ticker(state) do
		IO.puts("ticker started")
		{:noreply, %{state | count: 0, ticker: :running}, 1_000}
	end

	defp run_parallel(state) do
		:ok = PopcornDemo.Parallel.run()
		{:noreply, state}
	end

	# fallback: 受信内容をそのままログ（送信到達確認用）
	@impl true
	def handle_info(msg, state) do
		IO.puts("received message: #{inspect(msg)}")
		{:noreply, state}
	end
end


