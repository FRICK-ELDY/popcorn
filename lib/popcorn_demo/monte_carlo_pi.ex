defmodule PopcornDemo.MonteCarloPi do
	@moduledoc false

	import Bitwise

	@default_trials 200_000
	@default_workers 8
	@modulus 0x1_0000_0000

	def run(trials \\ @default_trials, workers \\ @default_workers)
			when is_integer(trials) and trials > 0 and is_integer(workers) and workers > 0 do
		start_ms = System.monotonic_time(:millisecond)
		IO.puts("[pi] starting trials=#{trials} workers=#{workers}")

		parent = self()
		trials_per = div(trials, workers)
		remainder = rem(trials, workers)
		base_seed = System.monotonic_time(:millisecond) &&& 0xFFFF_FFFF
		IO.puts("[pi dbg] split per=#{trials_per} rem=#{remainder} base_seed=#{base_seed}")

		for idx <- 0..(workers - 1) do
			seed = mix_seed(base_seed, idx)
			n = trials_per + if(idx < remainder, do: 1, else: 0)
			IO.puts("[pi dbg] spawn idx=#{idx} n=#{n} seed=#{seed}")
			pid =
				spawn_link(fn ->
					send(parent, {:pi_hits, idx, hits_for(n, seed)})
				end)
			_process_ref = Process.monitor(pid)
		end

		total_hits = collect(workers, 0)
		pi = 4.0 * total_hits / trials
		ms = System.monotonic_time(:millisecond) - start_ms
		pi_str = :io_lib.format('~.6f', [pi]) |> IO.iodata_to_binary()
		IO.puts("[pi] pi ≈ #{pi_str} (#{total_hits}/#{trials})")
		IO.puts("[pi] done in #{ms} ms")
		:ok
	end

	defp collect(0, acc), do: acc
	defp collect(n, acc) do
		receive do
			{:pi_hits, idx, k} ->
				IO.puts("[pi dbg] recv idx=#{idx} hits=#{k}")
				collect(n - 1, acc + k)
			{:DOWN, _ref, :process, pid, reason} ->
				IO.puts("[pi dbg] DOWN pid=#{inspect(pid)} reason=#{inspect(reason)}")
				collect(n, acc)
			other ->
				IO.puts("[pi dbg] other msg=#{inspect(other)}")
				collect(n, acc)
		after
			10_000 ->
				IO.puts("[pi dbg] timeout waiting (remaining=#{n})")
				acc
		end
	end

	defp hits_for(n, seed), do: loop(n, seed, 0)

	defp loop(0, _seed, acc), do: acc
	defp loop(n, seed, acc) do
		{seed1, x} = rand01(seed)
		{seed2, y} = rand01(seed1)
		acc2 = if x * x + y * y <= 1.0, do: acc + 1, else: acc
		loop(n - 1, seed2, acc2)
	end

	defp rand01(seed) do
		new_seed = lcg(seed)
		{new_seed, new_seed / @modulus}
	end

	defp lcg(seed) do
		(1664525 * seed + 1013904223) &&& 0xFFFF_FFFF
	end

	defp mix_seed(base, idx) do
		(((base ^^^ (idx * 0x9E37_79B9)) &&& 0xFFFF_FFFF) + 0x1234_5678) &&& 0xFFFF_FFFF
	end
end
