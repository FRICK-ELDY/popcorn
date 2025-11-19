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
    {micros, results} =
      :timer.tc(fn ->
        [30, 31, 32]
        |> Task.async_stream(&fib/1, timeout: 30_000)
        |> Enum.map(fn {:ok, {n, v}} -> {n, v} end)
      end)

    ms = div(micros, 1000)
    Enum.each(results, fn {n, v} ->
      IO.puts("parallel fib(#{n}) = #{v}")
    end)
    IO.puts("parallel done in #{ms} ms")
    {:stop, :normal, state}
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


