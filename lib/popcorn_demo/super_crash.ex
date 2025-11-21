defmodule PopcornDemo.SuperCrash do
	@moduledoc false

	@max_restarts 5
	@interval_ms 100
	@counter_name __MODULE__.Counter
	@crashy_name __MODULE__.Crashy

	def run(max \\ @max_restarts, interval_ms \\ @interval_ms) when max >= 0 and interval_ms > 0 do
		start_ms = System.monotonic_time(:millisecond)
		IO.puts("[sup] supervisor starting (max=#{max})")
		IO.puts("[sup dbg] ensure_counter begin")
		{:ok, _} = ensure_counter(%{max: max, start_ms: start_ms})
		IO.puts("[sup dbg] ensure_counter ok")

		children = [
			%{
				id: @crashy_name,
				start: {@crashy_name, :start_link, [%{interval_ms: interval_ms}]},
				restart: :permanent,
				shutdown: 2_000,
				type: :worker
			},
			%{
				id: __MODULE__.Watcher,
				start: {__MODULE__.Watcher, :start_link, [[:ok]]},
				restart: :permanent,
				shutdown: 2_000,
				type: :worker
			}
		]

		{:ok, sup} =
			Supervisor.start_link(children,
				strategy: :one_for_one,
				max_restarts: max + 2,
				max_seconds: 2
			)
		IO.puts("[sup dbg] supervisor started pid=#{inspect(sup)}")
		:ok
	end

	defp ensure_counter(%{max: max, start_ms: start_ms}) do
		case Process.whereis(@counter_name) do
			nil ->
				case GenServer.start(__MODULE__.Counter, %{max: max, start_ms: start_ms, count: 0}, name: @counter_name) do
					{:ok, pid} ->
						IO.puts("[sup dbg] counter started pid=#{inspect(pid)}")
						{:ok, pid}
					other ->
						IO.puts("[sup dbg] counter start failed: #{inspect(other)}")
						other
				end
			pid when is_pid(pid) ->
				IO.puts("[sup dbg] counter reset max=#{max}")
				GenServer.call(@counter_name, {:reset, max, start_ms})
				{:ok, pid}
		end
	end

	defmodule Counter do
		use GenServer

		@impl true
		def init(%{max: max, start_ms: start_ms, count: count}) do
			IO.puts("[sup dbg] counter.init max=#{max} start_ms=#{start_ms} count=#{count}")
			{:ok, %{max: max, start_ms: start_ms, count: count}}
		end

		@impl true
		def handle_call(:next, _from, %{count: count} = state) do
			new_state = %{state | count: count + 1}
			IO.puts("[sup dbg] counter.next -> #{new_state.count}")
			{:reply, {new_state.count, state.start_ms, state.max}, new_state}
		end

		@impl true
		def handle_call({:reset, max, start_ms}, _from, _state) do
			IO.puts("[sup dbg] counter.reset max=#{max}")
			{:reply, :ok, %{max: max, start_ms: start_ms, count: 0}}
		end
	end

	defmodule Crashy do
		use GenServer

		@counter PopcornDemo.SuperCrash.Counter
		@name PopcornDemo.SuperCrash.Crashy

		def start_link(args), do: GenServer.start_link(__MODULE__, args, name: @name)

		@impl true
		def init(%{interval_ms: t}) do
			{attempt, start_ms, max} = GenServer.call(@counter, :next)
			IO.puts("[sup] worker started")
			IO.puts("[sup dbg] crashy.init attempt=#{attempt} max=#{max} start_ms=#{start_ms}")
			state = %{interval_ms: t, attempt: attempt, max: max, start_ms: start_ms}
			# 正常終了でも再起動されるよう permanent を利用する
			send(self(), :step)
			{:ok, state}
		end

		@impl true
		def handle_info(:step, %{attempt: attempt, max: max, start_ms: start_ms} = state) do
			if attempt <= max do
				IO.puts("[sup] crashing (#{attempt}/#{max})")
				IO.puts("[sup dbg] crashy.step exit=:normal")
				Process.exit(self(), :normal)
				{:noreply, state}
			else
				ms = System.monotonic_time(:millisecond) - start_ms
				IO.puts("[sup] recovered after #{max} restarts")
				IO.puts("[sup] done in #{ms} ms")
				{:noreply, state}
			end
		end

		@impl true
		def terminate(reason, %{attempt: attempt} = _state) do
			IO.puts("[sup dbg] crashy.terminate reason=#{inspect(reason)} attempt=#{attempt}")
			:ok
		end

		@impl true
		def handle_info(_msg, state), do: {:noreply, state}
	end

	defmodule Watcher do
		use GenServer
		@crashy PopcornDemo.SuperCrash.Crashy

		def start_link(_), do: GenServer.start_link(__MODULE__, :ok)

		@impl true
		def init(:ok) do
			IO.puts("[sup dbg] watcher.init")
			Process.send_after(self(), :ensure, 0)
			{:ok, %{ref: nil, pid: nil}}
		end

		@impl true
		def handle_info(:ensure, %{pid: pid} = state) do
			case Process.whereis(@crashy) do
				nil ->
					IO.puts("[sup dbg] watcher: crashy not found; retry")
					Process.send_after(self(), :ensure, 50)
					{:noreply, state}
				p when is_pid(p) and p != pid ->
					ref = Process.monitor(p)
					IO.puts("[sup dbg] watcher: monitoring crashy pid=#{inspect(p)}")
					{:noreply, %{state | pid: p, ref: ref}}
				_ ->
					Process.send_after(self(), :ensure, 50)
					{:noreply, state}
			end
		end

		@impl true
		def handle_info({:DOWN, ref, :process, pid, reason}, %{ref: ref} = state) do
			IO.puts("[sup dbg] watcher: crashy DOWN pid=#{inspect(pid)} reason=#{inspect(reason)}")
			Process.send_after(self(), :ensure, 0)
			{:noreply, %{state | pid: nil, ref: nil}}
		end

		@impl true
		def handle_info(msg, state) do
			IO.puts("[sup dbg] watcher: other msg=#{inspect(msg)}")
			{:noreply, state}
		end
	end
end
