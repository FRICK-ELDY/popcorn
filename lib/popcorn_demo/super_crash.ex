defmodule PopcornDemo.SuperCrash do
	@moduledoc false

	@max_restarts 5
	@interval_ms 100
	@counter_name __MODULE__.Counter
	@crashy_name __MODULE__.Crashy

	def run(max \\ @max_restarts, interval_ms \\ @interval_ms) when max >= 0 and interval_ms > 0 do
		start_ms = System.monotonic_time(:millisecond)
		IO.puts("[sup] supervisor starting (max=#{max})")
		{:ok, mgr} = GenServer.start_link(__MODULE__.Manager, %{max: max, start_ms: start_ms})
		IO.puts("[sup dbg] manager started pid=#{inspect(mgr)}")
		GenServer.cast(mgr, :start)
		:ok
	end

	defmodule Manager do
		use GenServer

		def start_link(args), do: GenServer.start_link(__MODULE__, args)

		@impl true
		def init(%{max: max, start_ms: start_ms}) do
			IO.puts("[sup dbg] manager.init max=#{max} start_ms=#{start_ms}")
			{:ok, %{max: max, start_ms: start_ms, attempt: 0, child: nil, ref: nil}}
		end

		@impl true
		def handle_cast(:start, %{attempt: attempt, max: max} = state) do
			next = attempt + 1
			if next <= max do
				IO.puts("[sup dbg] manager.start_child attempt=#{next}")
				{:ok, pid} = PopcornDemo.SuperCrash.Crashy.start_link(%{attempt: next, max: max, start_ms: state.start_ms})
				ref = Process.monitor(pid)
				{:noreply, %{state | attempt: next, child: pid, ref: ref}}
			else
				ms = System.monotonic_time(:millisecond) - state.start_ms
				IO.puts("[sup] recovered after #{max} restarts")
				IO.puts("[sup] done in #{ms} ms")
				{:noreply, state}
			end
		end

		@impl true
		def handle_info({:DOWN, ref, :process, pid, reason}, %{ref: ref} = state) do
			IO.puts("[sup dbg] manager.down pid=#{inspect(pid)} reason=#{inspect(reason)}")
			GenServer.cast(self(), :start)
			{:noreply, %{state | child: nil, ref: nil}}
		end

		@impl true
		def handle_info(_msg, state), do: {:noreply, state}
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

		def start_link(args), do: GenServer.start_link(__MODULE__, args)

		@impl true
		def init(%{attempt: attempt, max: max, start_ms: start_ms}) do
			IO.puts("[sup] worker started")
			IO.puts("[sup] crashing (#{attempt}/#{max})")
			IO.puts("[sup dbg] crashy.init attempt=#{attempt} max=#{max} start_ms=#{start_ms}")
			# Supervisorを使わないので自力で即時終了を行う
			send(self(), :shutdown)
			state = %{attempt: attempt, max: max, start_ms: start_ms}
			{:ok, state}
		end

		@impl true
		def handle_info(:shutdown, state) do
			Process.exit(self(), :normal)
			{:noreply, state}
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
