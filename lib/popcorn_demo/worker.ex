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
    {:ok, timer_ref} = :timer.send_interval(1_000, :tick)
    state = %{count: 0, timer_ref: timer_ref}
    {:ok, state}
  end

  @impl true
  def handle_info(:tick, %{count: count, timer_ref: ref} = state) do
    new_count = count + 1
    IO.puts("ticker tick #{new_count}")

    if new_count >= 10 do
      _ = :timer.cancel(ref)
      IO.puts("ticker done")
      {:noreply, %{state | count: new_count}}
    else
      {:noreply, %{state | count: new_count}}
    end
  end
end


