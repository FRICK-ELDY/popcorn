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
    # AtomVM 環境でも動くように :timer ではなく send_after を使用
    _ref = Process.send_after(self(), :tick, 1_000)
    IO.puts("ticker started")
    state = %{count: 0}
    {:ok, state}
  end

  @impl true
  def handle_info(:tick, %{count: count} = state) do
    new_count = count + 1
    IO.puts("ticker tick #{new_count}")

    if new_count >= 10 do
      IO.puts("ticker done")
      {:noreply, %{state | count: new_count}}
    else
      _ref = Process.send_after(self(), :tick, 1_000)
      {:noreply, %{state | count: new_count}}
    end
  end
end


