defmodule PopcornDemo.Ring do
	@moduledoc false

	alias __MODULE__.NodeProc

	@default_nodes 50
	@default_hops 500
	@log_every 50

	def run(nodes \\ @default_nodes, hops \\ @default_hops) when nodes > 1 and hops > 0 do
		IO.puts("[ring] starting #{nodes} processes")

		pids =
			for _ <- 1..nodes do
				NodeProc.start(@log_every)
			end

		first = hd(pids)
		rest = tl(pids) ++ [first]

		Enum.zip(pids, rest)
		|> Enum.each(fn {pid, next} -> send(pid, {:set_next, next}) end)

		IO.puts("[ring] passing token for #{hops} hops")
		send(first, {:token, 1, hops, self()})

		receive do
			:done ->
				IO.puts("[ring] done")
		after
			10_000 ->
				IO.puts("[ring] timeout")
		end

		:ok
	end

	defmodule NodeProc do
		def start(log_every) do
			spawn_link(fn -> loop(%{next: nil, log_every: log_every}) end)
		end

		defp loop(%{next: next} = state) do
			receive do
				{:set_next, pid} ->
					loop(%{state | next: pid})

				{:token, hop, max, origin} ->
					maybe_log(hop, max, state.log_every)

					if hop >= max do
						send(origin, :done)
						loop(state)
					else
						send(next, {:token, hop + 1, max, origin})
						loop(state)
					end
			end
		end

		defp maybe_log(hop, max, every) do
			if hop == 1 or hop == max or rem(hop, every) == 0 do
				IO.puts("[ring] hop #{hop}")
			end
		end
	end
end
