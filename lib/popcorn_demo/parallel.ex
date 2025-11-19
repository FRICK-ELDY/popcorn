defmodule PopcornDemo.Parallel do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    Process.send_after(self(), :run, 0)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:run, state) do
    start_ms = System.monotonic_time(:millisecond)
    for n <- [30, 31, 32] do
      {^n, v} = fib(n)
      IO.puts("parallel fib(#{n}) = #{v}")
    end
    ms = System.monotonic_time(:millisecond) - start_ms
    IO.puts("parallel done in #{ms} ms")
    {:noreply, state}
  end

  defp fib(0), do: {0, 0}
  defp fib(1), do: {1, 1}
  defp fib(n) when n > 1 do
    {n, elem(fib_impl(n), 0)}
  end

  defp fib_impl(0), do: {0, 1}
  defp fib_impl(n) do
    {a, b} = fib_impl(div(n, 2))
    c = a * (2 * b - a)
    d = a * a + b * b
    if rem(n, 2) == 0, do: {c, d}, else: {d, c + d}
  end
end


