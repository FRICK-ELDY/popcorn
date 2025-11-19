defmodule PopcornDemo.Worker do
  use GenServer

  @process_name :main

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: @process_name)
  end

  @impl true
  def init(_init_arg) do
    Popcorn.Wasm.register(@process_name)
    IO.puts("Hello from WASM!")
    IO.puts("[ticker] started")
    state = %{count: 0, ticker: :running}
    :ok = PopcornDemo.Parallel.run()
    {:ok, state, 1_000}
  end

  @impl true
	def handle_info(:timeout, %{count: count, ticker: :running} = state) do
    new_count = count + 1
    IO.puts("[ticker] tick #{new_count}")

    if new_count >= 10 do
      IO.puts("[ticker] done")
			{:noreply, %{state | count: new_count, ticker: :stopped}}
    else
			{:noreply, %{state | count: new_count}, 1_000}
    end
  end

  # その他のメッセージは無視
end


