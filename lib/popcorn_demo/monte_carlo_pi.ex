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

		for idx <- 0..(workers - 1) do
			seed = mix_seed(base_seed, idx)
			n = trials_per + if(idx < remainder, do: 1, else: 0)
			spawn_link(fn ->
				send(parent, {:pi_hits, hits_for(n, seed)})
			end)
		end

		total_hits = collect_hits(workers, 0)
		pi = 4.0 * total_hits / trials
		ms = System.monotonic_time(:millisecond) - start_ms
		pi_str = :io_lib.format('~.6f', [pi]) |> IO.iodata_to_binary()
		IO.puts("[pi] pi ≈ #{pi_str} (#{total_hits}/#{trials})")

		ideal = :math.pi()
		err = abs(pi - ideal)
		p = ideal / 4.0
		sigma1 = 4.0 * :math.sqrt(p * (1.0 - p) / trials)
		z = if sigma1 > 0.0, do: err / sigma1, else: 0.0
		s1_str = :io_lib.format('~.4f', [sigma1]) |> IO.iodata_to_binary()
		s2_str = :io_lib.format('~.4f', [2.0 * sigma1]) |> IO.iodata_to_binary()
		err_str = :io_lib.format('~.6f', [err]) |> IO.iodata_to_binary()
		z_str = :io_lib.format('~.2f', [z]) |> IO.iodata_to_binary()
		status =
			cond do
				z <= 1.0 -> "OK (≤1σ)"
				z <= 2.0 -> "OK (≤2σ)"
				true -> "WARN (>2σ)"
			end
		IO.puts("[pi] expected error 1σ≈#{s1_str}, 2σ≈#{s2_str}")
		IO.puts("[pi] observed error=#{err_str} (#{z_str}σ) #{status}")

		IO.puts("[pi] done in #{ms} ms")
		:ok
	end

	def compare(cases \\ [100_000, 400_000, 900_000], workers \\ @default_workers) when is_list(cases) and is_integer(workers) and workers > 0 do
		IO.puts("[pi] compare start cases=#{Enum.join(cases, ",")} workers=#{workers}")
		Enum.each(cases, fn t ->
			IO.puts("[pi] --- trials=#{t} ---")
			:ok = run(t, workers)
		end)
		IO.puts("[pi] compare done")
		:ok
	end

	defp collect_hits(0, acc), do: acc
	defp collect_hits(n, acc) do
		receive do
			{:pi_hits, k} -> collect_hits(n - 1, acc + k)
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
