defmodule PopcornDemo.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
			PopcornDemo.Worker,
			# 先に Ticker を起動し、Popcorn.Wasm.register/1 を完了してから他の Task を流す
			PopcornDemo.Ticker,
			PopcornDemo.Hello,
			PopcornDemo.Parallel
    ]

    opts = [strategy: :one_for_one, name: PopcornDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end


